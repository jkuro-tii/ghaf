# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Module for Shared Memory Definitions
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.ghaf.shm;
  inherit (lib)
    foldl'
    mkMerge
    mkIf
    mkOption
    mdDoc
    types
    ;
  enabledServices = lib.filterAttrs (_name: serverAttrs: serverAttrs.enabled) cfg.service;
  clientsPerService =
    service:
    lib.flatten (
      lib.mapAttrsToList (
        name: value: if (name == service || service == "all") then value.clients else [ ]
      ) enabledServices
    );
  allVMs = lib.unique (
    lib.flatten (
      lib.mapAttrsToList (
        _serviceName: serviceAttrs: serviceAttrs.clients ++ [ serviceAttrs.server ]
      ) enabledServices
    )
  );
  clientServicePairs = lib.flatten (
    lib.mapAttrsToList (
      serverName: serverAttrs:
      lib.map (client: {
        service = serverName;
        inherit client;
      }) serverAttrs.clients
    ) enabledServices
  );
  clientServiceWithID = lib.foldl' (
    acc: pair: acc ++ [ (pair // { id = builtins.length acc; }) ]
  ) [ ] clientServicePairs;
  clientID =
    client: service:
    let
      filtered = builtins.filter (x: x.client == client && x.service == service) clientServiceWithID;
    in
    if filtered != [ ] then (builtins.toString (builtins.head filtered).id) else null;
  clientsArg = lib.foldl' (
    acc: pair:
    (
      acc
      // {
        "${pair.service}" =
          if (builtins.hasAttr "${pair.service}" acc) then
            acc.${pair.service} + "," + (builtins.toString pair.id)
          else
            (builtins.toString pair.id);
      }
    )
  ) { } clientServiceWithID;
in
{
  options.ghaf.shm = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc ''
        Enables shared memory communication between virtual machines (VMs) and the host
      '';
    };
    memSize = mkOption {
      type = types.int;
      default = 16;
      description = mdDoc ''
        Specifies the size of the shared memory region, measured in 
        megabytes (MB)
      '';
    };
    hugePageSz = mkOption {
      type = types.str;
      default = "2M";
      description = mdDoc ''
        Specifies the size of the large memory page area. Supported kernel 
        values are 2 MB and 1 GB
      '';
      apply =
        value:
        if value != "2M" && value != "1G" then
          builtins.throw "Invalid huge memory area page size"
        else
          value;
    };

    service = mkOption {
      type = types.attrsOf types.anything;
      default =
        let
          stdConfig = service: {
            server = "${service}-vm";
            clientSocketPath = "/run/user/${builtins.toString config.ghaf.users.accounts.uid}/memsocket-${service}-client.sock";
            serverSocketPath = service: suffix:
              "/run/user/${builtins.toString config.ghaf.users.accounts.uid}/memsocket-${service}${suffix}.sock";
          };
        in
        {
          gui = {
            serverConfig = {
              systemdParams = {
                after = [ "labwc.service" ];
                wantedBy = [ "ghaf-session.target" ];
              };
              multiProcess = true;
            };
            clients = [
              "chrome-vm"
              "business-vm"
              "comms-vm"
              "gala-vm"
              "zathura-vm"
            ];
            clientConfig = {
              systemdParams = {
                wantedBy = [ "default.target" ];
              };
            };
            enabled = true;
          } // stdConfig "gui";
          audio = {
            serverConfig = {
              systemdParams = { };
            };
            clients = [
              "chrome-vm"
              "business-vm"
            ];
            clientConfig = {
              systemdParams = {
                wantedBy = [ "default.target" ];
              };
            };
            enabled = true;
          } // stdConfig "audio";
        };
      description = mdDoc ''
        Specifies the configuration of shared memory services
      '';
    };

    hostSocketPath = mkOption {
      type = types.path;
      default = "/tmp/ivshmem_socket"; # The value is hardcoded in the application
      description = mdDoc ''
        Specifies the path to the shared memory socket, used by QEMU 
        instances for inter-VM memory sharing and interrupt signaling
      '';
    };
    flataddr = mkOption {
      type = types.str;
      default = "0x920000000";
      description = mdDoc ''
        Maps the shared memory to a physical address if set to a non-zero value.
        The address must be platform-specific and arbitrarily chosen to avoid 
        conflicts with other memory areas, such as PCI regions.
      '';
    };
    enable_host = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc ''
        Enables the memsocket functionality on the host system
      '';
    };
    shmSlots = mkOption {
      type = types.int;
      default =
        if cfg.enable_host then
          (builtins.length clientServiceWithID) + 1
        else
          builtins.length clientServiceWithID;
      description = mdDoc ''
        Number of memory slots allocated in the shared memory region
      '';
    };
  };
  config =
    let
      user = "microvm";
      group = "kvm";
    in
    mkIf cfg.enable (mkMerge [
      {
        boot.kernelParams =
          let
            hugepages = if cfg.hugePageSz == "2M" then cfg.memSize / 2 else cfg.memSize / 1024;
          in
          [
            "hugepagesz=${cfg.hugePageSz}"
            "hugepages=${toString hugepages}"
          ];
      }
      {
        systemd.tmpfiles.rules = [
          "d /dev/hugepages 0755 ${user} ${group} - -"
        ];
      }
      (mkIf cfg.enable_host {
        environment.systemPackages = [
          (pkgs.callPackage ../../../packages/memsocket { inherit (cfg) shmSlots; })
        ];
      })
      {
        systemd.services.ivshmemsrv =
          let
            pidFilePath = builtins.trace ">>>> ivshmemsrv service: ${builtins.toString (builtins.attrNames cfg.service)}" "/tmp/ivshmem-server.pid"; # jarekk
            ivShMemSrv =
              let
                vectors = toString (2 * cfg.shmSlots);
              in
              pkgs.writeShellScriptBin "ivshmemsrv" ''
                if [ -S ${cfg.hostSocketPath} ]; then
                  echo Erasing ${cfg.hostSocketPath} ${pidFilePath}
                  rm -f ${cfg.hostSocketPath}
                fi
                ${pkgs.qemu_kvm}/bin/ivshmem-server -p ${pidFilePath} -n ${vectors} -m /dev/hugepages/ -l ${(toString cfg.memSize) + "M"}
              '';
          in
          {
            enable = true;
            description = "Start qemu ivshmem memory server";
            path = [ ivShMemSrv ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              StandardOutput = "journal";
              StandardError = "journal";
              ExecStart = "${ivShMemSrv}/bin/ivshmemsrv";
              User = user;
              Group = group;
            };
          };
      }
      {
        microvm.vms =
          let
            memsocket = pkgs.callPackage ../../../packages/memsocket { inherit (cfg) shmSlots; };
            vectors = toString (2 * cfg.shmSlots);
            configCommon = vmName: {
              ${vmName} = {
                config = {
                  config = {
                    microvm = {
                      qemu = {
                        extraArgs = [
                          "-device"
                          "ivshmem-doorbell,vectors=${vectors},chardev=ivs_socket,flataddr=${cfg.flataddr}"
                          "-chardev"
                          "socket,path=${cfg.hostSocketPath},id=ivs_socket"
                        ];
                      };
                      kernelParams = [ "kvm_ivshmem.flataddr=${cfg.flataddr}" ];
                    };
                    boot.extraModulePackages = [
                      (pkgs.linuxPackages.callPackage ../../../packages/memsocket/module.nix {
                        inherit (config.microvm.vms.${vmName}.config.config.boot.kernelPackages) kernel;
                        inherit (cfg) shmSlots;
                      })
                    ];
                    services = {
                      udev = {
                        extraRules = ''
                          SUBSYSTEM=="misc",KERNEL=="ivshmem",GROUP="kvm",MODE="0666"
                        '';
                      };
                    };
                    environment.systemPackages = [
                      memsocket
                    ];
                  };
                };
              };
            };
            configClient = data: {
              ${data.client} = {
                config = {
                  config =
                    if !cfg.service.${data.service}.enabled then
                      {
                      }
                    else
                      {
                        systemd.user.services."memsocket-${data.service}" = lib.attrsets.recursiveUpdate {
                          enable = true;
                          description = "memsocket";
                          serviceConfig = {
                            Type = "simple";
                            ExecStart = "${memsocket}/bin/memsocket -c ${
                              cfg.service.${data.service}.clientSocketPath
                            } ${builtins.toString (clientID data.client data.service)}";
                            Restart = "always";
                            RestartSec = "1";
                          };
                        } cfg.service.${data.service}.clientConfig.systemdParams;
                      };
                };
              };
            };
            configServer = clientSuffix: clientId: service: {
              "${cfg.service.${service}.server}" =
                builtins.trace ">>>configServer client=${clientSuffix} ${clientId} ${service}"
                  {
                    config = {
                      config = {
                        systemd.user.services."memsocket-${service}${clientSuffix}" = lib.attrsets.recursiveUpdate {
                          enable = true;
                          description = "memsocket";
                          serviceConfig = {
                            Type = "simple"; # jarekk
                            ExecStart = "${memsocket}/bin/memsocket -s ${
                              cfg.service.${service}.serverSocketPath service clientSuffix
                            } -l ${clientId}";
                            Restart = "always";
                            RestartSec = "1";
                          };
                        } cfg.service.${service}.serverConfig.systemdParams; # jarekk
                      };
                    };
                  };
            };

            clientsConfig = foldl' lib.attrsets.recursiveUpdate { } (map configClient clientServicePairs);

            clientsAndServers = builtins.trace ">>>clientsAndServers" (
              lib.foldl' lib.attrsets.recursiveUpdate clientsConfig (
                map (
                  service:
                  let
                    multiProcess =
                      if lib.attrsets.hasAttr "multiProcess" cfg.service.${service}.serverConfig then
                        cfg.service.${service}.serverConfig.multiProcess
                      else
                        false;
                    result =
                      if multiProcess then
                        (lib.foldl' lib.attrsets.recursiveUpdate { } (
                          map (client: configServer "-${client}" (clientID client service) service) (
                            clientsPerService service
                          )

                        ))
                      else
                        (configServer "" # clientSuffix
                          clientsArg.${service}
                          service
                        );
                  in
                  result
                ) (builtins.attrNames enabledServices)
              )
            );

            finalConfig = foldl' lib.attrsets.recursiveUpdate clientsAndServers (map configCommon allVMs);
          in
          finalConfig;
      }
    ]);
}

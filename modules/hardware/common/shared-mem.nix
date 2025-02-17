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
  cfg = config.shm;
  inherit (lib)
    foldl'
    mkMerge
    mkIf
    mkOption
    types
    ;
  enabledServices = lib.filterAttrs (_name: serverAttrs: serverAttrs.enabled) cfg.service;
  enabledVmServices =
    isVM:
    lib.filterAttrs (_name: serverAttrs: serverAttrs.serverConfig.runsOnVm == isVM) enabledServices;
  clientsPerService =
    service:
    lib.flatten (
      lib.mapAttrsToList (
        name: value: if (name == service || service == "all") then value.clients else [ ]
      ) enabledServices
    );
  allVMs = let t = lib.unique (
    lib.concatLists (map (s: (lib.filter (client: client != "host") s.clients) ++ [ s.server ]) (builtins.attrValues enabledServices))
  ); in builtins.trace t t; 
  clientServicePairs = let t = lib.unique (
    lib.concatLists (
      map (
        s:
        map (c: {
          service = s.name;
          client = c;
        }) s.clients
      ) (lib.mapAttrsToList (name: attrs: attrs // { inherit name; }) enabledServices)
    )
  ); in builtins.trace t t;
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
  options.shm = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enables shared memory communication between virtual machines (VMs) and the host
      '';
    };
    memSize = mkOption {
      type = types.int;
      default = 32;
      description = ''
        Specifies the size of the shared memory region, measured in
        megabytes (MB)
      '';
    };
    hugePageSz = mkOption {
      type = types.str;
      default = "2M";
      description = ''
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
            clientSocketPath = "/run/memsocket/${service}-client.sock";
            serverSocketPath = service: suffix: "/run/memsocket/${service}${suffix}.sock";
            userService = false;
            serverConfig = {
              runsOnVm = true;
            };
          };
        in
        {
          gui = lib.attrsets.recursiveUpdate (stdConfig "gui") {
            enabled = true;
            serverSocketPath = service: suffix: "/tmp/${service}${suffix}.sock";
            serverConfig = {
              userService = true;
              systemdParams = {
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
              userService = false;
              systemdParams = {
                wantedBy = [ "default.target" ];
                serviceConfig = {
                  User = "appuser";
                  Group = "users";
                };
              };
            };
          };
          audio = lib.attrsets.recursiveUpdate (stdConfig "audio") {
            enabled = config.ghaf.services.audio.pulseaudioUseShmem; # jarekk: fixme
            serverSocketPath = _service: _suffix: config.ghaf.services.audio.pulseaudioUnixSocketPath;
            serverConfig = {
              userService = false;
              systemdParams = {
                wantedBy = [ "default.target" ];
                after = [ "pipewire.service" ];
                serviceConfig = {
                  User = "pipewire";
                  Group = "pipewire";
                };
              };
            };
            clients = [
              "chrome-vm"
              "business-vm"
              "comms-vm"
              "gala-vm"
            ];
            clientConfig = {
              userService = false;
              systemdParams = {
                wantedBy = [ "default.target" ];
                serviceConfig = {
                  User = "appuser";
                  Group = "users";
                };
              };
            };
          };
          host-adminVm = lib.attrsets.recursiveUpdate (stdConfig "admin") {
            enabled = true; #config.givc.host.enable; # jarekk: fixme?
            serverSocketPath = _1: _2: (builtins.elemAt config.ghaf.givc.adminConfig.addresses 1).addr;
            serverConfig = {
              runsOnVm = true;
              userService = false;
              systemdParams = {
                wantedBy = [ "multi-user.target" ];
                before = [ "givc-admin.service" ];
              };
            };
            clients = [
              "host"
            ];
            clientConfig = {
              userService = false;
              systemdParams = {
                # before = [ "givc-${config.givc.host.agent.name}.service" ]; jarekk: The option `givc.host.agent' does not exist
                after = [ "ivshmemsrv.service" ];
                wantedBy = [ "multi-user.target" ];
              };
            };
          };
          adminVm-host = lib.attrsets.recursiveUpdate (stdConfig "admin") {
            enabled = true; #config.givc.host.enable;
            serverSocketPath = _1: _2: "/run/memsocket/host-adminvm.sock";
            clientSocketPath = "/run/memsocket/host-adminvm.sock";
            serverConfig = {
              runsOnVm = false;
              userService = false;
              systemdParams = {
                after = [ "ivshmemsrv.service" ];
                wantedBy = [ "multi-user.target" ];
              };
            };
            clients = [
              "admin-vm"
            ];
            clientConfig = {
              userService = false;
              systemdParams = {
                # before = [ "givc-${config.givc.host.agent.name}.service" ]; jarekk: The option `givc.host.agent' does not exist
                wantedBy = [ "multi-user.target" ];
                before = [ "givc-admin.service" ];
              };
            };
          };
        };
      description = ''
        Specifies the configuration of shared memory services:
        server and client VMs. The server VMs are named after the 
        service name.
      '';
    };

    hostSocketPath = mkOption {
      type = types.path;
      default = "/tmp/ivshmem_socket"; # The value is hardcoded in the application
      description = ''
        Specifies the path to the shared memory socket, used by QEMU
        instances for inter-VM memory sharing and interrupt signaling
      '';
    };
    flataddr = mkOption {
      type = types.str;
      default = "0x920000000";
      description = ''
        Maps the shared memory to a physical address if set to a non-zero value.
        The address must be platform-specific and arbitrarily chosen to avoid
        conflicts with other memory areas, such as PCI regions.
      '';
    };
    shmSlots = mkOption {
      type = types.int;
      default = builtins.length clientServiceWithID;
      description = ''
        Number of memory slots allocated in the shared memory region
      '';
    };
  };
  config =
    let
      user = "microvm";
      group = "kvm";
      memsocket = pkgs.callPackage ../../../packages/memsocket { inherit (cfg) shmSlots; debug = true;};
      vectors = toString (2 * cfg.shmSlots);
      defaultClientConfig =
        data:
        lib.attrsets.recursiveUpdate {
          enable = true;
          description = "memsocket";
          serviceConfig = {
            Type = "simple";
            ExecStart = let hostOpt = 
              if data.client == "host" then 
                "-h ${cfg.hostSocketPath}" 
              else "";
            in 
            "${memsocket}/bin/memsocket ${hostOpt} -c ${
              cfg.service.${data.service}.clientSocketPath
            } ${builtins.toString (clientID data.client data.service)}";
            Restart = "always";
            RestartSec = "1";
            RuntimeDirectory = "memsocket";
            RuntimeDirectoryMode = "0770";
          };
        } cfg.service.${data.service}.clientConfig.systemdParams;
      clientConfigTemplate =
        data:
        let
          base =
            if cfg.service.${data.service}.clientConfig.userService then
              {
                user.services."memsocket-${data.service}-client" = defaultClientConfig data;
              }
            else
              {
                services."memsocket-${data.service}-client" = defaultClientConfig data;
              };

        in
        if data.client == "host" then
          base
        else
          {
            "${data.client}".config.config.systemd = base;
          };

      defaultServerConfig =
        clientSuffix: clientId: service: runsOnVm:
        lib.attrsets.recursiveUpdate {
          enable = true;
          description = "memsocket";
          serviceConfig = {
            Type = "simple";
            ExecStart = let hostOpt = 
              if !runsOnVm then 
                "-h ${cfg.hostSocketPath}" 
              else "";
            in
            "${memsocket}/bin/memsocket -s ${
              cfg.service.${service}.serverSocketPath service clientSuffix
            } ${hostOpt} -l ${clientId}";
            Restart = "always";
            RestartSec = "1";
            RuntimeDirectory = "memsocket";
            RuntimeDirectoryMode = "0750";
          };
        } cfg.service.${service}.serverConfig.systemdParams;
      serverConfigTemplate =
        clientSuffix: clientId: service:
        let
          base =
            if cfg.service.${service}.serverConfig.userService then
              {
                user.services."memsocket-${service}${clientSuffix}-service" =
                  defaultServerConfig clientSuffix clientId 
                    service cfg.service.${service}.serverConfig.runsOnVm;
              }
            else
              {
                services."memsocket-${service}${clientSuffix}-service" =
                  defaultServerConfig clientSuffix clientId 
                    service cfg.service.${service}.serverConfig.runsOnVm;
              };
        in
        if cfg.service.${service}.serverConfig.runsOnVm then
          {
            "${cfg.service.${service}.server}".config.config.systemd = base;
          }
        else
          base;
      serverConfig =
        service:
        let
          multiProcess =
            if lib.attrsets.hasAttr "multiProcess" cfg.service.${service}.serverConfig then
              cfg.service.${service}.serverConfig.multiProcess
            else
              false;
        in
        if multiProcess then
          (lib.foldl' lib.attrsets.recursiveUpdate { } (
            map (client: serverConfigTemplate "-${client}" (clientID client service) service) (
              clientsPerService service
            )
          ))
        else
          (serverConfigTemplate "" # clientSuffix
            clientsArg.${service}
            service
          );

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
      (mkIf cfg.enable {
        environment.systemPackages = [
          (pkgs.callPackage ../../../packages/memsocket { inherit (cfg) shmSlots; })
        ];
      })
      {
        systemd.services.ivshmemsrv =
          let
            pidFilePath = "/tmp/ivshmem-server.pid";
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
      # add host systemd client services
      {
        systemd = foldl' lib.attrsets.recursiveUpdate { } (
          map clientConfigTemplate (lib.filter (data: data.client == "host") clientServicePairs)
        );
      }
      # add host systemd server services
      {
        systemd = lib.foldl' lib.attrsets.recursiveUpdate { } (
          map serverConfig (builtins.attrNames (enabledVmServices false))
        );
      }
      # override the default configuration of the host givc service
      { # jarekk: fixme
        # givc.host.admin = lib.mkIf (lib.elem "host" enabledServices.admin.clients) (lib.mkForce {
        #   addr = builtins.toString enabledServices.admin.clientSocketPath;
        #   protocol = "unix";
        # });
      }
      {
        #config.ghaf.givc.adminvm 
        # givc.admin.addresses = let memsocketAddr = {
        #   addr = (builtins.toString enabledServices.admin.serverSocketPath);
        #   protocol = "unix";
        # }; in [ ];#memsocketAddr ];
      }
      {
        microvm.vms =
          let
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
            # generate config for memsocket services  running in client mode on VMs
            clientsConfig = foldl' lib.attrsets.recursiveUpdate { } (
              map clientConfigTemplate (lib.filter (data: data.client != "host") clientServicePairs)
            );
            # generate config for memsocket services running in server mode on VMs
            clientsAndServers = lib.foldl' lib.attrsets.recursiveUpdate clientsConfig (
              map serverConfig (builtins.attrNames (enabledVmServices true))
            );
            finalMicroVmsConfig = foldl' lib.attrsets.recursiveUpdate clientsAndServers (
              map configCommon allVMs
            );
          in
          finalMicroVmsConfig;
      }
    ]);
}

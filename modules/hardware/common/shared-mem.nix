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
  services = {
    gui = {
      server = "gui-vm";
      enabled = config.ghaf.shm.gui;
      clients = [
        "chrome-vm"
        "business-vm"
      ];
    };
    audio = {
      server = "audio-vm";
      enabled = config.ghaf.shm.audio;
      clients = [
        "chrome-vm"
        "business-vm"
      ];
    };
  };
  enabledServices = lib.filterAttrs (_name: serverAttrs: serverAttrs.enabled) services;
  serviceServer =
    service:
    (
      (lib.attrsets.concatMapAttrs (
        name: value:
        if name == service && value.enabled then { inherit (value) server; } else { server = "None"; }
      ))
      enabledServices
    ).server;
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
    if filtered != [ ] then (builtins.head filtered).id else null;
  clientsArg =
    lib.foldl'
      (
        acc: pair:
        (
          acc
          // {
            ${pair.service} =
              acc.${pair.service}
              + "${if (builtins.stringLength acc.${pair.service}) > 0 then "," else ""}"
              + (builtins.toString pair.id);
          }
        )
      )
      {
        audio = "";
        gui = "";
      }
      clientServiceWithID;
in
{
  options.ghaf.shm = {
    enable = mkOption {
      type = types.bool;
      default = false;
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
    guiClientSocketPath = mkOption {
      type = types.path;
      default = "/run/user/${builtins.toString config.ghaf.users.loginUser.uid}/memsocket-gui-client.sock";
      description = mdDoc ''
        Specifies the path of the listening socket, which is used by Waypipe 
        or other server applications as the output socket in its server mode for 
        data transmission
      '';
    };
    guiServerSocketPath = mkOption {
      type = types.path;
      default = "/run/user/${builtins.toString config.ghaf.users.loginUser.uid}/memsocket-gui-server.sock";
      description = mdDoc ''
        Specifies the location of the output socket, which will connected to
        in order to receive data from AppVMs. This socket must be created by
        another application, such as Waypipe, when operating in client mode
      '';
    };
    audioClientSocketPath = mkOption {
      type = types.path;
      # default = /tmp/pulseaudio.sock;
      default = "/run/user/${builtins.toString config.ghaf.users.loginUser.uid}/memsocket-audio-client.sock";
      description = mdDoc ''
        Specifies the path of the audio listening socket, which is used by an audio 
        or other server applications as the output socket in its server mode for 
        data transmission
      '';
    };
    audioServerSocketPath = mkOption {
      type = types.path;
      default = "/run/user/${builtins.toString config.ghaf.users.loginUser.uid}/memsocket-audio-server.sock";
      # default = /tmp/remote.sock;
      description = mdDoc ''
        Specifies the location of the audio output socket, which will connected 
        to in order to receive data from AppVMs. This socket must be created by
        another application
      '';
    };
    gui = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Enables the use of shared memory with Waypipe for Wayland-enabled
        applications running on virtual machines (VMs), facilitating
        efficient inter-VM communication
      '';
    };
    audio = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Enables the use of shared memory for sending audio
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
            configGuiServer = vmName: {
              ${vmName} = {
                config = {
                  config = {
                    systemd.user.services.memsocket-gui = {
                      enable = true;
                      description = "memsocket";
                      after = [ "labwc.service" ];
                      serviceConfig = {
                        Type = "simple";
                        ExecStart = "${memsocket}/bin/memsocket -s ${cfg.guiServerSocketPath} -l ${clientsArg.gui}";
                        Restart = "always";
                        RestartSec = "1";
                      };
                      wantedBy = [ "ghaf-session.target" ];
                    };
                  };
                };
              };
            };
            configGuiClient = vmName: {
              ${vmName} = {
                config = {
                  config =
                    if cfg.gui then
                      {
                        systemd.user.services.memsocket-gui = {
                          enable = true;
                          description = "memsocket";
                          serviceConfig = {
                            Type = "simple";
                            ExecStart = "${memsocket}/bin/memsocket -c ${cfg.guiClientSocketPath} ${builtins.toString (clientID vmName "gui")}";
                            Restart = "always";
                            RestartSec = "1";
                          };
                          wantedBy = [ "default.target" ];
                        };
                      }
                    else
                      { };
                };
              };
            };
            configAudioServer = vmName: {
              ${vmName} = {
                config = {
                  config = {
                    systemd.user.services.memsocket-audio = {
                      enable = true;
                      description = "memsocket";
                      serviceConfig = {
                        Type = "simple";
                        ExecStart = "${memsocket}/bin/memsocket -s ${cfg.audioServerSocketPath} -l ${clientsArg.audio}";
                        Restart = "always";
                        RestartSec = "1";
                        ExecStartPre = "/bin/sh -c 'sleep 2'";
                      };
                      wantedBy = [ "default.target" ];
                      requires = [ "pipewire-pulse.socket" ];
                    };
                  };
                };
              };
            };
            configAudioClient = vmName: {
              ${vmName} = {
                config = {
                  config = {
                    systemd.user.services.memsocket-audio = {
                      enable = true;
                      description = "memsocket";
                      serviceConfig = {
                        Type = "simple";
                        ExecStart = "${memsocket}/bin/memsocket -c ${cfg.audioClientSocketPath} ${builtins.toString (clientID vmName "audio")}";
                        Restart = "always";
                        RestartSec = "1";
                      };
                      wantedBy = [ "default.target" ];
                    };
                  };
                };
              };
            };

            # Combine "gui" client configurations
            guiClients = foldl' lib.attrsets.recursiveUpdate { } (
              map configGuiClient (clientsPerService "gui")
            );

            # Add the server configuration for "gui"
            guiConfig =
              if cfg.gui then
                lib.attrsets.recursiveUpdate guiClients (configGuiServer (serviceServer "gui"))
              else
                { };

            # Combine "audio" client configurations
            audioClients = foldl' lib.attrsets.recursiveUpdate guiConfig (
              map configAudioClient (clientsPerService "audio")
            );

            # Add the server configuration for "audio"
            audioConfig =
              if cfg.audio then
                lib.attrsets.recursiveUpdate audioClients (configAudioServer (serviceServer "audio"))
              else
                guiConfig;
            # Merge with common VM configurations
            finalConfig = foldl' lib.attrsets.recursiveUpdate audioConfig (map configCommon allVMs);
          in
          finalConfig;
      }
    ]);
}

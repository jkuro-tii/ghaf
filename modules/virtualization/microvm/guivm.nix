# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  configHost = config;
  vmName = "gui-vm";
  macAddress = "02:00:00:02:02:02";
  memsocket = pkgs.callPackage ../../../user-apps/memsocket {};
  guivmBaseConfiguration = {
    imports = [
      (import ./common/vm-networking.nix {inherit vmName macAddress;})
      ({
        lib,
        pkgs,
        ...
      }: {
        ghaf = {
          users.accounts.enable = lib.mkDefault configHost.ghaf.users.accounts.enable;
          profiles.graphics.enable = true;
          # Uncomment this line to take LabWC in use
          # profiles.graphics.compositor = "labwc";
          profiles.applications.enable = false;
          windows-launcher.enable = false;
          development = {
            ssh.daemon.enable = lib.mkDefault configHost.ghaf.development.ssh.daemon.enable;
            debug.tools.enable = lib.mkDefault configHost.ghaf.development.debug.tools.enable;
          };
        };

        environment = {
          systemPackages = [
            pkgs.waypipe
            pkgs.networkmanagerapplet
            pkgs.nm-launcher
            memsocket
          ];
        };

        system.stateVersion = lib.trivial.release;

        nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
        nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

        time.timeZone = "Asia/Dubai";

        microvm = {
          optimize.enable = false;
          vcpu = 2;
          mem = 2048;
          hypervisor = "qemu";
          shares = [
            {
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
          ];
          writableStoreOverlay = lib.mkIf config.ghaf.development.debug.tools.enable "/nix/.rw-store";

          qemu.extraArgs = [
            "-object"
            "memory-backend-file,size=${config.ghaf.profiles.applications.ivShMemServer.memSize},share=on,mem-path=/dev/shm/ivshmem,id=hostmem"
            "-device"
            "ivshmem-doorbell,vectors=2,chardev=ivs_socket"
            "-chardev"
            "socket,path=/tmp/ivshmem_socket,id=ivs_socket"
          ];
        };

        imports = import ../../module-list.nix;

        services.udev.extraRules = ''
          SUBSYSTEM=="misc",KERNEL=="ivshmem",GROUP="kvm",MODE="0666"
          '';

        # Waypipe service runs in the GUIVM and listens for incoming connections from AppVMs
        # via shared memory socket
        systemd.user.services = let
            memSocketPath = "/tmp/ivshmem_socket";
            pidFilePath = "/tmp/ivshmem-server.pid"; in
        {
          waypipe = {
            enable = true;
            description = "waypipe";
            after = ["memsocket.service"];
            serviceConfig = {
              Type = "simple";
              Environment = [
                "WAYLAND_DISPLAY=\"wayland-1\""
                "DISPLAY=\":0\""
                "XDG_SESSION_TYPE=wayland"
                "QT_QPA_PLATFORM=\"wayland\"" # Qt Applications
                "GDK_BACKEND=\"wayland\"" # GTK Applications
                "XDG_SESSION_TYPE=\"wayland\"" # Electron Applications
                "SDL_VIDEODRIVER=\"wayland\""
                "CLUTTER_BACKEND=\"wayland\""
              ];
              ExecStart = "${pkgs.waypipe}/bin/waypipe -s ${memSocketPath} client";
              Restart = "always";
              RestartSec = "1";
            };
            wantedBy = ["ghaf-session.target"];
          };

          # Waypipe in GUIVM needs to communicate with AppVMs using socket forwading
          # application. It uses shared memory between virtual machines to forward
          # data between sockets.
          #
          memsocket = {
            enable = true;
            description = "memsocket";
            after = ["weston.service"];
            unitConfig = {
              Type = "simple";
            };
            serviceConfig = {
              ExecStart = "${memsocket}/bin/memsocket -s ${memSocketPath}";
            };
            wantedBy = ["ghaf-session.target"];
          };
        };
        # Fixed IP-address for debugging subnet
        systemd.network.networks."10-ethint0".addresses = [
          {
            addressConfig.Address = "192.168.101.3/24";
          }
        ];
      })
    ];
  };
  cfg = config.ghaf.virtualization.microvm.guivm; in
  {
    options.ghaf.virtualization.microvm.guivm = {
      enable = lib.mkEnableOption "GUIVM";

      extraModules = lib.mkOption {
        description = ''
          List of additional modules to be imported and evaluated as part of
          GUIVM's NixOS configuration.
        '';
        default = [];
      };
  };

  config = lib.mkIf cfg.enable {
    microvm.vms."${vmName}" = {
      autostart = true;
      config =
        guivmBaseConfiguration
        // {
          imports =
            guivmBaseConfiguration.imports
            ++ cfg.extraModules;
        } // {
          config.boot.kernelPatches = [{
            name = "Shared memory PCI driver";
            patch = pkgs.fetchpatch {
              url = "https://raw.githubusercontent.com/jkuro-tii/ivshmem/dev/0001-Shared-memory-driver.patch";
              sha256 = "sha256-Nu/r72MIgXcLO7SmvT11kKyfjxu3EpFnATIVmmbEH4o=";
            };}];
        };
      specialArgs = {inherit lib;};
    };

    systemd.services."ivshmemsrv" = let
      socketPath = "/tmp/ivshmem_socket";
      pidFilePath = "/tmp/ivshmem-server.pid";
      ivShMemSrv = pkgs.writeShellScriptBin "ivshmemsrv" ''
          if [ -S ${socketPath} ]; then
            echo Erasing ${socketPath} ${pidFilePath}
            rm -f ${socketPath}
          fi
          ${pkgs.sudo}/sbin/sudo -u microvm -g kvm ${pkgs.qemu_kvm}/bin/ivshmem-server -p ${pidFilePath} -n 2 -m /dev/shm -l ${config.ghaf.profiles.applications.ivShMemServer.memSize}
        ''; in
    {
      enable = true;
      description = "Start qemu ivshmem memory server";
      path = [ivShMemSrv];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardOutput = "journal";
        StandardError = "journal";
        ExecStart = "${ivShMemSrv}/bin/ivshmemsrv";
      };
    };
  };
}

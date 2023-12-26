# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.ghaf.profiles.applications;
in
  with lib; {
    options.ghaf.profiles.applications = {
      enable = mkEnableOption "Some sample applications";
      ivShMemServer = {
        enable = mkEnableOption "Shared memory server";
        memSize = mkOption {
          type = lib.types.int;
          default = 16;
          description = mdDoc ''
          Defines shared memory size in MiB
        '';
        };
      };
      #TODO Create options to allow enabling individual apps
      #weston.ini.nix mods needed
    };

    config = mkMerge [
      (mkIf cfg.enable {
        # TODO: Needs more generic support for defining application launchers
        #       across different window managers.
        ghaf = {
          profiles.graphics.enable = true;
          graphics.weston.enableDemoApplications = true;
        };
      })
      (mkIf cfg.ivShMemServer.enable {
        systemd.services."ivshmemsrv" = let
          ivShMemSrv = let
            socketPath = "/tmp/ivshmem_socket";
            pidFilePath = "/tmp/ivshmem-server.pid"; in
            pkgs.writeShellScriptBin "ivshmemsrv" ''
              if [ -S ${socketPath} ]; then
                echo Erasing ${socketPath} ${pidFilePath}
                rm -f /tmp/ivshmem_socket
              fi
              ${pkgs.sudo}/sbin/sudo -u microvm ${pkgs.qemu_kvm}/bin/ivshmem-server -p ${pidFilePath} -n 2 -m /dev/shm -l ${builtins.toString cfg.ivShMemServer.memSize}M
            '';
        in {
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
      })
    ];
  }

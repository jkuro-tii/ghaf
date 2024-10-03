# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
  pkgs,
  options,
  ...
}: let
  cfg = config.ghaf.profiles.applications;
in
  with lib; {
    options.ghaf.profiles.applications = {
      enable = mkEnableOption "Some sample applications";
      #TODO Create options to allow enabling individual apps
      #weston.ini.nix mods needed
      ivShMemServer = {
        serverSocketPath = mkOption {
          type = types.path;
          default = "/run/user/${builtins.toString config.ghaf.users.accounts.uid}/memsocket-server.sock";
          description = mdDoc ''
            Defines location of the listening socket.
            It's used by waypipe as an output socket when running in server mode
          '';
        };
        clientSocketPath = mkOption {
          type = types.path;
          default = "/run/user/${builtins.toString config.ghaf.users.accounts.uid}/memsocket-client.sock";
          description = mdDoc ''
            Defines location of the output socket. It's fed
            with data coming from AppVMs.
            It's used by waypipe as an input socket when running in client mode
          '';
        };
        instancesCount = mkOption {
          type = types.int;
          default = builtins.length options.ghaf.namespaces.vms.value;
        };
      };
    };

    config = mkIf cfg.enable {
      # TODO: Needs more generic support for defining application launchers
      #       across different window managers.
      ghaf = {
        profiles.graphics.enable = true;
        graphics.enableDemoApplications = true;
      };
    };
  }

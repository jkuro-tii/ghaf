# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  config,
  lib,
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
        memSize = mkOption {
          type = lib.types.str;
          default = "16M";
          description = mdDoc ''
          Defines shared memory size
        '';
        };
        vmCount = mkOption {
          type = lib.types.int;
          default = 6;
          description = mdDoc ''
          Defines maximum number of application VMs
        '';
        };
      };
    };

    config = mkIf cfg.enable {
      # TODO: Needs more generic support for defining application launchers
      #       across different window managers.
      ghaf = {
        profiles.graphics.enable = true;
        graphics.weston.enableDemoApplications = true;
      };
    };
  }

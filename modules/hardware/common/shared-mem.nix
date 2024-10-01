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
with lib; {
    options.ghaf.shm = builtins.trace "!!! shm !!!" {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = mdDoc ''
          Enables using shared memory between VMs.
        '';
      };
      memSize = mkOption {
        type = types.int;
        default = 16;
        description = mdDoc ''
          Defines shared memory size in MBytes
      '';
      };
    };
    
    config.boot.kernelParams = let 
      hugepagesz = "2M"; # valid values: "2M" and "1G", as kernel supports these huge pages' size
      hugepages =
        if hugepagesz == "2M"
          then config.ghaf.shm.memSize / 2
          else config.ghaf.shm.memSize / 1024;
    in optionals config.ghaf.shm.enable
      [
            "hugepagesz=${hugepagesz}"
            "hugepages=${toString hugepages}"
      ];

}
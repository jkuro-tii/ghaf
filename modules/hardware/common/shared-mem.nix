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
    options.ghaf.shm = builtins.trace "!!! shm !!!" { # jarekk: remove
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
      flataddr = mkOption {
        type = types.str;
        default = "0x920000000";
        description = mdDoc ''
          If set to a non-zero value, it maps the shared memory
          into this physical address. The value is arbitrary chosen, platform
          specific, in order not to conflict with other memory areas (e.g. PCI).
        '';
      };
      vms_enabled = mkOption {
        type = types.listOf types.str; 
        default = [];
        description = mdDoc ''
          If set to a non-zero value, it maps the shared memory
          into this physical address. The value is arbitrary chosen, platform
          specific, in order not to conflict with other memory areas (e.g. PCI).
        '';
      };
      instancesCount = mkOption {
        type = types.int;
        default = builtins.length config.ghaf.namespaces.vms;
      };
    };
    
    config.boot.kernelParams = let 
      hugepagesz = "2M"; # valid values: "2M" and "1G", as kernel supports these huge pages' size
      hugepages =
        if hugepagesz == "2M"
          then config.ghaf.shm.memSize / 2
          else config.ghaf.shm.memSize / 1024; # TODO jarekk: remove
    in builtins.trace (">>>> kernelParams vms_enabled=" + (builtins.toString config.ghaf.shm.vms_enabled)) 
    (optionals config.ghaf.shm.enable
      [
            "hugepagesz=${hugepagesz}"
            "hugepages=${toString hugepages}"
      ]);

    config.ghaf.hardware.definition.gpu.kernelConfig.kernelParams = 
      builtins.trace (">>>>> " + (builtins.toString config.ghaf.shm.instancesCount))
      optionals config.ghaf.shm.enable
      [
        "kvm_ivshmem.flataddr=${config.ghaf.shm.flataddr}"
      ];
}
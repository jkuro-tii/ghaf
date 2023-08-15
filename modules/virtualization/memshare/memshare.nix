# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  config,
  pkgs,
  ...
}:
let

  cfg = config.ghaf.virtualization.memshare; 
in
with lib; {
  # config.ghaf.virtualization.memshare.kernel =  pkgs.linuxPackages_latest.kernel;
  # config.microvm.vms.netvm.config.config.microvm.hypervisor <- reference to the VM hypervisor
  options.ghaf.virtualization.memshare = {
    enable = mkOption {
      description = "Memory sharing option";
      type = types.bool;
      default = false;
    };

    size = mkOption {
      description = "Shared memory file size (MiB)";
      type = types.string;
      default = "";
    };

    filePath = mkOption {
      description = "Shared memory file path";
      type = types.path;
      default = /dev/shm/memshare;
      example = /dev/shm/memshare;
    };

    makeMemoryFile = mkOption {
      description = "Add creating the memory file into systemd startup";
      type = types.bool;
      default = false;
    };

    kernel = mkOption {
        type = types.package;
        default = pkgs.linuxPackages_6_4.kernel.override {
            kernelPatches = [ {
              name = "Shared memory patch";
              patch = ./0001-Memory-sharing-driver.patch;
            } ];
            extraConfig = ''
              VIRT_DRIVERS y
              VIRTIO_NET y
              VIRTIO_CONSOLE y
              VIRTIO_MMIO y
              VIRTIO_PCI y
              VIRTIO_PMEM n
              LIBNVDIMM y
            '';
        };
        description = ''
          Linux kernel built with the memory sharing module
        '';
    };
  };
  config = mkIf cfg.enable {
    systemd.services."memshare" = (mkIf cfg.makeMemoryFile 
#    builtins.trace ("  >>>systemd.services>>>>  " + (builtins.toString (builtins.attrNames config.microvm)))
    {
        before = builtins.trace (">>>systemd.services.before>>>>  ") [ /*"microvm@netvm.service"*/ "multiuser.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
        ls
        '';

    });
    # virtualisation.docker.enable = "true";
    # microvm.kernel = pkgs.linuxPackages_latest;
    # microvm.vms.netvm.config.microvm.kernel = pkgs.linuxPackages_latest;
  };
}


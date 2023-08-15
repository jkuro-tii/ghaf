# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  configHost = config;
  memshareBaseConfiguration = {
    imports = [
      ({lib, ...}: {
        ghaf = {
          users.accounts.enable = lib.mkDefault configHost.ghaf.users.accounts.enable;
          development = {
            # NOTE: SSH port also becomes accessible on the network interface
            #       that has been passed through to NetVM
            ssh.daemon.enable = lib.mkDefault configHost.ghaf.development.ssh.daemon.enable;
            debug.tools.enable = lib.mkDefault configHost.ghaf.development.debug.tools.enable;
          };
        };

        networking.hostName = "memshare";
        system.stateVersion = lib.trivial.release;

        nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
        nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

        microvm.hypervisor = "qemu";
        ghaf.virtualization.memshare.enable = true;
        ghaf.virtualization.memshare.makeMemoryFile = true;
        # ghaf.virtualization.memshare.size = "13M";
        # ghaf.virtualization.memshare.filePath = "/dev/shm/memshare";

        microvm.kernel = config.ghaf.virtualization.memshare.kernel;

        microvm.qemu.bios.enable =      
        builtins.trace (">>>microvm.qemu.bios.enable>>>>  " + (builtins.toString (builtins.attrNames config.microvm.vms.memshare.config.config)))
        false;
        microvm.storeDiskType = "squashfs";

        imports = import ../../module-list.nix;
      })
    ];
  };

in {

  config = {
    microvm.vms."memshare" = {
      autostart = true;
      config =
        memshareBaseConfiguration
        // {
          imports =
            memshareBaseConfiguration.imports;
        };
      specialArgs = {inherit lib;};
    };
  };
}

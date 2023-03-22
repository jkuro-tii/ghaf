# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  self,
  nixpkgs,
  microvm,
  system,
}:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    # TODO: Enable only for development builds
    ../../modules/development/authentication.nix
    ../../modules/development/ssh.nix
    ../../modules/development/packages.nix

    microvm.nixosModules.microvm

    ({pkgs, ...}: {
      config = {
        nixpkgs.overlays = [
          self.memshare_overlay
        ];

        /* Kernel change must be done here - e.g. pkgs.linuxPackages_6_1 and in the
           above memshare_overlay overlay */
        boot.kernelPackages =
          pkgs.linuxPackages_latest.extend (_: _: {
          kernel = pkgs.memsharevm-kernel;
        });

        networking.hostName = "memshare";
        # TODO: Maybe inherit state version
        system.stateVersion = "22.11";

        microvm.hypervisor = "qemu";
        microvm.mem = 2048;
        # TODO: supply pmem parameters
        microvm.qemu.extraArgs = [ 
          "-object memory-backend-file,id=mem1,share,mem-path=/dev/shm/virtio_pmem.img,size=2M"
          "-device virtio-pmem-pci,memdev=mem1,id=nv1"
        ];
        microvm.kernelParams = [ "param for memshare testing app" ];

      };
    })
  ];
}

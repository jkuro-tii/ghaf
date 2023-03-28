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

        /* Kernel change must be done here and in the
           above memshare_overlay in the overlay_config.nix file in this dir. 
           E.g. for specific kernel version use: pkgs.linuxPackages_6_1.extend 
         */
        boot.kernelPackages =
          pkgs.linuxPackages_latest.extend (_: _: {
          kernel = pkgs.memsharevm-kernel;
        });

        networking.hostName = "memshare";
        # TODO: Maybe inherit state version
        system.stateVersion = "22.11";

        microvm.hypervisor = "cloud-hypervisor";
        microvm.mem = 2048;
      };
    })
  ];
}

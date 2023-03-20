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

        boot.kernelPackages =
          pkgs.linuxPackages_latest.extend (_: _: {
          kernel = pkgs.memsharevm-kernel;
        });

        networking.hostName = "memshare";
        # TODO: Maybe inherit state version
        system.stateVersion = "22.11";

        microvm.hypervisor = "crosvm";
        microvm.mem = 2048;

      };
    })
  ];
}

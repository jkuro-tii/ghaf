# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  self,
  microvm,
  netvm,
  memsharevm,
}: {...}: {
  imports = [
    (import ./minimal.nix)

    microvm.nixosModules.host

    (import ./microvm.nix {inherit self netvm memsharevm;})

    ./networking.nix
  ];

  networking.hostName = "ghaf-host";
  system.stateVersion = "22.11";
}

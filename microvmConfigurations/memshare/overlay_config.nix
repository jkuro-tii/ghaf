# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ self }: {
  memshare_overlay =  self: super: {
    memsharevm-kernel = super.linuxPackages_latest.callPackage ./memsharevm-kernel.nix {};
  };
}

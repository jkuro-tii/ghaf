# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

/* Kernel change must be done here and in the default.nix file in this dir. 
    E.g. for specific kernel version use: super.linuxPackages_6_1.callPackage 
*/

{ self }: {
  memshare_overlay =  self: super: {
    memsharevm-kernel = super.linuxPackages_latest.callPackage ./memsharevm-kernel.nix {};
  };
}

# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ self }: {
  netvm_overlay =  self: super: { netvm-kernel = builtins.trace "overlay is setting microvm-kernel "
      (super.linuxPackages_latest.callPackage ./netvm-kernel.nix {});
      };
}

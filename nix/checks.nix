# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{lib, ...}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: {
    checks =
      {
        reuse =
          pkgs.runCommandLocal "reuse-lint" {
            buildInputs = [pkgs.reuse];
          } ''
            cd ${../.}
            reuse lint
            touch $out
          '';
        module-test-hardened-host-kernel =
          pkgs.callPackage ../modules/host/kernel/test {inherit pkgs;};
      }
      // (lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self'.packages);
  };
}

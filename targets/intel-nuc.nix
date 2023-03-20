# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Intel NUC 11 Pro -target
{
  self,
  nixpkgs,
  nixos-generators,
  microvm,
}: let
  name = "intel-nuc";
  system = "x86_64-linux";
  formatModule = nixos-generators.nixosModules.raw-efi;
  intel-nuc = variant: extraModules: let
    hostConfiguration = nixpkgs.lib.nixosSystem {
      inherit system;
      modules =
        [
          (import ../modules/host {
            inherit self microvm netvm memsharevm;
          })
          ./common-${variant}.nix

          ../modules/graphics/weston.nix

          formatModule
        ]
        ++ extraModules;
    };
    netvm = "netvm-${name}-${variant}";
    memsharevm = "memsharevm-${name}-${variant}";
  in {
    inherit hostConfiguration netvm memsharevm;
    name = "${name}-${variant}";
    netvmConfiguration = import ../microvmConfigurations/netvm {
      inherit self nixpkgs microvm system;
    };
    memsharevmConfiguration = import ../microvmConfigurations/memshare {
      inherit self nixpkgs microvm system;
    };
    package = hostConfiguration.config.system.build.${hostConfiguration.config.formatAttr};
  };
  debugModules = [../modules/development/intel-nuc-getty.nix];
  targets = [
    (intel-nuc "debug" debugModules)
    (intel-nuc "release" [])
  ];
in {
  nixosConfigurations =
    builtins.listToAttrs (map (t: nixpkgs.lib.nameValuePair t.name t.hostConfiguration) targets)
    // builtins.listToAttrs (map (t: nixpkgs.lib.nameValuePair t.netvm t.netvmConfiguration) targets)
    // builtins.listToAttrs (map (t: nixpkgs.lib.nameValuePair t.memsharevm t.memsharevmConfiguration) targets);
  packages = {
    x86_64-linux =
      builtins.listToAttrs (map (t: nixpkgs.lib.nameValuePair t.name t.package) targets);
  };
}

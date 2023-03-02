# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  self,
  nixpkgs,
  nixos-generators,
  microvm,
}: let
  name = "vm";
  system = "x86_64-linux";
  formatModule = nixos-generators.nixosModules.vm;
  microvmm-kernel = final: prev: { microvm1-kernel = builtins.trace "Overlay" "Overlay";};
  pkgs = import nixpkgs { inherit system; overlays = [microvmm-kernel];
          microvm-kernel = 12;};
  vm = variant: let
    hostConfiguration = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        { nixpkgs = { inherit pkgs; };}
        (import ../modules/host {
          inherit self microvm netvm;
        })
        ./common-${variant}.nix

        ../modules/graphics/weston.nix

        formatModule
      ];
    };
    netvm = "netvm-${name}-${variant}";
  in {
    inherit hostConfiguration netvm pkgs;
    name = "${name}-${variant}";
    netvmConfiguration = 
    let tmp = import ../microvmConfigurations/netvm {
      inherit nixpkgs microvm system;
    };
    in builtins.trace tmp.pkgs.microvm-kernel.version  tmp;
    package = hostConfiguration.config.system.build.${hostConfiguration.config.formatAttr};
  };
  targets = [
    (vm "debug")
    (vm "release")
  ];
in {
  nixosConfigurations =
    builtins.listToAttrs (map (t: nixpkgs.lib.nameValuePair t.name t.hostConfiguration) targets)
    // builtins.listToAttrs (map (t: nixpkgs.lib.nameValuePair t.netvm t.netvmConfiguration) targets);
  packages = {
    x86_64-linux =
      builtins.listToAttrs (map (t: nixpkgs.lib.nameValuePair t.name t.package) targets);
  };
}

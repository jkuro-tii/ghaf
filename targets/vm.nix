# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  self,
  nixpkgs, /* [ "_type" "checks" "htmlDocs" "inputs" "lastModified" "lastModifiedDate" "legacyPackages" "lib" "narHash" "nixosModules" "outPath" "outputs" "rev" "shortRev" "sourceInfo" ]*/
          /* no microvm!!! */
  nixos-generators,
  microvm,
}: let
  name = # builtins.trace (/*"vm.nix:9 nixpkgs: " + */(builtins.attrNames nixpkgs.legacyPackages.x86_64-linux.microvm-kernel)) 
  "vm";
  system = "x86_64-linux";
  formatModule = nixos-generators.nixosModules.vm;
  overlay-kernel = self: super: /*final: prev: */{
    microvm-kernel =  builtins.trace ("microvm-kernel!") "overlay-kernel";
    # pkkgs.microvm-kernel = builtins.trace ("!!!!overlay + super = " +/*(builtins.toString*/(builtins.toString (builtins.attrNames pkgs.execFormat)))
    # super.microvm-kernel.override {
    #   extraConfig = ''
    #     ERROR = error;
    #   '';
    #     /* microvm-kernel = builtins.trace "Overlay" "Overlay"; */
    #     /*pkgs.*/microvm-kernel = "xxx" /*builtins.trace "Oversssslay" "Overlaassay"*/;
    # };
  #  "microvm kernel" ;
  };

  # outputs.nixosConfigurations.vm-debug.pkgs.overlays
  pkgs = import nixpkgs { inherit system; overlays = builtins.trace "netvm/vm.nix:27  overlays set" [ overlay-kernel ]; };
  vm = variant: let
    hostConfiguration = 
      #builtins.trace  ("hostConfiguration: microvm.pkgs.microvm-kernel.version = " + (/*toString*/ microvm/*.packages.x86_64-linux.microvm-kernel.version*/))
      nixpkgs.lib.nixosSystem {
      inherit system;
      modules = let tmp = [
       { nixpkgs = { inherit pkgs; }; }
        (import ../modules/host {
          inherit self microvm netvm;
        })
        ./common-${variant}.nix

        ../modules/graphics/weston.nix

        formatModule
      ];
      in (builtins.trace (tmp) tmp);
    };
    netvm = "netvm-${name}-${variant}";
  in {
    inherit hostConfiguration netvm pkgs;
    name = "${name}-${variant}";
    overlays = overlay-kernel;

    netvmConfiguration = 
      let tmp = import ../microvmConfigurations/netvm {
        inherit self nixpkgs microvm system;
      };
      in 
        builtins.trace  ("vm.nix 58: Got netvmConfiguration.pkgs.microvm-kernel.version = " + toString tmp.pkgs.microvm-kernel.version)   
        (builtins.trace  ("vm.nix 59: microvm = " + microvm))  
    tmp;
                                                                                  
    package = let package_ = hostConfiguration.config.system.build.${hostConfiguration.config.formatAttr};
    in 
    builtins.trace  ("vm.nix 56: package = "+ package_) 
    package_
    ;
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

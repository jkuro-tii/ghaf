# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "Ghaf - Documentation and implementation for TII SSRC Secure Technologies Ghaf Framework";

  nixConfig = {
    extra-trusted-substituters = [
      "https://cache.vedenemo.dev"
      "https://cache.ssrcdevops.tii.ae"
    ];
    extra-trusted-public-keys = [
      "cache.vedenemo.dev:RGHheQnb6rXGK5v9gexJZ8iWTPX6OcSeS56YeXYzOcg="
      "cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    microvm = {
      # TODO: change back to url = "github:astro/microvm.nix";
      # url = "github:mikatammi/microvm.nix/wip_hacks_2";
      # url = "github:jkuro-tii/microvm.nix/wip_hacks_2";
      url = "path:/home/jk/tmp/flakes/microvm.nix/";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    jetpack-nixos = {
      url = "github:anduril/jetpack-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nixos-generators,
    nixos-hardware,
    microvm,
    jetpack-nixos,
  }: 
  let
    systems = with flake-utils.lib.system;
      #builtins.trace "microvm: outputs" 
    # builtins.trace (builtins.trace ("flakes: microvm= " + (builtins.toString microvm.outputs.overlay))) 
    [
      x86_64-linux
      aarch64-linux
    ];
    mm = nixpkgs.lib.attrsets.recursiveUpdate microvm {packages.x86_64-linux.microvm-kernel = "asasa";};

  in
    let microvm = mm; in
    # nixpksgs.overlays  { aaa="asasas"; };
    # Combine list of attribute sets together
    # /*  config.*/nixpkgs.packageOverrides = builtins.trace "----------------" (pkgs: {
    # microvm-kernel = pkgs.microvm-kernel.override {
    #   extraConfig = ''
    #   ...
    # '';
    # };});
    nixpkgs.lib.foldr nixpkgs.lib.recursiveUpdate {} [
      # Documentation
      (flake-utils.lib.eachSystem systems (system: {
        packages = let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          doc = pkgs.callPackage ./docs/doc.nix {};
        };
        overlays = final: prev: { 
          microvm-kernel = builtins.trace "----------" "";
          boot.kernelPackages = builtins.trace "--------------------boot.kernelPackages" "????";
        }; # goes into top namespace, outputs.overlays
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
      }))
      # overlays = final: prev: { }
      # (overlay = final: prev: {
      # microvm-kernel = builtins.trace "flake.nix:82 setting local overlay variable" "xxx";})

      # Target configurations
      (import ./targets {inherit self nixpkgs nixos-generators nixos-hardware microvm jetpack-nixos;})

      # Hydra jobs
      (import ./hydrajobs.nix {inherit self;})

    ];
}

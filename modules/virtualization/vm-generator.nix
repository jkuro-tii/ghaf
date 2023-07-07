# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ 
  self
}: 
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: 

{
    environment.systemPackages = with pkgs; 
      let image = self.inputs.nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [

        ];
        format = "iso";
      };
    in 
      builtins.trace (">>>>>>>>>>>>Installing vm-generators" +
      ("\n>>>>>>>>>>>>self=" + (builtins.toString(builtins.attrNames self.inputs.nixos-generators))) +
      ("\n image = " + image) + ("\n modulesPath = " + modulesPath)
      )
      [(
        # (callPackage ./vm-generator-package.nix {})
        pkgs.stdenv.mkDerivation {
          name = "vm-generators-test-image";
          phases = [ "installPhase" ];
          installPhase = builtins.trace ">>>>>>>>>>>>installPhase..."
          ''
              echo ">>>>>Installing vm-generators!!!!!"
              mkdir -p $out/bin/vm-generators
              cp -rf ${image}/* $out/bin/vm-generators
          '';
        }
      )];
}

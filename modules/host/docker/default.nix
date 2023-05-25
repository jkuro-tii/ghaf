# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/virtualisation/docker.nix")
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  environment.systemPackages = with pkgs;
  [
    (callPackage ./packages.nix {})
    /*
    (callPackage

      (stdenv.mkDerivation {
        name = builtins.trace ("script= " / *+ script* /) "docker_test";

        phases = [ "installPhase" ];
        installPhase = builtins.trace (">>>>>>>> installPhase " ) ''
          mkdir -p $out
          echo mkdir -p $out/bin
          echo mkdir -p $out/home/ghaf
          echo ">>>>>>>>>>>>>> out= " $out
          echo "Ala ma 2 koty"  $out/bin/jk1.test
          echo "Ala ma kota"  $out/bin/jk.test
          echo $out  $out/bin/jk.test
          echo cp -r {script}/* $out
          echo "Ala ma 22 koty"   $out/home/ghaf/jk.home
        '';
      }) {} )*/
  ];
}

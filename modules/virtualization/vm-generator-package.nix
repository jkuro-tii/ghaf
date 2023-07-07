# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
    name = "vm-generators-test-image";
    phases = [ "installPhase" ];
    installPhase = ''
        echo ">>>>>Installing vm-generators"
        mkdir -p $out/bin/vm-generators
        ls -l > $out/bin/vm-generators/jk
      '';
}

/*
pkgs.stdenv.mkDerivation {
  name = "docker_test";

  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp -r ${script}/* $out
    '';
}
*/
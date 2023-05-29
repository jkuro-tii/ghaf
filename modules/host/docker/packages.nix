# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ pkgs ? import <nixpkgs> {} }:

let
  dockerImage = 
    pkgs.dockerTools.buildImage rec {

    name = "busybox_test";
    tag = "latest";

    created = "now";
    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = [ /*pkgs.busybox*/ ];
      pathsToLink = [ "/bin" ];
    };
    config.Cmd = [ "/bin/bash" ];
  };

  script = pkgs.writeScriptBin "run-docker-load" ''
    #! ${pkgs.stdenv.shell}
    set -e

    echo "loading docker image..." >&2
    docker load < ${dockerImage}
  '';
in
pkgs.stdenv.mkDerivation {
  name = "docker_test";

  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp -r ${script}/* $out
    '';
}

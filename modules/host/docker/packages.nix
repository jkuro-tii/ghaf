{ pkgs ? import <nixpkgs> {} }:

let
  dockerImage = 
    pkgs.dockerTools.buildImage rec {

    name = builtins.trace (">>>> buildImage") "busybox_test";
    tag = "latest";

    created = "now";
    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = [ pkgs.busybox ];
      pathsToLink = [ "/bin" ];
    };

    config.Cmd = [ "/bin/bash" ];
  };

  script = builtins.trace (">>>Docker load script= " + dockerImage) pkgs.writeScriptBin "run-docker-load" ''
    #! ${pkgs.stdenv.shell}
    set -e

    #echo "building root image..." >&2
    #imageOut=$(nix-build -A $ {image} --no-out-link)
    #echo "importing root image..." >&2
    echo "loading docker image..." >&2
    docker load < ${dockerImage}
    #echo "building {unstable.version}..." >&2
    #cp -f {baseDocker} Dockerfile
    #docker build -t lnl7/nix:{unstable.version} .
    #docker rmi nix-base:{unstable.version}
  '';
in
pkgs.stdenv.mkDerivation {
  name = builtins.trace ("script= " + script)
  "docker_test";

  phases = [ "installPhase" ];
  installPhase = builtins.trace (">>>>>>>> installPhase " ) ''
    mkdir -p $out/bin
    cp -r ${script}/* $out
    '';
}

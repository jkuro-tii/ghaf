{ pkgs ? import <nixpkgs> {} }:

let
  image = pkgs.dockerTools.pullImage {
    imageName = "nixos/nix";
    imageDigest =
      "sha256:473a2b527958665554806aea24d0131bacec46d23af09fef4598eeab331850fa";
    finalImageName = "nix_jkk";
    finalImageTag = "2.11.1";
    sha256 = "sha256-UYVwe2Y1E3dwpK+RK0jGbhBbc9CIMbi7uTziWmzH0Dw=";
    os = "linux";
    arch = "aarch64";
  };
  #   pkgs.dockerTools.buildImage rec {

  #   name = "busybox_test";
  #   tag = "latest";

  #   fromImageTag = "busybox:latest";

  #   created = "now";
  #   copyToRoot = pkgs.buildEnv {
  #     name = "image-root";
  #     paths = [ /*pkgs.busybox*/ ];
  #     pathsToLink = [ "/bin" ];
  #   };

  #   config.Cmd = [ "/bin/bash" ];
  # };

  script = builtins.trace (">>>Docker image=" + image) pkgs.writeScriptBin "run-docker-build" ''
    #! ${pkgs.stdenv.shell}
    set -e

    echo "building root image..." >&2
    imageOut=$(nix-build -A ${image} --no-out-link)
    echo "importing root image..." >&2
    docker load < $imageOut
    echo "building {unstable.version}..." >&2
    cp -f {baseDocker} Dockerfile
    docker build -t lnl7/nix:{unstable.version} .
    docker rmi nix-base:{unstable.version}
  '';
in
#  script
pkgs.stdenv.mkDerivation {
  name = builtins.trace ("script= " + script)
  "docker_test";

  phases = [ "installPhase" ];
  BUILD_TARGET = "\"Ala ma 41kota!\"";
  installPhase = builtins.trace (">>>>>>>> installPhase " ) ''
    mkdir -p $out/bin
    mkdir -p $out/home/ghaf
    echo ">>>>>>>>>>>>>> out= " $out
    echo "Ala ma 2 koty" > $out/bin/jk1.test
    echo "Ala ma kota" > $out/bin/jk.test
    echo $out >> $out/bin/jk.test
    cp -r ${script}/* $out
    echo "Ala ma 22 koty" >  $out/home/ghaf/jk.home
#   '';
}
#   src =
#   cleanSourceWith {
#     filter = name: _type: !(hasSuffix ".nix" name);
#     src = cleanSource script;
#   };

#   doCheck = true;


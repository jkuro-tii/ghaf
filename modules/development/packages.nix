# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs, ...}: {
  environment.systemPackages = with pkgs; 
/*
  let dockerScript = 
    pkgs.writeScriptBin "run-docker-build" ''
      #! {native.stdenv.shell}
      set -e

      echo "building root image..." >&2
      imageOut=$(nix-build -A image --no-out-link)
      echo "importing root image..." >&2
      docker load < $imageOut
      echo "building {unstable.version}..." >&2
      cp -f {baseDocker} Dockerfile
      docker build -t lnl7/nix:{unstable.version} .
      docker rmi nix-base:{unstable.version}
      ''
    ; 
  in*/
  let 
    pciutils_ = builtins.trace (">>> pciutils = " + pciutils) pciutils;
    docker_ = builtins.trace (">>> docker = " +
        (pkgs.callPackage ./test.nix { inherit pkgs; }))
        
        (pkgs.callPackage ./test.nix { inherit pkgs; });
    docker_jk = builtins.trace (">>> docker_system = " + docker) docker;

  in
  [
    # For lspci:
  #  pciutils_

   qemu

    # For lsusb:
    usbutils

    # Useful in NetVM
    ethtool

    # Basic monitors
    htop
    iftop
    iotop

    traceroute
    dig

    docker_

    # docker_jk

    # (pkgs.stdenv.mkDerivation {
    #   name = builtins.trace ">>>>docker_test";
    #   ph
    # ases = [ "installPhase" ];
    # #   src = pkgs.lib.cleanSource ./.;
    #   installPhase = /*builtins.trace ("out=" + out)*/ ''
    #     echo "out= " $out
    #     mkdir -p $out/dockerdata
    #     touch $out/jk.test
    #     echo cp ${dockerScript}/run-docker-build $out
    #     ''
    #     ;
    # })
  # (pkgs.dockerTools.buildImage {
  #   name = "hello";
  #   tag = "latest";
  #   created = "now";
  #   copyToRoot = pkgs.buildEnv {
  #     name = "image-root";
  #     paths = [ pkgs.hello ];
  #     pathsToLink = [ "/bin" ];
  #   };

  #   config.Cmd = [ "/bin/hello" ];
  # })

  ];
}

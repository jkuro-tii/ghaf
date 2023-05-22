# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs, ...}: {
  # inherit nixpkgs;
  environment.systemPackages = with pkgs; [
    # For docker:
    docker
    # dockerTools



  # stdenv.mkDerivation rec {
  #   name = "hello-2.9";
  #   src = fetchurl {
  #   url = "mirror://gnu/hello/${name}.tar.gz";
  #     #  sha256 = "0wqd8sjmxfskrflaxywc7gqw7sfawrfvdxd9skxawzfgyy0pzdz6";
  #   };
  #   doCheck = true;

  #   passthru.tests.version =
  #   testVersion { package = hello; };
  # }
      (pkgsStatic.callPackage ./nix-docker/default.nix {})
  ];


}
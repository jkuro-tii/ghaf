# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  gcc,
  gnumake,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  name = "memtest";

  src = fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "058dd0e49d608f7b990b521f5ae2d39a89fcc8f9";
    sha256 = "sha256-c7ZaSFxEwPMxtyl6ay5rpZcycA1XI4J7AxQ7WdNT3cQ=";
  };

  nativeBuildInputs = [gcc gnumake];

  prePatch = ''
    cd app/test
  '';

  installPhase = ''
    mkdir -p $out/bin
    install ./memtest $out/bin/memtest
  '';

  meta = with lib; {
    description = "memtest";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

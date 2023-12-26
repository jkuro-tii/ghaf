# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  pkgs,
  lib,
  ...
}:
stdenv.mkDerivation {
  name = "memsocket";

  src = pkgs.fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "2ce104490b4dd4be22267bbebc2c8c5bc0987acb";
    sha256 = "sha256-/6No77WDlt8IlN36ccHaGzl+H8RM2NHNAA07e3OWZTU=";
  };

  prePatch = ''
    cd app
  '';
  installPhase = ''
    mkdir -p $out/bin
    install ./memsocket $out/bin/memsocket
  '';

  meta = with lib; {
    description = "memsocket";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

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
    rev = "83d4ed4cb11cf501db04d0c02092c2d21ecb0dd9";
    sha256 = "sha256-+OT7BO2EPS/bprQ3DZy/RyVA1mtqWrEXEoqUkM2CecE=";
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

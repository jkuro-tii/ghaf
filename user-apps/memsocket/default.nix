# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  pkgs,
  lib,
  debug,
  vms,
  ...
}:
stdenv.mkDerivation {
  inherit debug vms;
  name = "memsocket";

  src = pkgs.fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "6c4c279b18092458e076d74f83363b0815c1f6b2";
    sha256 = "sha256-xIWjiWtxKXEPdTQwSxtfIDw3zX9Cu5xwH3CSbBiVJEY=";
  };

  nativeBuildInputs = with pkgs; [ gcc gnumake ];

#  CFLAGS = "-g -O1 -DVM_COUNT=" + (toString vms) + (if debug then " -DDEBUG_ON" else "");
#  CFLAGS = "-g -pg -DVM_COUNT=" + (toString vms);
  CFLAGS = "-O2 -DVM_COUNT=" + (toString vms);

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

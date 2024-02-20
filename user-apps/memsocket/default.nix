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
    rev = "aeadb14d211f92fe8e207e604aaa818caef4b77a";
    sha256 = "sha256-JY0WSRkA4Fpu5SIoSPXLlrDr++wWTqZPkQd9osOXx2Q=";
  };

  nativeBuildInputs = with pkgs; [ gcc gnumake ];

  CFLAGS = "-O2 -DVM_COUNT=" + (toString vms)  + (if debug then " -DDEBUG_ON" else "");
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

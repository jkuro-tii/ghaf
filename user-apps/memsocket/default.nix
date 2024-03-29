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

  name = "memsocket";

  src = pkgs.fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "9e3e97edaf727dcf0743d497652cf9fd61be0494";
    sha256 = "sha256-hWpueXazTlqyy21V/ZuKj07+Gq/ee5UCyt2wqXMwy0U=";
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
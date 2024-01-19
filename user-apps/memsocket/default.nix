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
    rev = "5c59e3818db108b93d806ef750058ed4d5b71de2";
    sha256 = "sha256-YfcfxZyUsHez+njYtwrlnUlrlh3hbdubvNDGiuD4UXM=";
  };

  nativeBuildInputs = with pkgs; [ gcc gnumake ];

  CFLAGS = "-DVM_COUNT=" + (toString vms) + (if debug then " -DDEBUG_ON" else "");

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

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
    rev = "6f953091c15b08507eef6f6ac48cb1115a2af5e6";
    sha256 = "sha256-q9kHXGlchTDo+7Hy73l62gMWAmFpmnogcLESq3JGDXo=";
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

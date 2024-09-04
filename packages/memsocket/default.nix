# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  debug ? true, # TODO: change to false
  vms,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  name = "memsocket";

  src = fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "52ac5d3719d2139ac36f25f81f93b8ae4ad3f527";
    sha256 = "sha256-Km0zDMPp9gEUa+ING+NW4IO63eC8+gFVzNZSAhF4gv4=";
  };

  CFLAGS = let
    tmp =
      "-O2 -DVM_COUNT="
      + (toString vms)
      + (
        if debug
        then " -DDEBUG_ON"
        else ""
      );
  in
    builtins.trace (">> CFLAGS=" + tmp) tmp;
  sourceRoot = "source/app";

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

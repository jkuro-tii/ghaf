# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  debug,
  vms,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  name = "memsocket";

  src = fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "5e1cd6bdb2f9e4d5825be689d86f57ceeb7c3b5d";
    sha256 = "sha256-7U3NpX/FalIGxX7gf5ImEX+k7YTTdF4FtL7OsY3uTvg=";
  };

  CFLAGS =
    "-O2 -DVM_COUNT="
    + (toString vms)
    + (
      if debug
      then " -DDEBUG_ON"
      else ""
    );
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

# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  debug,
  vms,
  gcc,
  gnumake,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  name = "memsocket";

  src = fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "694d90393ae7bd7a67000c0e4373bfe07f0aafc3";
    sha256 = "sha256-y1o9Md9apgn+mjBZ9wScWUNQ3ZgxbT0TKxl8bIMZxGs=";
  };

  nativeBuildInputs = [gcc gnumake];

  CFLAGS =
    "-O2 -DVM_COUNT="
    + (toString vms)
    + (
      if debug
      then " -DDEBUG_ON"
      else ""
    );
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

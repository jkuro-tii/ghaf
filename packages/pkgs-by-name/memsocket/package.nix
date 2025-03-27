# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  debug ? false,
  shmSlots ? null,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  name = "memsocket";

  src = fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "fa83ff1b62796ca2379d2871683bad0683e0c542";
    sha256 = "sha256-Ai4qGI/osmai3SAn0tFF2OGO6nQ4qUS/zDYMj7bgw2w=";
  };

  CFLAGS = "-O2 -DSHM_SLOTS=" + (toString shmSlots) + (if debug then " -DDEBUG_ON" else "");
  sourceRoot = "source/app";

  installPhase = ''
    mkdir -p $out/bin
    install ./memsocket $out/bin/memsocket
  '';

  meta = {
    description = "memsocket";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

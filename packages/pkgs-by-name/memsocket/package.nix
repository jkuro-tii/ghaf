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
    rev = "c8a51ff731710960594447283e446887bfae1ddb";
    sha256 = "sha256-Jp8uIHr+V+618JdEFafnGnCWwt1GnYYJgWCwIL6lp5U=";
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

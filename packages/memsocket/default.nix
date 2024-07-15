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
    rev = "ebee711b06514ce941f1284db49b95f620b2f61b";
    sha256 = "sha256-2ChDC3uFZYgRrY4ZcERXg81IWtrEL7A1wCTFnveOqL8=";
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

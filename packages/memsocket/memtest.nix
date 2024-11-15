# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  name = "memtest";

  src = fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "2357926b94ed12c050fdbfbfc0f248393a4c9ea1";
    sha256 = "sha256-9KlHuVbe5qvjRUXj7oyJ1X7CLvqj7/OoVGDWRqpIY2s=";
  };

  sourceRoot = "source/app/test";

  installPhase = ''
    mkdir -p $out/bin
    install ./memtest $out/bin/memtest
  '';

  meta = with lib; {
    description = "memtest";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

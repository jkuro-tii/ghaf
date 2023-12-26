# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  gcc,
  gnumake,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  name = "memtest";

  src = fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "4eef1a7e1f6993a9ba0ef1aa066145c410e2eec6";
    sha256 = "sha256-uaKBtb+bD42RK/Z96dhMrGxNXg+ZV/6iW52ouNQ+QSY=";
  };

  nativeBuildInputs = [gcc gnumake];

  prePatch = ''
    cd app/test
  '';

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

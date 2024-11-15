# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  name = "unsock";

  src = fetchFromGitHub {
    owner = "kohlschutter";
    repo = "unsock";
    rev = "0b3c873c3a5bda41708bb3b46c0434a2b09a3762";
    sha256 = "sha256-E4gzxBjj93p29ceX/dKJuqMPU5wzgRMfOfTq7JE/rqE=";
  };

  # makeFlags = [
  #   "PREFIX=${placeholder "out"}"
  # ];

  makeFlags = [ "PREFIX=$(out)" ];
  installPhase = ''
    make install PREFIX=\$\(out\)
  '';

  meta = with lib; {
    description = "memtest";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

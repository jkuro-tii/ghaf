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
    rev = "d793c23e606bf6ad3ffdf9db0049408792e2c727";
    sha256 = "sha256-zzgdptykR6OjbjzXbN7oNXfgpQ6nfegNMUeYJdzJvB0=";
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

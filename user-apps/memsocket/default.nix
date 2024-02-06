# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  pkgs,
  lib,
  debug,
  vms,
  ...
}:
stdenv.mkDerivation {
  inherit debug vms;
  name = builtins.trace ("vms="+ builtins.toString(vms))"memsocket";

  src = pkgs.fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "b119cf00f90f8f0ba7af9f6387c1f064e4a1cebf";
    sha256 = "sha256-JMU+PRarbyoLD+ZhD1elGkBIJ9MaZcl8+5S4QhZ4GcM=";
  };

  nativeBuildInputs = with pkgs; [ gcc gnumake ];

#  CFLAGS = "-g -O1 -DVM_COUNT=" + (toString vms) + (if debug then " -DDEBUG_ON" else "");
#  CFLAGS = "-g -pg -DVM_COUNT=" + (toString vms);
  CFLAGS = "-O2 -DVM_COUNT=" + (toString vms);

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

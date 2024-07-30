# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  automake,
  autoconf,
  libtool,
  fetchFromGitHub,
  flex,
  pkgconf,
  yacc,
  ...
}:
stdenv.mkDerivation {
  name = "thrift";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "thrift";
    rev = "v0.20.0";
    sha256 = "sha256-cwFTcaNHq8/JJcQxWSelwAGOLvZHoMmjGV3HBumgcWo=";
  };

  nativeBuildInputs = [autoconf automake libtool pkgconf yacc flex];
  patches = [./0001-thrift-use-shm-sockets.patch];
  preConfigure = ''
    ./bootstrap.sh
  '';

  meta = with lib; {
    description = "Apache Thrift";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

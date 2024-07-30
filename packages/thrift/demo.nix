# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  automake,
  autoconf,
  cmake,
  libtool,
  fetchFromGitHub,
  flex,
  pkgconf,
  yacc,
  boost,
  openssl,
  thrift,
  ...
}:
stdenv.mkDerivation {
  name = "thrift_demo";

  src = fetchFromGitHub {
    owner = "apache";
    repo = "thrift";
    rev = "v0.20.0";
    sha256 = "sha256-cwFTcaNHq8/JJcQxWSelwAGOLvZHoMmjGV3HBumgcWo=";
  };

  nativeBuildInputs = [autoconf automake cmake libtool pkgconf yacc flex];
  buildInputs = [boost openssl thrift];
  patches = [./0001-thrift-use-shm-sockets.patch];
  preConfigure = ''
    ./bootstrap.sh
  '';
  buildPhase = ''
    make -C tutorial/cpp
  '';
  installPhase = ''
    mkdir -p $out/bin
    install bin/* $out/bin
  '';

  meta = with lib; {
    description = "Apache Thrift";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

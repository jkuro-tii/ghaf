# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  grpc,
  cmake,
  openssl,
  protobuf,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  name = "gRPC-demo";

  nativeBuildInputs = [cmake];
  buildInputs = [openssl protobuf grpc];

  src = fetchFromGitHub {
    owner = "grpc";
    repo = "grpc";
    rev = "v1.66.0";
    sha256 = "sha256-H0ABT7gRn+G0drgDQ+jEmYldK5mgmbfUQHqqDFGvsVc=";
  };

  gRpcExamples = fetchFromGitHub {
    owner = "jkuro-tii";
    repo = "gRPC_examples";
    rev = "2fc2b8f55b8c3d82351ba67ae51982087561efb6";
    sha256 = "sha256-9W5vMBgBhrb7iioAPsfFYURDspXnQB1rBjVGF2HdIX8=";
  };

  patchPhase = ''
    cp -r $gRpcExamples/* examples/cpp
    chmod u+w examples/cpp/*
  '';
  configurePhase = ''
    echo "configurePhase skipped"
  '';
  buildPhase = ''
    cd examples/cpp/unix_sockets
    mkdir -p build
    cd build
    cmake ..
    make
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp client server $out/bin
  '';

  meta = with lib; {
    description = "gRPC demo programs";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  lib,
  kernel ? null,
  fetchFromGitHub,
  clientServiceWithID ? null,
  ...
}:
stdenv.mkDerivation {
  name = "sec_shm-driver-${kernel.version}";

  src = fetchFromGitHub {
    owner = "tiiuae";
    repo = "shmsockproxy";
    rev = "15617157a4bdbe1232a4edc047334fc914037919";
    sha256 = "sha256-UrJa6/qR+wDNEakdHhKyoMAa8EQLAE8fXoaBRzkmyMM=";
  };

  sourceRoot = "source/secure_shmem";
  hardeningDisable = [
    "pic"
    "format"
  ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags =
    [
      "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
      "MODULEDIR=$(out)/lib/modules/${kernel.modDirVersion}/kernel/drivers/char"
      "ARCH=${stdenv.hostPlatform.linuxArch}"
      "INSTALL_MOD_PATH=${placeholder "out"}"
    ]
    ++ lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
      "CROSS_COMPILE=${stdenv.cc}/bin/${stdenv.cc.targetPrefix}"
    ];

  CROSS_COMPILE = lib.optionalString (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "${stdenv.cc}/bin/${stdenv.cc.targetPrefix}";

  /*
    Convert clientServiceWithID into C structure to be
    included into driver's config table
  */
  patchPhase = let t =
    let
  pow = base: exp: if exp == 0 then 1 else base * (pow base (exp - 1));

  clientNames = lib.unique (map (x: x.client) clientServiceWithID);
  serviceNames = lib.unique (map (x: x.service) clientServiceWithID);

  clientTable = builtins.concatStringsSep ",\n  " (
    map (
      client:
      let
        mask = builtins.foldl' (
          acc: x: if x.client == client then acc + (pow 2 x.id) else acc
        ) 0 clientServiceWithID;
      in
      "  {\"${client}\", 0x${lib.toHexString mask}}"
    ) clientNames
  );

  serviceTable = builtins.concatStringsSep ",\n  " (
    map (
      service:
      let
        mask = builtins.foldl' (
          acc: x: if x.service == service then acc + (pow 2 x.id) else acc
        ) 0 clientServiceWithID;
      in
      "  {\"${service}-vm\", 0x${lib.toHexString mask}}"
    ) serviceNames
  );
in ''
  cat > config.h <<EOF
  #ifndef SECSHM_CONFIG_H
  #define SECSHM_CONFIG_H

  struct client_entry {
    const char* name;
    int bitmask;
  };

  static const struct client_entry CLIENT_TABLE[] = {
    ${clientTable},
    ${serviceTable}
  };

  #define CLIENT_TABLE_SIZE ${builtins.toString (builtins.length clientNames + builtins.length serviceNames)}

  #endif // SECSHM_CONFIG_H
''; in builtins.trace t t ;

  meta = with lib; {
    description = "Secured shared memory on host Linux kernel module";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

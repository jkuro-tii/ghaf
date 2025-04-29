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

  /*
    Convert clientServiceWithID into C structure to be
    fed into driver's config table
  */
  src =
    let
      pow = base: exp: if exp == 0 then 1 else base * (pow base (exp - 1));
      grouped = builtins.groupBy (e: e.service) clientServiceWithID;
      serviceBitmasks = builtins.mapAttrs (
        _service: entries: builtins.foldl' (acc: e: acc + (pow 2 e.id)) 0 entries
      ) grouped;
      combinedEntries = builtins.map (e:
        let
          bitmask = serviceBitmasks.${e.service};
        in
          ''{ "${e.client}", ${builtins.toString e.id}, "${e.service}", 0x${builtins.toString bitmask} }''
      ) clientServiceWithID;
        headerText = ''
          #ifndef CLIENT_TABLE_H
          #define CLIENT_TABLE_H

          struct ClientInfo {
              const char* name;
              int id;
              const char* service;
              int service_mask;
          };
          static const struct ClientInfo client_table[] = {
            ${builtins.concatStringsSep ",\n  " combinedEntries}
          };
          static const int client_table_len = ${toString (builtins.length clientServiceWithID)};

          #endif
  '';

    in
    builtins.trace /*grouped.gui*/ headerText fetchFromGitHub {
      owner = "tiiuae";
      repo = "shmsockproxy";
      rev = "1786d6e312741f9d1a3b17caec086b3dd2899273";
      sha256 = "sha256-vwsK98M7IGNn27QGQSnUq2PUzKogtkRCMsLC1ZWff/E=";
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
      # "CFLAGS_kvm_ivshmem.o=\"-DCONFIG_KVM_IVSHMEM_SHM_SLOTS=${builtins.toString shmSlots}\""
      # jarekk: TODO: generate config here
      "ARCH=${stdenv.hostPlatform.linuxArch}"
      "INSTALL_MOD_PATH=${placeholder "out"}"
    ]
    ++ lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
      "CROSS_COMPILE=${stdenv.cc}/bin/${stdenv.cc.targetPrefix}"
    ];

  CROSS_COMPILE = lib.optionalString (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "${stdenv.cc}/bin/${stdenv.cc.targetPrefix}";

  meta = with lib; {
    description = "Secured shared memory on host Linux kernel module";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

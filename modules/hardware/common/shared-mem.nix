# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Module for Shared Memory Definitions
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.ghaf.shm = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = mdDoc ''
        Enables using shared memory between VMs.
      '';
    };
    memSize = mkOption {
      type = types.int;
      default = 16;
      description = mdDoc ''
        Defines shared memory size in MBytes
      '';
    };
    hostSocketPath = mkOption {
      type = types.path;
      default = "/tmp/ivshmem_socket"; # The value is hardcoded in the application
      description = mdDoc ''
        Defines location of the shared memory socket. It's used by qemu
        instances for memory sharing and sending interrupts.
      '';
    };
    flataddr = mkOption {
      type = types.str;
      default = "0x920000000";
      description = mdDoc ''
        If set to a non-zero value, it maps the shared memory
        into this physical address. The value is arbitrary chosen, platform
        specific, in order not to conflict with other memory areas (e.g. PCI).
      '';
    };
    vms_enabled = mkOption {
      type = types.listOf types.str;
      default = [];
      description = mdDoc ''
        If set to a non-zero value, it maps the shared memory
        into this physical address. The value is arbitrary chosen, platform
        specific, in order not to conflict with other memory areas (e.g. PCI).
      '';
    };
    instancesCount = mkOption {
      type = types.int;
      default = builtins.length config.ghaf.namespaces.vms;
    };
  };

  config.boot.kernelParams = let
    hugepagesz = "2M"; # valid values: "2M" and "1G", as kernel supports these huge pages' size
    hugepages =
      if hugepagesz == "2M"
      then config.ghaf.shm.memSize / 2
      else config.ghaf.shm.memSize / 1024; # TODO jarekk: remove
  in
    builtins.trace (">>>> kernelParams vms_enabled=" + (builtins.toString config.ghaf.shm.vms_enabled))
    (optionals config.ghaf.shm.enable
      [
        "hugepagesz=${hugepagesz}"
        "hugepages=${toString hugepages}"
      ]);
  config.systemd.services.ivshmemsrv = let
    pidFilePath = "/tmp/ivshmem-server.pid";
    ivShMemSrv = let
      vectors = toString (2 * config.ghaf.shm.instancesCount);
    in
      pkgs.writeShellScriptBin "ivshmemsrv" ''
        chown microvm /dev/hugepages
        chgrp kvm /dev/hugepages
        if [ -S ${config.ghaf.shm.hostSocketPath} ]; then
          echo Erasing ${config.ghaf.shm.hostSocketPath} ${pidFilePath}
          rm -f ${config.ghaf.shm.hostSocketPath}
        fi
        ${pkgs.sudo}/sbin/sudo -u microvm -g kvm ${pkgs.qemu_kvm}/bin/ivshmem-server -p ${pidFilePath} -n ${vectors} -m /dev/hugepages/ -l ${(toString config.ghaf.profiles.applications.ivShMemServer.memSize) + "M"}
        sleep 2
      '';
  in
    lib.mkIf config.ghaf.shm.enable {
      enable = true;
      description = "Start qemu ivshmem memory server";
      path = [ivShMemSrv];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardOutput = "journal";
        StandardError = "journal";
        ExecStart = "${ivShMemSrv}/bin/ivshmemsrv";
      };
    };
  config.microvm.vms = let
    vectors = toString (2 * config.ghaf.shm.instancesCount);
    makeAssignment = vmName: {
      ${vmName} = {
        config = builtins.trace (">>>> iter VM: " + vmName) {
          config = {
            microvm = {
              qemu = {
                extraArgs = [
                  "-device"
                  "ivshmem-doorbell,vectors=${vectors},chardev=ivs_socket,flataddr=${config.ghaf.shm.flataddr}"
                  "-chardev"
                  "socket,path=${config.ghaf.shm.hostSocketPath},id=ivs_socket"
                ];
              };
            };
            services = {
              udev = {
                extraRules = ''
                  SUBSYSTEM=="misc",KERNEL=="ivshmem",GROUP="kvm",MODE="0666"
                '';
              };
            };
          };
        };
      };
    };
  in
    mkIf config.ghaf.shm.enable (foldl' lib.attrsets.recursiveUpdate {} (map makeAssignment config.ghaf.shm.vms_enabled)); #(makeAssignment "chromium-vm");

  config.ghaf.hardware.definition.gpu.kernelConfig.kernelParams =
    builtins.trace (">>>>> " + (builtins.toString config.ghaf.shm.instancesCount))
    optionals
    config.ghaf.shm.enable
    [
      "kvm_ivshmem.flataddr=${config.ghaf.shm.flataddr}"
    ];

  # microvm.vms.chromium-vm.config.config.microvm.qemu.extraArgs = [ "????!!2" ];
  # builtins.toString (config.ghaf.shm.vms_enabled)
}

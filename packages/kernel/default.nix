# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: CC-BY-SA-4.0
{
  config,
  pkgs,
  lib,
}: {
  kernelPatches ? [],
  enable_kernel_guest ? false,
  enable_kernel_guest_graphics ? false,
}: let
  kernel_package = pkgs.linux_latest;
  version = "${kernel_package.version}-ghaf-hardened";
  modDirVersion = version;
  base_kernel =
    pkgs.linuxManualConfig rec
    {
      inherit (kernel_package) src;
      inherit version modDirVersion kernelPatches;
      allowImportFromDerivation = true;
      /*
      baseline "make tinyconfig"
      - enabled for 64-bit, TTY, printk and initrd
      - fixed following NixOS required assertions via "make menuconfig" + search
      (following is documented here to highlight NixOS required (asserted) kernel features)
      ❯ nix build .#packages.x86_64-linux.lenovo-x1-carbon-gen11-debug --accept-flake-config
      error:
         Failed assertions:
         - CONFIG_DEVTMPFS is not enabled!
         - CONFIG_CGROUPS is not enabled!
         - CONFIG_INOTIFY_USER is not enabled!
         - CONFIG_SIGNALFD is not enabled!
         - CONFIG_TIMERFD is not enabled!
         - CONFIG_EPOLL is not enabled!
         - CONFIG_NET is not enabled!
         - CONFIG_SYSFS is not enabled!
         - CONFIG_PROC_FS is not enabled!
         - CONFIG_FHANDLE is not enabled!
         - CONFIG_CRYPTO_USER_API_HASH is not enabled!
         - CONFIG_CRYPTO_HMAC is not enabled!
         - CONFIG_CRYPTO_SHA256 is not enabled!
         - CONFIG_DMIID is not enabled!
         - CONFIG_AUTOFS4_FS is not enabled!
         - CONFIG_TMPFS_POSIX_ACL is not enabled!
         - CONFIG_TMPFS_XATTR is not enabled!
         - CONFIG_SECCOMP is not enabled!
         - CONFIG_TMPFS is not yes!
         - CONFIG_BLK_DEV_INITRD is not yes!
         - CONFIG_EFI_STUB is not yes!
         - CONFIG_MODULES is not yes!
         - CONFIG_BINFMT_ELF is not yes!
         - CONFIG_UNIX is not enabled!
         - CONFIG_INOTIFY_USER is not yes!
         - CONFIG_NET is not yes!
      ...
      additional NixOS dependencies (fixed):
      > modprobe: FATAL: Module uas not found ...
      > modprobe: FATAL: Module nvme not found ...
      ... < many packages enabled as M,
            others allowMissing = true with overlay
            - see implementation below under cfg.enable
      - also see https://github.com/NixOS/nixpkgs/issues/109280
        for the context >
      */
      configfile = ../../modules/host/kernel/ghaf_host_hardened_baseline;
    };

  host_source = ../../modules/host/kernel/configs;
  guest_source = ../../modules/guest/kernel/configs;
  enable_kernel_virtualization = config.ghaf.host.kernel.virtualization_hardening.enable;
  enable_kernel_networking = config.ghaf.host.kernel.networking_hardening.enable;
  enable_kernel_usb = config.ghaf.host.kernel.usb_hardening.enable;
  enable_kernel_inputdevices = config.ghaf.host.kernel.inputdevices_hardening.enable;

  has_virtualization =
    if enable_kernel_virtualization
    then ["${host_source}/virtualization.config"]
    else [];

  has_networking =
    if enable_kernel_networking
    then ["${host_source}/networking.config"]
    else [];

  has_usb =
    if enable_kernel_usb
    then ["${host_source}/usb.config"]
    else [];

  has_inputdevices =
    if enable_kernel_inputdevices
    then ["${host_source}/user-input-devices.config"]
    else [];

  has_guest =
    if enable_kernel_guest
    then ["${guest_source}/guest.config"]
    else [];

  has_guest_graphics =
    if enable_kernel_guest_graphics
    then ["${guest_source}/display-gpu.config"]
    else [];

  kernel_features = [has_virtualization has_networking has_usb has_inputdevices has_guest has_guest_graphics];

  kernel =
    if lib.length kernel_features > 0
    then
      base_kernel.overrideAttrs (_old: {
        inherit kernel_features;
        postConfigure = ''
          ./scripts/kconfig/merge_config.sh  -O $buildRoot $buildRoot/.config  $kernel_features;
        '';
      })
    else base_kernel;
in
  kernel

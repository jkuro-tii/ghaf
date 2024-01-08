# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  baseKernel =
    if hyp_cfg.enable
    then
      pkgs.linux_6_1.override {
        argsOverride = rec {
          src = pkgs.fetchurl {
            url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
            hash = "sha256-qH4kHsFdU0UsTv4hlxOjdp2IzENrW5jPbvsmLEr/FcA=";
          };
          version = "6.1.55";
          modDirVersion = "6.1.55";
        };
      }
    else pkgs.linux_latest;

  buildKernel = import ./buildKernel.nix {inherit config pkgs lib;};
  version = "${baseKernel.version}-ghaf-hardened";

  # Create kernel derivation and override nix phases
  hardened_kernel = buildKernel {
    inherit (baseKernel) src modDirVersion version;
  };

  pkvm_patch = lib.mkIf config.ghaf.hardware.x86_64.common.enable [
    {
      name = "pkvm-patch";
      patch = ../virtualization/pkvm/0001-pkvm-enable-pkvm-on-intel-x86-6.1-lts.patch;
      structuredExtraConfig = with lib.kernel; {
        KVM_INTEL = yes;
        KSM = no;
        PKVM_INTEL = yes;
        PKVM_INTEL_DEBUG = yes;
        PKVM_GUEST = yes;
        EARLY_PRINTK_USB_XDBC = yes;
        RETPOLINE = yes;
      };
    }
  ];

  enable_kernel_baseline = config.ghaf.host.kernel_baseline_hardening.enable;
  hyp_cfg = config.ghaf.host.hypervisor_hardening;
in
  with lib; {
    options.ghaf.host.kernel_baseline_hardening = {
      enable = mkEnableOption "Host kernel hardening";
    };

    options.ghaf.host.hypervisor_hardening = {
      enable = mkEnableOption "Hypervisor hardening";
    };

    options.ghaf.host.kernel_virtualization_hardening.enable = lib.mkOption {
      description = "Virtualization hardening for Ghaf Host";
      type = lib.types.bool;
      default = false;
    };

    options.ghaf.host.kernel_networking_hardening.enable = lib.mkOption {
      description = "Networking hardening for Ghaf Host";
      type = lib.types.bool;
      default = false;
    };

    options.ghaf.host.kernel_usb_hardening.enable = lib.mkOption {
      description = "USB hardening for Ghaf Host";
      type = lib.types.bool;
      default = false;
    };

    options.ghaf.host.kernel_inputdevices_hardening.enable = lib.mkOption {
      description = "User input devices hardening for Ghaf Host";
      type = lib.types.bool;
      default = false;
    };

    config = mkIf enable_kernel_baseline {
      boot.kernelPackages = pkgs.linuxPackagesFor hardened_kernel;
      boot.kernelPatches = mkIf (hyp_cfg.enable && "${baseKernel.version}" == "6.1.55") pkvm_patch;
      # https://github.com/NixOS/nixpkgs/issues/109280#issuecomment-973636212
      nixpkgs.overlays = [
        (_final: prev: {
          makeModulesClosure = x:
            prev.makeModulesClosure (x // {allowMissing = true;});
        })
      ];
    };
  }

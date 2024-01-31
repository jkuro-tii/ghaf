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

  # Importing kernel builder function from packages and checking hardening options
  buildKernel = import ../../../packages/kernel {inherit config pkgs lib;};
  host_hardened_kernel = buildKernel {};

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

  enable_kernel_baseline = config.ghaf.host.kernel.baseline_hardening.enable;
  hyp_cfg = config.ghaf.host.hypervisor_hardening;
in
  with lib; {
    options.ghaf.host.kernel.baseline_hardening.enable = mkOption {
      description = "Host kernel hardening";
      type = types.bool;
      default = false;
    };

    options.ghaf.host.hypervisor_hardening.enable = mkOption {
      description = "Hypervisor hardening";
      type = types.bool;
      default = false;
    };

    options.ghaf.host.kernel.virtualization_hardening.enable = lib.mkOption {
      description = "Virtualization hardening for Ghaf Host";
      type = types.bool;
      default = false;
    };

    options.ghaf.host.kernel.networking_hardening.enable = mkOption {
      description = "Networking hardening for Ghaf Host";
      type = types.bool;
      default = false;
    };

    options.ghaf.host.kernel.usb_hardening.enable = mkOption {
      description = "USB hardening for Ghaf Host";
      type = types.bool;
      default = false;
    };

    options.ghaf.host.kernel.inputdevices_hardening.enable = mkOption {
      description = "User input devices hardening for Ghaf Host";
      type = types.bool;
      default = false;
    };

    config = mkIf enable_kernel_baseline {
      boot.kernelPackages = pkgs.linuxPackagesFor host_hardened_kernel;
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

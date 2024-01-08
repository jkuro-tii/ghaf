# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  configHost = config;
  vmName = "hardened-vm";
  macAddress = "02:00:00:04:04:04";
  kernelvmBaseConfiguration = {
    imports = [
      (import ./common/vm-networking.nix {inherit vmName macAddress;})
      ({lib, ...}: {
        ghaf = {
          users.accounts.enable = lib.mkDefault configHost.ghaf.users.accounts.enable;
          development = {
            ssh.daemon.enable = lib.mkDefault configHost.ghaf.development.ssh.daemon.enable;
            debug.tools.enable = lib.mkDefault configHost.ghaf.development.debug.tools.enable;
          };
        };
        microvm.hypervisor = "qemu";
        system.stateVersion = lib.trivial.release;

        nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
        nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

        microvm = {
          optimize.enable = false;
          shares = [
            {
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
          ];
          writableStoreOverlay = lib.mkIf config.ghaf.development.debug.tools.enable "/nix/.rw-store";
        };

        imports = import ../../module-list.nix;

        systemd.network.networks."10-ethint0".addresses = [
          {
            addressConfig.Address = "192.168.101.4/24";
          }
        ];
      })
    ];
  };
  cfg = config.ghaf.guest.hardening;
  baseKernel = pkgs.linux_latest;
  buildKernel = import ../../host/kernel/buildKernel.nix {inherit config pkgs lib;};
  hardened_kernel = buildKernel {
    inherit (baseKernel) src modDirVersion version;
  };
in {
  options.ghaf.guest.hardening = {
    enable = lib.mkEnableOption "Hardened VM";
  };

  config = lib.mkIf cfg.enable {
    microvm.vms."${vmName}" = {
      autostart = true;
      config =
        kernelvmBaseConfiguration
        // {
          boot.kernelPackages = pkgs.linuxPackagesFor hardened_kernel;
          inherit (kernelvmBaseConfiguration) imports;
        };
      specialArgs = {inherit lib;};
    };
  };
}

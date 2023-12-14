# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  configHost = config;
  cfg = config.ghaf.virtualization.microvm.appvm;
  makeVm = {
    vm,
    index,
  }: let
    vmName = "${vm.name}-vm";
    appvmConfiguration = {
      imports = [
        (import ./common/vm-networking.nix {
          inherit vmName;
          macAddress = vm.macAddress;
        })
        ({
          lib,
          config,
          pkgs,
          ...
        }: {
          ghaf = {
            users.accounts.enable = lib.mkDefault configHost.ghaf.users.accounts.enable;

            # Don't enable Wayland compositor inside every AppVM
            profiles.graphics.enable = false;

            development = {
              ssh.daemon.enable = lib.mkDefault configHost.ghaf.development.ssh.daemon.enable;
              debug.tools.enable = lib.mkDefault configHost.ghaf.development.debug.tools.enable;
            };
          };

          system.stateVersion = lib.trivial.release;

          nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
          nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

          time.timeZone = "Asia/Dubai";

          environment.systemPackages = [
            pkgs.waypipe
          ];

          microvm = {
            optimize.enable = false;
            mem = vm.ramMb;
            vcpu = vm.cores;
            hypervisor = "qemu";
            shares = [
              {
                tag = "ro-store";
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
              }
            ];
            writableStoreOverlay = lib.mkIf config.ghaf.development.debug.tools.enable "/nix/.rw-store";

            qemu.extraArgs = [
              "-M"
              "q35,accel=kvm:tcg,mem-merge=on,sata=off"
            ];
          };

          imports = import ../../module-list.nix;

          services.udev.extraRules = ''
            SUBSYSTEM=="misc",KERNEL=="ivshmem",GROUP="kvm",MODE="0666"
          '';
        })
      ];
    };
  in {
    autostart = true;
    config = appvmConfiguration // {imports = appvmConfiguration.imports ++ cfg.extraModules ++ vm.extraModules ++ [{environment.systemPackages = vm.packages;}];};
    specialArgs = {inherit lib;};
  };
in {
  options.ghaf.virtualization.microvm.appvm = with lib; {
    enable = lib.mkEnableOption "appvm";
    vms = with types;
      mkOption {
        description = ''
          List of AppVMs to be created
        '';
        type = lib.types.listOf (submodule {
          options = {
            name = mkOption {
              description = ''
                Name of the AppVM
              '';
              type = str;
            };
            packages = mkOption {
              description = ''
                Packages that are included into the AppVM
              '';
              type = types.listOf package;
              default = [];
            };
            macAddress = mkOption {
              description = ''
                AppVM's network interface MAC address
              '';
              type = str;
            };
            ramMb = mkOption {
              description = ''
                Amount of RAM for this AppVM
              '';
              type = int;
            };
            cores = mkOption {
              description = ''
                Amount of processor cores for this AppVM
              '';
              type = int;
            };
            extraModules = mkOption {
              description = ''
                List of additional modules to be imported and evaluated as part of
                appvm's NixOS configuration.
              '';
              default = [];
            };
          };
        });
        default = [];
      };

    extraModules = mkOption {
      description = ''
        List of additional modules to be imported and evaluated as part of
        appvm's NixOS configuration.
      '';
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    microvm.vms = (
      let
        vms = lib.imap0 (index: vm: {"${vm.name}-vm" = makeVm {inherit index vm;};}) cfg.vms;
      in
        lib.foldr lib.recursiveUpdate {} vms
    );
  };
}

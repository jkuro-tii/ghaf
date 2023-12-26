# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
{
  self,
  lib,
  microvm,
  lanzaboote,
  name,
  system,
  ...
}: let
  lenovo-x1 = generation: variant: extraModules: let
    hostConfiguration = lib.nixosSystem {
      inherit system;
      modules =
        [
          lanzaboote.nixosModules.lanzaboote
          microvm.nixosModules.host
          self.nixosModules.common
          self.nixosModules.desktop
          self.nixosModules.host
          self.nixosModules.lanzaboote
          self.nixosModules.microvm
          self.nixosModules.reference-appvms
          self.nixosModules.reference-programs
          self.nixosModules.reference-services

          ({
            pkgs,
            config,
            ...
          }: let
            powerControl = pkgs.callPackage ../../packages/powercontrol {};
          in {
            security.polkit = {
              enable = true;
              extraConfig = powerControl.polkitExtraConfig;
            };
            time.timeZone = "Asia/Dubai";

            ghaf = {
              # variant type, turn on debug or release
              profiles = {
                debug.enable = variant == "debug";
                release.enable = variant == "release";
              };

              # Hardware definitions
              hardware = {
                inherit generation;
                x86_64.common.enable = true;
                tpm2.enable = true;
                usb.internal.enable = true;
                usb.external.enable = true;
              };

              reference.appvms = {
                enable = true;
                chromium-vm = true;
                gala-vm = true;
                zathura-vm = true;
                element-vm = true;
                appflowy-vm = true;
              };

              reference.services = {
                enable = true;
                dendrite = true;
              };

              reference.programs = {
                windows-launcher = {
                  enable = true;
                  spice = true;
                };
              };

              # Virtualization options
              virtualization = {
                microvm-host = {
                  enable = true;
                  networkSupport = true;
                };

                microvm = {
                  netvm = {
                    enable = true;
                    wifi = true;
                    extraModules = [self.nixosModules.reference-services];
                  };

                  adminvm = {
                    enable = true;
                  };

                  idsvm = {
                    enable = false;
                    mitmproxy.enable = false;
                  };

                  guivm = {
                    enable = true;
                    extraModules = [self.nixosModules.reference-programs];
                  };

                  audiovm = {
                    enable = true;
                    audio = true;
                  };

                  appvm = {
                    enable = true;
                    vms = config.ghaf.reference.appvms.enabled-app-vms;
                  };
                };
              };

              host = {
                networking.enable = true;
                powercontrol.enable = true;
              };

              # UI applications
              profiles = {
                applications.enable = false;
                applications.ivShMemServer.enable = false;
              };
              windows-launcher = {
                enable = true;
                spice = true;
              };
            };
          })

          #TODO: how to handle the majority of laptops that need a little
          # something extra?
          # SEE: https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
          # nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen

          ({config, ...}: {
            boot.kernelParams = let
              filterDevices = builtins.filter (d: d.vendorId != null && d.productId != null);
              mapPciIdsToString = builtins.map (d: "${d.vendorId}:${d.productId}");
              vfioPciIds = mapPciIdsToString (filterDevices (
                config.ghaf.hardware.definition.network.pciDevices
                ++ config.ghaf.hardware.definition.gpu.pciDevices
              ));
              hugepagesz = 2;
              hugepages = config.ghaf.profiles.applications.ivShMemServer.memSize / hugepagesz;
              hugePagesArg =
                if config.ghaf.profiles.applications.ivShMemServer.enable
                then [
                  "hugepagesz=${toString hugepagesz}M"
                  "hugepages=${toString hugepages}"
                ]
                else [];
            in [
              "intel_iommu=on,sm_on"
              "iommu=pt"
              # Prevent i915 module from being accidentally used by host
              "module_blacklist=i915"

              "vfio-pci.ids=${builtins.concatStringsSep "," vfioPciIds}"
            ]
            ++ hugePagesArg;;

            boot.initrd.availableKernelModules = ["nvme"];
          })
        ]
        ++ extraModules;
    };
  in {
    inherit hostConfiguration;
    name = "${name}-${generation}-${variant}";
    package = hostConfiguration.config.system.build.diskoImages;
  };
in [
  (lenovo-x1 "gen10" "debug" [self.nixosModules.disko-lenovo-x1-basic-v1 self.nixosModules.hw-lenovo-x1])
  (lenovo-x1 "gen11" "debug" [self.nixosModules.disko-lenovo-x1-basic-v1 self.nixosModules.hw-lenovo-x1])
  (lenovo-x1 "gen10" "release" [self.nixosModules.disko-lenovo-x1-basic-v1 self.nixosModules.hw-lenovo-x1])
  (lenovo-x1 "gen11" "release" [self.nixosModules.disko-lenovo-x1-basic-v1 self.nixosModules.hw-lenovo-x1])
]

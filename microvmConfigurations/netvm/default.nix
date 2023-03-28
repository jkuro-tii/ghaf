# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  self,
  nixpkgs,
  microvm,
  system,
}:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    # TODO: Enable only for development builds
    ../../modules/development/authentication.nix
    ../../modules/development/ssh.nix
    ../../modules/development/packages.nix

    microvm.nixosModules.microvm

    ({pkgs, ...}: {
      config = {
        nixpkgs.overlays = [
          self.netvm_overlay
        ];

        /* Kernel change must be done here and in the
           above netvm_overlay in the overlay_config.nix file in this dir. 
           E.g. for specific kernel version use: pkgs.linuxPackages_6_1.extend 
         */
        boot.kernelPackages =
          pkgs.linuxPackages_latest.extend (_: _: {
          kernel = pkgs.netvm-kernel;
        });

        networking.hostName = "netvm";
        # TODO: Maybe inherit state version
        system.stateVersion = "22.11";

        # For WLAN firmwares
        hardware.enableRedistributableFirmware = true;

        microvm.hypervisor = "crosvm";

        networking.enableIPv6 = false;
        networking.interfaces.eth0.useDHCP = true;
        networking.firewall.allowedTCPPorts = [22];

        # TODO: Idea. Maybe use udev rules for connecting
        # USB-devices to crosvm

        # TODO: Move these to target-specific modules
        # microvm.devices = [
        #   {
        #     bus = "usb";
        #     path = "vendorid=0x050d,productid=0x2103";
        #   }
        # ];
        # microvm.devices = [
        #   {
        #     bus = "pci";
        #     path = "0001:00:00.0";
        #   }
        #   {
        #     bus = "pci";
        #     path = "0001:01:00.0";
        #   }
        # ];

        # TODO: Move to user specified module - depending on the use x86_64
        #       laptop pci path
        # x86_64 Laptop
        # microvm.devices = [
        #   {
        #     bus = "pci";
        #     path = "0000:03:00.0";
        #   }
        #   {
        #     bus = "pci";
        #     path = "0000:05:00.0";
        #   }
        # ];
        microvm.interfaces = [
          {
            type = "tap";
            id = "vm-netvm";
            mac = "02:00:00:01:01:01";
          }
        ];

        networking.wireless = {
          enable = true;

          # networks."SSID_OF_NETWORK".psk = "WPA_PASSWORD";
        };
      };
    })
  ];
}

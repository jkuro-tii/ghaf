# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  nixpkgs,
  microvm, /* still clean path */
  system,
}:
let mm =  /*builtins.trace ("netvm/default.nix 8 microvm = " + microvm)*/
nixpkgs.lib.attrsets.recursiveUpdate microvm {packages.x86_64-linux.microvm-kernel = "asasa";};
in
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = 
  let  
  pkgs = #builtins.trace ("mm =" + mm) builtins.trace (/*"netvm/default.nix 15 nixpkgs: " + */((builtins.attrNames(import nixpkgs {inherit system;}) )) )
    import nixpkgs { inherit system; overlays = 
  builtins.trace "netvm/default.nix 15: overlays set" [mvm];
       };
  mvm = final: prev: { /*final.*//*microvm.overlay*/ /*self.*/microvm-kernel = builtins.trace "My overlay called microvm-kernel=!" "overlay15";};
  # microvm = mm;
  nix_overlays = "";
  ttmp = microvm.nixosModules.microvm ({pkgs, ...}: {  });
  # tmp = {pkgs, ...}: ;
  in
  [
    # { nixpkgs = builtins.trace (microvm.nixosModules.microvm ({pkgs, ...}: {  })) { inherit pkgs; }; }
    # TODO: Enable only for development builds
    ../../modules/development/authentication.nix
    ../../modules/development/ssh.nix
    ../../modules/development/packages.nix

    # ttmp
    microvm.nixosModules.microvm ({pkgs, config, ...}: {

      # config.nixpkgs.packageOverrides = builtins.trace "----------------" (pkgs: {
      #   microvm-kernel = pkgs.microvm-kernel.override {
      #     extraConfig = ''
      #     ...
      #   '';
      #   };});
      config = {
        nixpkgs.overlays = builtins.trace (nix_overlays + "microvmConfigurations/netvm default.nix:41 overlays set!") [
          mvm
        ];
        # nixpkgs.config.packageOverrides = builtins.trace ("packageOverrides set>>>>" ) (pkgs: rec {
        #    microvm-kernel =  builtins.trace "--------->>>>>>>>>>>>" pkgs.microvm-kernel.override {
        #     extraConfig = ''
        #     ''
        #     ;
        #    };
        #   });
        
        
        
      };
      
    })
    # { builtins.trace (microvm.nixosModules.microvm ({pkgs, ...}: {  })) 1212}
      # networking.hostName = 
      # builtins.trace ("### microvm.nixosModules.microvm: pkgs.microvm-kernel.version = " + (builtins.toString pkgs.microvm-kernel.version))
      # "netvm";
      # # TODO: Maybe inherit state version
      # system.stateVersion = "22.11";

      # # For WLAN firmwares
      # hardware.enableRedistributableFirmware = true;

      # microvm.hypervisor = "crosvm";

      # networking.enableIPv6 = false;
      # networking.interfaces.eth0.useDHCP = true;
      # networking.firewall.allowedTCPPorts = [22];

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
      # microvm.interfaces = [
      #   {
      #     type = "tap";
      #     id = "vm-netvm";
      #     mac = "02:00:00:01:01:01";
      #   }
      # ];

      # networking.wireless = {
      #   enable = true;

      #   # networks."SSID_OF_NETWORK".psk = "WPA_PASSWORD";
      # };
    # })
  ];
}

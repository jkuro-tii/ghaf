# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.ghaf.virtualization.memshare;
in
with lib; {
  # config.ghaf.virtualization.memshare.kernel =  pkgs.linuxPackages_latest.kernel;
  # config.microvm.vms.netvm.config.config.microvm.hypervisor <- reference to the VM hypervisor
  options.ghaf.virtualization.memshare = {
      enable = mkOption {
      description = "Memory sharing";
      type = types.bool;
      default = false;
    };
  
    kernel = mkOption {
        type = types.package;
        default = pkgs.linuxPackages_latest.kernel;
        description = ''
          Linux kernel built with the memory sharing module
        '';
    };
  # config = mkIf cfg.enable {
    # virtualisation.docker.enable = "true";
    # microvm.kernel = pkgs.linuxPackages_latest;
    # microvm.vms.netvm.config.microvm.kernel = pkgs.linuxPackages_latest;
  # };
  };
}


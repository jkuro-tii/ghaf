# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ config, lib, ... }:
let
  cfg = let tmp = config.ghaf.givc.adminvm; in builtins.trace tmp tmp;
  inherit (lib) mkEnableOption mkIf;
  inherit (import ./definitions.nix { inherit config lib; })
    transportSubmodule
    tlsSubmodule
    ;
in
{
  options.ghaf.givc.adminvm = {
    enable = mkEnableOption "Enable adminvm givc module.";
    KKKKKK = mkEnableOption "Enable adminvm givc module.";
  };
  options.ghaf.givc.admin = {
    addresses = lib.mkOption {
      description = ''
        List of addresses for the admin service to listen on. Requires a list of 'transportSubmodule'.
      '';
      type = lib.types.listOf transportSubmodule;
    };
  };
  # givc.admin.addresses = config.ghaf.givc.adminConfig.addresses;
  config = mkIf (cfg.enable && config.ghaf.givc.enable) {
    # Configure admin service
    givc.admin = {
      enable = true;
      inherit (config.ghaf.givc) debug;
      # inherit (config.ghaf.givc.adminConfig) name;
      # config.microvm.vms.admin-vm.config. config.givc.admin.name
      #       `microvm.vms.admin-vm.config. givc.admin.addresses' does not exist.
      #
      # config.ghaf.givc.adminConfig.addresses
      # config.givc.admin.addresses <- needed !!!!!!!!!!!!!!!!!!!!
      # config.ghaf.givc.adminvm <- local option
      name = "??????";
      # inherit (config.ghaf.givc.adminConfig) addresses;
      inherit (config.ghaf.givc.adminConfig) port;
      inherit (config.ghaf.givc.adminConfig) protocol;
      services = [
        "givc-ghaf-host-debug.service"
        "givc-net-vm.service"
        "givc-gui-vm.service"
        "givc-audio-vm.service"
      ];
      tls.enable = config.ghaf.givc.enableTls;
    };
  };
}

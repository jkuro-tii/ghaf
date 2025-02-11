# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ config, lib, ... }:
let
  cfg = let tmp = config.ghaf.givc.adminvm; in builtins.trace tmp tmp;
  inherit (lib) mkEnableOption mkIf;
  inherit (config.ghaf.givc.adminConfig) name;
  systemHosts = lib.lists.subtractLists (config.ghaf.common.appHosts ++ [ name ]) (
    builtins.attrNames config.ghaf.networking.hosts
  );
in
{
  options.ghaf.givc.adminvm = {
    enable = mkEnableOption "Enable adminvm givc module.";
  };
  # options.ghaf.givc.admin = {
  #   addresses = lib.mkOption {
  #     description = ''
  #       List of addresses for the admin service to listen on. Requires a list of 'transportSubmodule'.
  #     '';
  #     type = lib.types.listOf transportSubmodule;
  #   };
  # };
  # givc.admin.addresses = config.ghaf.givc.adminConfig.addresses;
  config = mkIf (cfg.enable && config.ghaf.givc.enable) {
    # Configure admin service
    givc.admin = {
      enable = true;
      # inherit (config.ghaf.givc) debug;
      debug = true;
      inherit name;
      inherit (config.ghaf.givc.adminConfig) addresses;
      services = map (host: "givc-${host}.service") systemHosts;
      # addresses = [{
      #   name = "admin-vm";
      #   # addr = addrs.adminvm;
      #   inherit (config.ghaf.givc.adminConfig) addr;
      #   port = "9001";
      #   protocol = "tcp";
      #   }
      # ]
      tls.enable = config.ghaf.givc.enableTls;
    };
  };
}

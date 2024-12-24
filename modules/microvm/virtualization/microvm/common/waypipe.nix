# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  vmIndex,
  vm,
  configHost,
  cid,
}:
{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.ghaf.waypipe;
  waypipePort = configHost.ghaf.virtualization.microvm.appvm.waypipeBasePort + vmIndex;
  waypipeBorder = lib.optionalString (
    cfg.waypipeBorder && vm.borderColor != null
  ) "--border \"${vm.borderColor}\"";
  displayOpt =
    let
      cfgShm = configHost.ghaf.shm.service;

      t =
        if cfgShm.gui.enabled then
          "-s " + cfgShm.gui.serverSocketPath "gui" "-${vm.name}-vm"
        else
          "--vsock -s ${toString waypipePort}";
    in
    builtins.trace "displayOpt: ${t} vm=${vm.name}" t;
  runWaypipe =
    let
      script = ''
        #!${pkgs.runtimeShell} -e
        ${pkgs.waypipe}/bin/waypipe ${displayOpt} server "$@"
      '';
    in
    pkgs.writeScriptBin "run-waypipe" script;
  vsockproxy = pkgs.callPackage ../../../../../packages/vsockproxy { };
  guivmCID = configHost.ghaf.virtualization.microvm.guivm.vsockCID;
in
{
  options.ghaf.waypipe = with lib; {
    enable = mkEnableOption "Waypipe support";

    proxyService = lib.mkOption {
      type = lib.types.attrs;
      description = "vsockproxy service configuration for the AppVM";
      readOnly = true;
      visible = false;
    };

    waypipeService = lib.mkOption {
      type = lib.types.attrs;
      description = "Waypipe service configuration for the AppVM";
      readOnly = true;
      visible = false;
    };

    waypipeBorder = lib.mkEnableOption "Waypipe window border";
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = [
      pkgs.waypipe
      runWaypipe
    ];

    ghaf.waypipe = {
      # Waypipe service runs in the GUIVM and listens for incoming connections from AppVMs
      waypipeService = {
        enable = true;
        description = "Waypipe for ${vm.name}";
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "1";
          ExecStart = "${pkgs.waypipe}/bin/waypipe --secctx \"${vm.name}\" ${waypipeBorder} ${displayOpt} client";
        };
        startLimitIntervalSec = 0;
        partOf = [ "ghaf-session.target" ];
        wantedBy = [ "ghaf-session.target" ];
      };

      # vsockproxy is used on host to forward data between AppVMs and GUIVM
      proxyService = {
        enable = true;
        description = "vsockproxy for ${vm.name}";
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "1";
          ExecStart = "${vsockproxy}/bin/vsockproxy ${toString waypipePort} ${toString guivmCID} ${toString waypipePort} ${toString cid}";
        };
        startLimitIntervalSec = 0;
        wantedBy = [ "multi-user.target" ];
      };
    };
  };
}

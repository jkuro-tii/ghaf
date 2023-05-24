# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  pkgs,
  modulesPath,
  ...
}: {
  imports = builtins.trace (">>>Docker module not included!: modulesPath="+modulesPath) [
  #   (modulesPath + "/virtualisation/docker.nix")
#    (modulesPath + "/virtualisation/docker-image.nix")
  ];

  # virtualisation.docker.enable = true;
  # virtualisation.docker.rootless = {
  #   enable = true;
  #   setSocketVariable = true;
  # };
#  networking.useHostResolvConf = false;
}

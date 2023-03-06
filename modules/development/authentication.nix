# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs, ...}:
# account for the development time login with sudo rights
let
  user = #builtins.trace (("xxx: " + builtins.toString (builtins.attrNames pkgs.zzuf)/*microsoft-gsl)/*.microvm-kernel*/))
  # builtins.trace pkgs
  "ghaf";
  password = builtins.trace "???????????????????????????"
  "gxphaf";
in {
  users = {
    mutableUsers = true;
    users."${user}" = {
      isNormalUser = true;
      password = password;
      extraGroups = ["wheel"];
    };
  };
}

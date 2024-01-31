# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{lib, ...}:
with lib; {
  options.ghaf.guest.hardening.enable = mkOption {
    description = "Guest hardening";
    type = lib.types.bool;
    default = false;
  };
  options.ghaf.guest.graphics_hardening.enable = mkOption {
    description = "Guest Graphics hardening";
    type = lib.types.bool;
    default = false;
  };
  config = {
    # Guest kernel hardening
    ghaf.guest.graphics_hardening.enable = false;
  };
}

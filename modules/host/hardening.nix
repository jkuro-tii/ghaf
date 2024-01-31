# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{lib, ...}: {
  imports = [
    ./kernel
    # other host hardening modules - to be defined later
  ];

  options.ghaf.host.hardening.enable = lib.mkOption {
    description = "Host hardening";
    type = lib.types.bool;
    default = false;
  };

  config = {
    # host kernel hardening
    ghaf.host.kernel.baseline_hardening.enable = false;
    ghaf.host.kernel.virtualization_hardening.enable = false;
    ghaf.host.kernel.networking_hardening.enable = false;
    ghaf.host.kernel.usb_hardening.enable = false;
    ghaf.host.kernel.inputdevices_hardening.enable = false;
    # host kernel hypervisor (KVM) hardening
    ghaf.host.hypervisor_hardening.enable = false;
    # other host hardening options - user space, etc. - to be defined later
  };
}

# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # For lspci:
    pciutils

    # For lsusb:
    usbutils

    # For cloud-hypervisor:
    cloud-hypervisor

    # TODO: test. It works!
    #(import ./my-hello.nix)
    (
      stdenv.mkDerivation rec {
        name = "hello-2.8";
        src = fetchurl {
          url = "mirror://gnu/hello/${name}.tar.gz";
          sha256 = "0wqd8sjmxfskrflaxywc7gqw7sfawrfvdxd9skxawzfgyy0pzdz6";
        };
      }
    )
  ];
}

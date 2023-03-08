# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{self}: {
  hydraJobs = {
    intel-nuc-debug.x86_64-linux = self.packages.x86_64-linux.intel-nuc-debug;
    nvidia-jetson-orin-debug.aarch64-linux = self.packages.aarch64-linux.nvidia-jetson-orin-debug;
  };
  overlays.default = let tmp = builtins.trace "HYDRA/default " 
    { xx = builtins.trace "HYDRA/overlay1" "z"; }; 
  in tmp;
  # overlays.default =  {};#{ xx = builtins.trace "HYDRA/overlay1" "z"; }; 
  overlays.microvm = [ (final: prev: { xx = builtins.trace "HYDRA/overlay1" "z"; }) ]; 
  overlays.microvm-kernel = [ (final: prev: { xx = builtins.trace "HYDRA/overlay1" "z"; }) ]; 
  # overlays.default = final: prev: { builtins.trace "HYDRA/overlay1" "z" };
  # overlays.microvm = final: prev: { builtins.trace "HYDRA/overlay1" "z" };
  # overlays.microvm-kernel = final: prev: { builtins.trace "HYDRA/overlay1" "z" };
}

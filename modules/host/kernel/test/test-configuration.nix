{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../default.nix
  ];

  config.ghaf.host.kernel_baseline_hardening.enable = true;
  config.ghaf.host.kernel_virtualization_hardening.enable = true;
  config.ghaf.host.kernel_networking_hardening.enable = true;

  # required to module test a module via top level configuration
  config.boot.loader.systemd-boot.enable = true;
  config.fileSystems."/" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
    fsType = "ext4";
  };
  config.system.stateVersion = "23.11";
}

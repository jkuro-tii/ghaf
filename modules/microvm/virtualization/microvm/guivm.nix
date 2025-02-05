# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  vmName = "gui-vm";
  inherit (import ../../../../lib/launcher.nix { inherit pkgs lib; }) rmDesktopEntries;
  guivmBaseConfiguration = {
    imports = [
      inputs.impermanence.nixosModules.impermanence
      inputs.self.nixosModules.givc-guivm
      (import ./common/vm-networking.nix {
        inherit
          config
          lib
          vmName
          ;
      })

      ./common/storagevm.nix

      # To push logs to central location
      ../../../common/logging/client.nix
      (
        { lib, pkgs, ... }:
        let
          # A list of applications from all AppVMs
          virtualApps = lib.lists.concatMap (
            vm: map (app: app // { vmName = "${vm.name}-vm"; }) vm.applications
          ) config.ghaf.virtualization.microvm.appvm.vms;

          # Launchers for all virtualized applications that run in AppVMs
          virtualLaunchers = map (app: rec {
            inherit (app) name;
            inherit (app) description;
            #inherit (app) givcName;
            vm = app.vmName;
            path = "${pkgs.givc-cli}/bin/givc-cli ${config.ghaf.givc.cliArgs} start --vm ${vm} ${app.givcName}";
            inherit (app) icon;
          }) virtualApps;
          # Launchers for all desktop, non-virtualized applications that run in the GUIVM
          guivmLaunchers = map (app: {
            inherit (app) name;
            inherit (app) description;
            path = app.command;
            inherit (app) icon;
          }) cfg.applications;
        in
        {
          imports = [
            ../../../common
            ../../../desktop
            ../../../reference/services
          ];

          ghaf = {
            # Profiles
            profiles = {
              debug.enable = lib.mkDefault config.ghaf.profiles.debug.enable;
              applications.enable = false;
              graphics.enable = true;
            };
            users.loginUser.enable = true;
            development = {
              ssh.daemon.enable = lib.mkDefault config.ghaf.development.ssh.daemon.enable;
              debug.tools.enable = lib.mkDefault config.ghaf.development.debug.tools.enable;
              nix-setup.enable = lib.mkDefault config.ghaf.development.nix-setup.enable;
            };

            # System
            type = "system-vm";
            systemd = {
              enable = true;
              withName = "guivm-systemd";
              withAudit = config.ghaf.profiles.debug.enable;
              withHomed = true;
              withLocaled = true;
              withNss = true;
              withResolved = true;
              withTimesyncd = true;
              withDebug = config.ghaf.profiles.debug.enable;
              withHardenedConfigs = true;
            };

            givc.guivm.enable = true;

            # Storage
            storagevm = {
              enable = true;
              name = vmName;
            };

            # Services

            # Create launchers for regular apps running in the GUIVM and virtualized ones if GIVC is enabled
            graphics = {
              launchers = guivmLaunchers ++ lib.optionals config.ghaf.givc.enable virtualLaunchers;
              labwc = {
                autolock.enable = lib.mkDefault config.ghaf.graphics.labwc.autolock.enable;
                autologinUser = lib.mkDefault config.ghaf.graphics.labwc.autologinUser;
                securityContext = map (vm: {
                  identifier = vm.name;
                  color = vm.borderColor;
                }) config.ghaf.virtualization.microvm.appvm.vms;
              };
            };

            logging.client = {
              inherit (config.ghaf.logging.client) enable endpoint;
            };

            services = {
              disks = {
                enable = true;
                fileManager = "${pkgs.pcmanfm}/bin/pcmanfm";
              };
              xdghandlers.enable = true;
            };

            reference.services.ollama = true;
          };

          services = {
            acpid = lib.mkIf config.ghaf.givc.enable {
              enable = true;
              lidEventCommands = ''
                case "$1" in
                  "button/lid LID close")
                    # Lock sessions
                    ${pkgs.systemd}/bin/loginctl lock-sessions

                    # Switch off display, if wayland is running
                    if ${pkgs.procps}/bin/pgrep -fl "wayland" > /dev/null; then
                      wl_running=1
                      WAYLAND_DISPLAY=/run/user/${builtins.toString config.ghaf.users.loginUser.uid}/wayland-0 ${pkgs.wlopm}/bin/wlopm --off '*'
                    else
                      wl_running=0
                    fi

                    # Initiate Suspension
                    ${pkgs.givc-cli}/bin/givc-cli ${config.ghaf.givc.cliArgs} suspend

                    # Enable display
                    if [ "$wl_running" -eq 1 ]; then
                      WAYLAND_DISPLAY=/run/user/${builtins.toString config.ghaf.users.loginUser.uid}/wayland-0 ${pkgs.wlopm}/bin/wlopm --on '*'
                    fi
                    ;;
                  "button/lid LID open")
                    # Command to run when the lid is opened
                    ;;
                esac
              '';
            };

            # Suspend inside Qemu causes segfault
            # See: https://gitlab.com/qemu-project/qemu/-/issues/2321
            logind.lidSwitch = "ignore";

            # We dont enable services.blueman because it adds blueman desktop entry
            dbus.packages = [ pkgs.blueman ];
          };

          systemd = {
            packages = [ pkgs.blueman ];

            user.services.audio-control = {
              enable = true;
              description = "Audio Control application";

              serviceConfig = {
                Type = "simple";
                Restart = "always";
                RestartSec = "5";
                ExecStart = "${pkgs.ghaf-audio-control}/bin/GhafAudioControlStandalone --pulseaudio_server=audio-vm:${toString config.ghaf.services.audio.pulseaudioTcpControlPort} --deamon_mode=true --indicator_icon_name=preferences-sound";
              };

              partOf = [ "ghaf-session.target" ];
              wantedBy = [ "ghaf-session.target" ];
            };

            services."waypipe-ssh-keygen" =
              let
                uid = "${toString config.ghaf.users.loginUser.uid}";
                pubDir = config.ghaf.security.sshKeys.waypipeSshPublicKeyDir;
                keygenScript = pkgs.writeShellScriptBin "waypipe-ssh-keygen" ''
                  set -xeuo pipefail
                  mkdir -p /run/waypipe-ssh
                  echo -en "\n\n\n" | ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /run/waypipe-ssh/id_ed25519 -C ""
                  chown ${uid}:users /run/waypipe-ssh/*
                  cp /run/waypipe-ssh/id_ed25519.pub ${pubDir}/id_ed25519.pub
                  chown -R ${uid}:users ${pubDir}
                '';
              in
              {
                enable = true;
                description = "Generate SSH keys for Waypipe";
                path = [ keygenScript ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  StandardOutput = "journal";
                  StandardError = "journal";
                  ExecStart = "${keygenScript}/bin/waypipe-ssh-keygen";
                };
              };
          };

          environment = {
            systemPackages =
              (rmDesktopEntries [
                pkgs.waypipe
                pkgs.networkmanagerapplet
                pkgs.gnome-calculator
                pkgs.sticky-notes
              ])
              ++ [
                pkgs.bt-launcher
                pkgs.pamixer
                pkgs.eww
                pkgs.wlr-randr
              ]
              ++ [ pkgs.ctrl-panel ]
              ++ (lib.optional (
                config.ghaf.profiles.debug.enable && config.ghaf.virtualization.microvm.idsvm.mitmproxy.enable
              ) pkgs.mitmweb-ui)
              # Packages for checking hardware acceleration
              ++ lib.optionals config.ghaf.profiles.debug.enable [
                pkgs.glxinfo
                pkgs.libva-utils
                pkgs.glib
              ];
          };

          time.timeZone = config.time.timeZone;
          system.stateVersion = lib.trivial.release;

          nixpkgs = {
            buildPlatform.system = config.nixpkgs.buildPlatform.system;
            hostPlatform.system = config.nixpkgs.hostPlatform.system;
          };

          microvm = {
            optimize.enable = false;
            vcpu = 2;
            mem = 12288;
            hypervisor = "qemu";
            shares = [
              {
                tag = "waypipe-ssh-public-key";
                source = config.ghaf.security.sshKeys.waypipeSshPublicKeyDir;
                mountPoint = config.ghaf.security.sshKeys.waypipeSshPublicKeyDir;
                proto = "virtiofs";
              }
              {
                tag = "ro-store";
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
                proto = "virtiofs";
              }
            ];
            writableStoreOverlay = lib.mkIf config.ghaf.development.debug.tools.enable "/nix/.rw-store";

            qemu = {
              extraArgs = [
                "-device"
                "vhost-vsock-pci,guest-cid=${toString cfg.vsockCID}"
              ];

              machine =
                {
                  # Use the same machine type as the host
                  x86_64-linux = "q35";
                  aarch64-linux = "virt";
                }
                .${config.nixpkgs.hostPlatform.system};
            };
          };
        }
      )
    ];
  };
  cfg = config.ghaf.virtualization.microvm.guivm;

  # Importing kernel builder function and building guest_graphics_hardened_kernel
  buildKernel = import ../../../../packages/kernel { inherit config pkgs lib; };
  config_baseline = ../../../hardware/x86_64-generic/kernel/configs/ghaf_host_hardened_baseline-x86;
  guest_graphics_hardened_kernel = buildKernel { inherit config_baseline; };

in
{
  options.ghaf.virtualization.microvm.guivm = {
    enable = lib.mkEnableOption "GUIVM";

    extraModules = lib.mkOption {
      description = ''
        List of additional modules to be imported and evaluated as part of
        GUIVM's NixOS configuration.
      '';
      default = [ ];
    };

    # GUIVM uses a VSOCK which requires a CID
    # There are several special addresses:
    # VMADDR_CID_HYPERVISOR (0) is reserved for services built into the hypervisor
    # VMADDR_CID_LOCAL (1) is the well-known address for local communication (loopback)
    # VMADDR_CID_HOST (2) is the well-known address of the host
    # CID 3 is the lowest available number for guest virtual machines
    vsockCID = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = ''
        Context Identifier (CID) of the GUIVM VSOCK
      '';
    };

    applications = lib.mkOption {
      description = ''
        Applications to include in the GUIVM
      '';
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "The name of the application";
            };
            description = lib.mkOption {
              type = lib.types.str;
              description = "A brief description of the application";
            };
            icon = lib.mkOption {
              type = lib.types.str;
              description = "Application icon";
              default = null;
            };
            command = lib.mkOption {
              type = lib.types.str;
              description = "The command to run the application";
              default = null;
            };
          };
        }
      );
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    microvm.vms."${vmName}" = {
      autostart = true;
      inherit (inputs) nixpkgs;
      config = guivmBaseConfiguration // {
        boot.kernelPackages =
          if config.ghaf.guest.kernel.hardening.graphics.enable then
            pkgs.linuxPackagesFor guest_graphics_hardened_kernel
          else
            pkgs.linuxPackages_latest;

        # We need this patch to avoid reserving Intel graphics stolen memory for vm
        # https://gitlab.freedesktop.org/drm/i915/kernel/-/issues/12103
        boot.kernelPatches = [
          {
            name = "gpu-passthrough-fix";
            patch = ./0001-x86-gpu-Don-t-reserve-stolen-memory-for-GPU-passthro.patch;
          }
        ];

        imports = guivmBaseConfiguration.imports ++ cfg.extraModules;
      };
    };
  };
}

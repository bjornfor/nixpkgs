{ system, pkgs }:

with import ../../lib/testing-python.nix { inherit system pkgs; };
with pkgs.lib;

let

  # The configuration to install.
  makeConfig = { bootLoader, grubVersion, grubDevice, grubIdentifier, grubUseEfi
               , extraConfig, forceGrubReinstallCount ? 0
               }:
    pkgs.writeText "configuration.nix" ''
      { config, lib, pkgs, modulesPath, ... }:

      { imports =
          [ ./hardware-configuration.nix
            <nixpkgs/nixos/modules/testing/test-instrumentation.nix>
          ];

        # To ensure that we can rebuild the grub configuration on the nixos-rebuild
        system.extraDependencies = with pkgs; [ stdenvNoCC ];

        ${optionalString (bootLoader == "grub") ''
          boot.loader.grub.version = ${toString grubVersion};
          ${optionalString (grubVersion == 1) ''
            boot.loader.grub.splashImage = null;
          ''}

          boot.loader.grub.extraConfig = "serial; terminal_output serial";
          ${if grubUseEfi then ''
            boot.loader.grub.device = "nodev";
            boot.loader.grub.efiSupport = true;
            boot.loader.grub.efiInstallAsRemovable = true; # XXX: needed for OVMF?
          '' else ''
            boot.loader.grub.device = "${grubDevice}";
            boot.loader.grub.fsIdentifier = "${grubIdentifier}";
          ''}

          boot.loader.grub.configurationLimit = 100 + ${toString forceGrubReinstallCount};
        ''}

        ${optionalString (bootLoader == "systemd-boot") ''
          boot.loader.systemd-boot.enable = true;
        ''}

        users.users.alice = {
          isNormalUser = true;
          home = "/home/alice";
          description = "Alice Foobar";
        };

        hardware.enableAllFirmware = lib.mkForce false;

        ${replaceChars ["\n"] ["\n  "] extraConfig}
      }
    '';


  # The test script boots a NixOS VM, installs NixOS on an empty hard
  # disk, and then reboot from the hard disk.  It's parameterized with
  # a test script fragment `createPartitions', which must create
  # partitions and filesystems.
  testScriptFun = { bootLoader, createPartitions, grubVersion, grubDevice, grubUseEfi
                  , grubIdentifier, preBootCommands, postBootCommands, extraConfig
                  , testSpecialisationConfig
                  }:
    let iface = if grubVersion == 1 then "ide" else "virtio";
        isEfi = bootLoader == "systemd-boot" || (bootLoader == "grub" && grubUseEfi);
        bios  = if pkgs.stdenv.isAarch64 then "QEMU_EFI.fd" else "OVMF.fd";
    in if !isEfi && !(pkgs.stdenv.isi686 || pkgs.stdenv.isx86_64) then
      throw "Non-EFI boot methods are only supported on i686 / x86_64"
    else ''
      def assemble_qemu_flags():
          flags = "-cpu max"
          ${if system == "x86_64-linux"
            then ''flags += " -m 768"''
            else ''flags += " -m 512 -enable-kvm -machine virt,gic-version=host"''
          }
          return flags


      qemu_flags = {"qemuFlags": assemble_qemu_flags()}

      hd_flags = {
          "hdaInterface": "${iface}",
          "hda": "vm-state-machine/machine.qcow2",
      }
      ${optionalString isEfi ''
        hd_flags.update(
            bios="${pkgs.OVMF.fd}/FV/${bios}"
        )''
      }
      default_flags = {**hd_flags, **qemu_flags}


      def create_machine_named(name):
          return create_machine({**default_flags, "name": name})


      machine.start()

      with subtest("Assert readiness of login prompt"):
          machine.succeed("echo hello")

      with subtest("Wait for hard disks to appear in /dev"):
          machine.succeed("udevadm settle")

      ${createPartitions}

      with subtest("Create the NixOS configuration"):
          machine.succeed("nixos-generate-config --root /mnt")
          machine.succeed("cat /mnt/etc/nixos/hardware-configuration.nix >&2")
          machine.copy_from_host(
              "${ makeConfig {
                    inherit bootLoader grubVersion grubDevice grubIdentifier
                            grubUseEfi extraConfig;
                  }
              }",
              "/mnt/etc/nixos/configuration.nix",
          )

      with subtest("Perform the installation"):
          machine.succeed("nixos-install < /dev/null >&2")

      with subtest("Do it again to make sure it's idempotent"):
          machine.succeed("nixos-install < /dev/null >&2")

      with subtest("Shutdown system after installation"):
          machine.succeed("umount /mnt/boot || true")
          machine.succeed("umount /mnt")
          machine.succeed("sync")
          machine.shutdown()

      # Now see if we can boot the installation.
      machine = create_machine_named("boot-after-install")

      # For example to enter LUKS passphrase.
      ${preBootCommands}

      with subtest("Assert that /boot get mounted"):
          machine.wait_for_unit("local-fs.target")
          ${if bootLoader == "grub"
              then ''machine.succeed("test -e /boot/grub")''
              else ''machine.succeed("test -e /boot/loader/loader.conf")''
          }

      with subtest("Check whether /root has correct permissions"):
          assert "700" in machine.succeed("stat -c '%a' /root")

      with subtest("Assert swap device got activated"):
          # uncomment once https://bugs.freedesktop.org/show_bug.cgi?id=86930 is resolved
          machine.wait_for_unit("swap.target")
          machine.succeed("cat /proc/swaps | grep -q /dev")

      with subtest("Check that the store is in good shape"):
          machine.succeed("nix-store --verify --check-contents >&2")

      with subtest("Check whether the channel works"):
          machine.succeed("nix-env -iA nixos.procps >&2")
          assert ".nix-profile" in machine.succeed("type -tP ps | tee /dev/stderr")

      with subtest(
          "Check that the daemon works, and that non-root users can run builds "
          "(this will build a new profile generation through the daemon)"
      ):
          machine.succeed("su alice -l -c 'nix-env -iA nixos.procps' >&2")

      with subtest("Configure system with writable Nix store on next boot"):
          # we're not using copy_from_host here because the installer image
          # doesn't know about the host-guest sharing mechanism.
          machine.copy_from_host_via_shell(
              "${ makeConfig {
                    inherit bootLoader grubVersion grubDevice grubIdentifier
                            grubUseEfi extraConfig;
                    forceGrubReinstallCount = 1;
                  }
              }",
              "/etc/nixos/configuration.nix",
          )

      with subtest("Check whether nixos-rebuild works"):
          machine.succeed("nixos-rebuild switch >&2")

      with subtest("Test nixos-option"):
          kernel_modules = machine.succeed("nixos-option boot.initrd.kernelModules")
          assert "virtio_console" in kernel_modules
          assert "List of modules" in kernel_modules
          assert "qemu-guest.nix" in kernel_modules

      machine.shutdown()

      # Check whether a writable store build works
      machine = create_machine_named("rebuild-switch")
      ${preBootCommands}
      machine.wait_for_unit("multi-user.target")

      # we're not using copy_from_host here because the installer image
      # doesn't know about the host-guest sharing mechanism.
      machine.copy_from_host_via_shell(
          "${ makeConfig {
                inherit bootLoader grubVersion grubDevice grubIdentifier
                grubUseEfi extraConfig;
                forceGrubReinstallCount = 2;
              }
          }",
          "/etc/nixos/configuration.nix",
      )
      machine.succeed("nixos-rebuild boot >&2")
      machine.shutdown()

      # And just to be sure, check that the machine still boots after
      # "nixos-rebuild switch".
      machine = create_machine_named("boot-after-rebuild-switch")
      ${preBootCommands}
      machine.wait_for_unit("network.target")
      ${postBootCommands}
      machine.shutdown()

      # Tests for validating clone configuration entries in grub menu
    ''
    + optionalString testSpecialisationConfig ''
      # Reboot Machine
      machine = create_machine_named("clone-default-config")
      ${preBootCommands}
      machine.wait_for_unit("multi-user.target")

      with subtest("Booted configuration name should be 'Home'"):
          # This is not the name that shows in the grub menu.
          # The default configuration is always shown as "Default"
          machine.succeed("cat /run/booted-system/configuration-name >&2")
          assert "Home" in machine.succeed("cat /run/booted-system/configuration-name")

      with subtest("We should **not** find a file named /etc/gitconfig"):
          machine.fail("test -e /etc/gitconfig")

      with subtest("Set grub to boot the second configuration"):
          machine.succeed("grub-reboot 1")

      ${postBootCommands}
      machine.shutdown()

      # Reboot Machine
      machine = create_machine_named("clone-alternate-config")
      ${preBootCommands}

      machine.wait_for_unit("multi-user.target")
      with subtest("Booted configuration name should be Work"):
          machine.succeed("cat /run/booted-system/configuration-name >&2")
          assert "Work" in machine.succeed("cat /run/booted-system/configuration-name")

      with subtest("We should find a file named /etc/gitconfig"):
          machine.succeed("test -e /etc/gitconfig")

      ${postBootCommands}
      machine.shutdown()
    '';


  makeInstallerTest = name:
    { createPartitions, preBootCommands ? "", postBootCommands ? "", extraConfig ? ""
    , extraInstallerConfig ? {}
    , bootLoader ? "grub" # either "grub" or "systemd-boot"
    , grubVersion ? 2, grubDevice ? "/dev/vda", grubIdentifier ? "uuid", grubUseEfi ? false
    , enableOCR ? false, meta ? {}
    , testSpecialisationConfig ? false
    }:
    makeTest {
      inherit enableOCR;
      name = "installer-" + name;
      meta = with pkgs.stdenv.lib.maintainers; {
        # put global maintainers here, individuals go into makeInstallerTest fkt call
        maintainers = (meta.maintainers or []);
      };
      nodes = {

        # The configuration of the machine used to run "nixos-install".
        machine = { pkgs, ... }: {
          imports = [
            ../../modules/profiles/installation-device.nix
            ../../modules/profiles/base.nix
            extraInstallerConfig
          ];

          virtualisation.diskSize = 8 * 1024;
          virtualisation.memorySize = 1536;

          # Use a small /dev/vdb as the root disk for the
          # installer. This ensures the target disk (/dev/vda) is
          # the same during and after installation.
          virtualisation.emptyDiskImages = [ 512 ];
          virtualisation.bootDevice =
            if grubVersion == 1 then "/dev/sdb" else "/dev/vdb";
          virtualisation.qemu.diskInterface =
            if grubVersion == 1 then "scsi" else "virtio";

          boot.loader.systemd-boot.enable = mkIf (bootLoader == "systemd-boot") true;

          hardware.enableAllFirmware = mkForce false;

          # The test cannot access the network, so any packages we
          # need must be included in the VM.
          system.extraDependencies = with pkgs; [
            desktop-file-utils
            docbook5
            docbook_xsl_ns
            libxml2.bin
            libxslt.bin
            nixos-artwork.wallpapers.simple-dark-gray-bottom
            ntp
            perlPackages.ListCompare
            perlPackages.XMLLibXML
            shared-mime-info
            sudo
            texinfo
            unionfs-fuse
            xorg.lndir

            # add curl so that rather than seeing the test attempt to download
            # curl's tarball, we see what it's trying to download
            curl
          ]
          ++ optional (bootLoader == "grub" && grubVersion == 1) pkgs.grub
          ++ optionals (bootLoader == "grub" && grubVersion == 2) [
            pkgs.grub2
            pkgs.grub2_efi
          ];

          nix.binaryCaches = mkForce [ ];
          nix.extraOptions = ''
            hashed-mirrors =
            connect-timeout = 1
          '';
        };

      };

      testScript = testScriptFun {
        inherit bootLoader createPartitions preBootCommands postBootCommands
                grubVersion grubDevice grubIdentifier grubUseEfi extraConfig
                testSpecialisationConfig;
      };
    };
in
  makeInstallerTest

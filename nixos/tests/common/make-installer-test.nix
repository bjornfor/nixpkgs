{ system, pkgs }:

with import ../../lib/testing.nix { inherit system pkgs; };
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

          boot.loader.grub.extraConfig = "serial; terminal_output.serial";
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
                  , grubIdentifier, preBootCommands, extraConfig
                  , testCloneConfig
                  }:
    let
      iface = if grubVersion == 1 then "ide" else "virtio";
      isEfi = bootLoader == "systemd-boot" || (bootLoader == "grub" && grubUseEfi);

      # FIXME don't duplicate the -enable-kvm etc. flags here yet again!
      qemuFlags =
        (if system == "x86_64-linux" then "-m 768 " else "-m 512 ") +
        (optionalString (system == "x86_64-linux") "-cpu kvm64 ") +
        (optionalString (system == "aarch64-linux") "-enable-kvm -machine virt,gic-version=host -cpu host ");

      hdFlags = ''hda => "vm-state-machine/machine.qcow2", hdaInterface => "${iface}", ''
        + optionalString isEfi (if pkgs.stdenv.isAarch64
            then ''bios => "${pkgs.OVMF.fd}/FV/QEMU_EFI.fd", ''
            else ''bios => "${pkgs.OVMF.fd}/FV/OVMF.fd", '');
    in if !isEfi && !(pkgs.stdenv.isi686 || pkgs.stdenv.isx86_64) then
      throw "Non-EFI boot methods are only supported on i686 / x86_64"
    else ''

      $machine->start;

      # Make sure that we get a login prompt etc.
      $machine->succeed("echo hello");
      #$machine->waitForUnit('getty@tty2');
      #$machine->waitForUnit("rogue");
      $machine->waitForUnit("nixos-manual");

      # Wait for hard disks to appear in /dev
      $machine->succeed("udevadm settle");

      # Partition the disk.
      ${createPartitions}

      # Create the NixOS configuration.
      $machine->succeed("nixos-generate-config --root /mnt");

      $machine->succeed("cat /mnt/etc/nixos/hardware-configuration.nix >&2");

      $machine->copyFileFromHost(
          "${ makeConfig { inherit bootLoader grubVersion grubDevice grubIdentifier grubUseEfi extraConfig; } }",
          "/mnt/etc/nixos/configuration.nix");

      # Perform the installation.
      $machine->succeed("nixos-install < /dev/null >&2");

      # Do it again to make sure it's idempotent.
      $machine->succeed("nixos-install < /dev/null >&2");

      $machine->succeed("umount /mnt/boot || true");
      $machine->succeed("umount /mnt");
      $machine->succeed("sync");

      $machine->shutdown;

      # Now see if we can boot the installation.
      $machine = createMachine({ ${hdFlags} qemuFlags => "${qemuFlags}", name => "boot-after-install" });

      # For example to enter LUKS passphrase.
      ${preBootCommands}

      # Did /boot get mounted?
      $machine->waitForUnit("local-fs.target");

      ${if bootLoader == "grub" then
          ''$machine->succeed("test -e /boot/grub");''
        else
          ''$machine->succeed("test -e /boot/loader/loader.conf");''
      }

      # Check whether /root has correct permissions.
      $machine->succeed("stat -c '%a' /root") =~ /700/ or die;

      # Did the swap device get activated?
      # uncomment once https://bugs.freedesktop.org/show_bug.cgi?id=86930 is resolved
      $machine->waitForUnit("swap.target");
      $machine->succeed("cat /proc/swaps | grep -q /dev");

      # Check that the store is in good shape
      $machine->succeed("nix-store --verify --check-contents >&2");

      # Check whether the channel works.
      $machine->succeed("nix-env -iA nixos.procps >&2");
      $machine->succeed("type -tP ps | tee /dev/stderr") =~ /.nix-profile/
          or die "nix-env failed";

      # Check that the daemon works, and that non-root users can run builds (this will build a new profile generation through the daemon)
      $machine->succeed("su alice -l -c 'nix-env -iA nixos.procps' >&2");

      # We need a writable Nix store on next boot.
      $machine->copyFileFromHost(
          "${ makeConfig { inherit bootLoader grubVersion grubDevice grubIdentifier grubUseEfi extraConfig; forceGrubReinstallCount = 1; } }",
          "/etc/nixos/configuration.nix");

      # Check whether nixos-rebuild works.
      $machine->succeed("nixos-rebuild switch >&2");

      # Test nixos-option.
      $machine->succeed("nixos-option boot.initrd.kernelModules | grep virtio_console");
      $machine->succeed("nixos-option boot.initrd.kernelModules | grep 'List of modules'");
      $machine->succeed("nixos-option boot.initrd.kernelModules | grep qemu-guest.nix");

      $machine->shutdown;

      # Check whether a writable store build works
      $machine = createMachine({ ${hdFlags} qemuFlags => "${qemuFlags}", name => "rebuild-switch" });
      ${preBootCommands}
      $machine->waitForUnit("multi-user.target");
      $machine->copyFileFromHost(
          "${ makeConfig { inherit bootLoader grubVersion grubDevice grubIdentifier grubUseEfi extraConfig; forceGrubReinstallCount = 2; } }",
          "/etc/nixos/configuration.nix");
      $machine->succeed("nixos-rebuild boot >&2");
      $machine->shutdown;

      # And just to be sure, check that the machine still boots after
      # "nixos-rebuild switch".
      $machine = createMachine({ ${hdFlags} qemuFlags => "${qemuFlags}", "boot-after-rebuild-switch" });
      ${preBootCommands}
      $machine->waitForUnit("network.target");
      $machine->shutdown;

      # Tests for validating clone configuration entries in grub menu
      ${optionalString testCloneConfig ''
        # Reboot Machine
        $machine = createMachine({ ${hdFlags} qemuFlags => "${qemuFlags}", name => "clone-default-config" });
        ${preBootCommands}
        $machine->waitForUnit("multi-user.target");

        # Booted configuration name should be Home
        # This is not the name that shows in the grub menu.
        # The default configuration is always shown as "Default"
        $machine->succeed("cat /run/booted-system/configuration-name >&2");
        $machine->succeed("cat /run/booted-system/configuration-name | grep Home");

        # We should find **not** a file named /etc/gitconfig
        $machine->fail("test -e /etc/gitconfig");

        # Set grub to boot the second configuration
        $machine->succeed("grub-reboot 1");

        $machine->shutdown;

        # Reboot Machine
        $machine = createMachine({ ${hdFlags} qemuFlags => "${qemuFlags}", name => "clone-alternate-config" });
        ${preBootCommands}

        $machine->waitForUnit("multi-user.target");
        # Booted configuration name should be Work
        $machine->succeed("cat /run/booted-system/configuration-name >&2");
        $machine->succeed("cat /run/booted-system/configuration-name | grep Work");

        # We should find a file named /etc/gitconfig
        $machine->succeed("test -e /etc/gitconfig");

        $machine->shutdown;
      ''}

    '';

  makeInstallerTest = name:
    { createPartitions, preBootCommands ? "", extraConfig ? ""
    , extraInstallerConfig ? {}
    , bootLoader ? "grub" # either "grub" or "systemd-boot"
    , grubVersion ? 2, grubDevice ? "/dev/vda", grubIdentifier ? "uuid", grubUseEfi ? false
    , enableOCR ? false, meta ? {}
    , testCloneConfig ? false
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
        machine =
          { pkgs, ... }:

          { imports =
              [ ../../modules/profiles/installation-device.nix
                ../../modules/profiles/base.nix
                extraInstallerConfig
              ];

            virtualisation.diskSize = 8 * 1024;
            virtualisation.memorySize = 1024;

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
            system.extraDependencies = with pkgs;
              [ sudo
                libxml2.bin
                libxslt.bin
                desktop-file-utils
                docbook5
                docbook_xsl_ns
                unionfs-fuse
                ntp
                nixos-artwork.wallpapers.simple-dark-gray-bottom
                perlPackages.XMLLibXML
                perlPackages.ListCompare
                shared-mime-info
                texinfo
                xorg.lndir

                # add curl so that rather than seeing the test attempt to download
                # curl's tarball, we see what it's trying to download
                curl
              ]
              ++ optional (bootLoader == "grub" && grubVersion == 1) pkgs.grub
              ++ optionals (bootLoader == "grub" && grubVersion == 2) [ pkgs.grub2 pkgs.grub2_efi ];

            nix.binaryCaches = mkForce [ ];
            nix.extraOptions =
              ''
                hashed-mirrors =
                connect-timeout = 1
              '';
          };

      };

      testScript = testScriptFun {
        inherit bootLoader createPartitions preBootCommands
                grubVersion grubDevice grubIdentifier grubUseEfi extraConfig
                testCloneConfig;
      };
    };
in
  makeInstallerTest

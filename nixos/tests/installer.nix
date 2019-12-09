{ system ? builtins.currentSystem,
  config ? {},
  pkgs ? import ../.. { inherit system config; }
}:

let

  makeInstallerTest = import ./common/make-installer-test.nix { inherit system pkgs; };

    makeLuksRootTest = name: luksFormatOpts: makeInstallerTest name {
      createPartitions = ''
        machine.succeed(
            "flock /dev/vda parted --script /dev/vda -- mklabel msdos"
            + " mkpart primary ext2 1M 50MB"  # /boot
            + " mkpart primary linux-swap 50M 1024M"
            + " mkpart primary 1024M -1s",  # LUKS
            "udevadm settle",
            "mkswap /dev/vda2 -L swap",
            "swapon -L swap",
            "modprobe dm_mod dm_crypt",
            "echo -n supersecret | cryptsetup luksFormat ${luksFormatOpts} -q /dev/vda3 -",
            "echo -n supersecret | cryptsetup luksOpen --key-file - /dev/vda3 cryptroot",
            "mkfs.ext3 -L nixos /dev/mapper/cryptroot",
            "mount LABEL=nixos /mnt",
            "mkfs.ext3 -L boot /dev/vda1",
            "mkdir -p /mnt/boot",
            "mount LABEL=boot /mnt/boot",
        )
      '';
      extraConfig = ''
        boot.kernelParams = lib.mkAfter [ "console=tty0" ];
      '';
      enableOCR = true;
      preBootCommands = ''
        machine.start()
        machine.wait_for_text("Passphrase for")
        machine.send_chars("supersecret\n")
      '';
    };

  # The (almost) simplest partitioning scheme: a swap partition and
  # one big filesystem partition.
  simple-test-config = {
    createPartitions = ''
      machine.succeed(
          "flock /dev/vda parted --script /dev/vda -- mklabel msdos"
          + " mkpart primary linux-swap 1M 1024M"
          + " mkpart primary ext2 1024M -1s",
          "udevadm settle",
          "mkswap /dev/vda1 -L swap",
          "swapon -L swap",
          "mkfs.ext3 -L nixos /dev/vda2",
          "mount LABEL=nixos /mnt",
      )
    '';
  };

  simple-uefi-grub-config = {
    createPartitions = ''
      machine.succeed(
          "flock /dev/vda parted --script /dev/vda -- mklabel gpt"
          + " mkpart ESP fat32 1M 50MiB"  # /boot
          + " set 1 boot on"
          + " mkpart primary linux-swap 50MiB 1024MiB"
          + " mkpart primary ext2 1024MiB -1MiB",  # /
          "udevadm settle",
          "mkswap /dev/vda2 -L swap",
          "swapon -L swap",
          "mkfs.ext3 -L nixos /dev/vda3",
          "mount LABEL=nixos /mnt",
          "mkfs.vfat -n BOOT /dev/vda1",
          "mkdir -p /mnt/boot",
          "mount LABEL=BOOT /mnt/boot",
      )
    '';
    bootLoader = "grub";
    grubUseEfi = true;
  };

  specialisation-test-extraconfig = {
    extraConfig = ''
      environment.systemPackages = [ pkgs.grub2 ];
      boot.loader.grub.configurationName = "Home";
      specialisation.work.configuration = {
        boot.loader.grub.configurationName = lib.mkForce "Work";

        environment.etc = {
          "gitconfig".text = "
            [core]
              gitproxy = none for work.com
              ";
        };
      };
    '';
    testSpecialisationConfig = true;
  };


in {

  # !!! `parted mkpart' seems to silently create overlapping partitions.


  # The (almost) simplest partitioning scheme: a swap partition and
  # one big filesystem partition.
  simple = makeInstallerTest "simple" simple-test-config;

  # Test cloned configurations with the simple grub configuration
  simpleSpecialised = makeInstallerTest "simpleSpecialised" (simple-test-config // specialisation-test-extraconfig);

  # Simple GPT/UEFI configuration using systemd-boot with 3 partitions: ESP, swap & root filesystem
  simpleUefiSystemdBoot = makeInstallerTest "simpleUefiSystemdBoot" {
    createPartitions = ''
      machine.succeed(
          "flock /dev/vda parted --script /dev/vda -- mklabel gpt"
          + " mkpart ESP fat32 1M 50MiB"  # /boot
          + " set 1 boot on"
          + " mkpart primary linux-swap 50MiB 1024MiB"
          + " mkpart primary ext2 1024MiB -1MiB",  # /
          "udevadm settle",
          "mkswap /dev/vda2 -L swap",
          "swapon -L swap",
          "mkfs.ext3 -L nixos /dev/vda3",
          "mount LABEL=nixos /mnt",
          "mkfs.vfat -n BOOT /dev/vda1",
          "mkdir -p /mnt/boot",
          "mount LABEL=BOOT /mnt/boot",
      )
    '';
    bootLoader = "systemd-boot";
  };

  simpleUefiGrub = makeInstallerTest "simpleUefiGrub" simple-uefi-grub-config;

  # Test cloned configurations with the uefi grub configuration
  simpleUefiGrubSpecialisation = makeInstallerTest "simpleUefiGrubSpecialisation" (simple-uefi-grub-config // specialisation-test-extraconfig);

  # Same as the previous, but now with a separate /boot partition.
  separateBoot = makeInstallerTest "separateBoot" {
    createPartitions = ''
      machine.succeed(
          "flock /dev/vda parted --script /dev/vda -- mklabel msdos"
          + " mkpart primary ext2 1M 50MB"  # /boot
          + " mkpart primary linux-swap 50MB 1024M"
          + " mkpart primary ext2 1024M -1s",  # /
          "udevadm settle",
          "mkswap /dev/vda2 -L swap",
          "swapon -L swap",
          "mkfs.ext3 -L nixos /dev/vda3",
          "mount LABEL=nixos /mnt",
          "mkfs.ext3 -L boot /dev/vda1",
          "mkdir -p /mnt/boot",
          "mount LABEL=boot /mnt/boot",
      )
    '';
  };

  # Same as the previous, but with fat32 /boot.
  separateBootFat = makeInstallerTest "separateBootFat" {
    createPartitions = ''
      machine.succeed(
          "flock /dev/vda parted --script /dev/vda -- mklabel msdos"
          + " mkpart primary ext2 1M 50MB"  # /boot
          + " mkpart primary linux-swap 50MB 1024M"
          + " mkpart primary ext2 1024M -1s",  # /
          "udevadm settle",
          "mkswap /dev/vda2 -L swap",
          "swapon -L swap",
          "mkfs.ext3 -L nixos /dev/vda3",
          "mount LABEL=nixos /mnt",
          "mkfs.vfat -n BOOT /dev/vda1",
          "mkdir -p /mnt/boot",
          "mount LABEL=BOOT /mnt/boot",
      )
    '';
  };

  # zfs on / with swap
  zfsroot = makeInstallerTest "zfs-root" {
    extraInstallerConfig = {
      boot.supportedFilesystems = [ "zfs" ];
    };

    extraConfig = ''
      boot.supportedFilesystems = [ "zfs" ];

      # Using by-uuid overrides the default of by-id, and is unique
      # to the qemu disks, as they don't produce by-id paths for
      # some reason.
      boot.zfs.devNodes = "/dev/disk/by-uuid/";
      networking.hostId = "00000000";
    '';

    createPartitions = ''
      machine.succeed(
          "flock /dev/vda parted --script /dev/vda -- mklabel msdos"
          + " mkpart primary linux-swap 1M 1024M"
          + " mkpart primary 1024M -1s",
          "udevadm settle",
          "mkswap /dev/vda1 -L swap",
          "swapon -L swap",
          "zpool create rpool /dev/vda2",
          "zfs create -o mountpoint=legacy rpool/root",
          "mount -t zfs rpool/root /mnt",
          "udevadm settle",
      )
    '';
  };

  # Create two physical LVM partitions combined into one volume group
  # that contains the logical swap and root partitions.
  lvm = makeInstallerTest "lvm" {
    createPartitions = ''
      machine.succeed(
          "flock /dev/vda parted --script /dev/vda -- mklabel msdos"
          + " mkpart primary 1M 2048M"  # PV1
          + " set 1 lvm on"
          + " mkpart primary 2048M -1s"  # PV2
          + " set 2 lvm on",
          "udevadm settle",
          "sleep 1",
          "pvcreate /dev/vda1 /dev/vda2",
          "sleep 1",
          "vgcreate MyVolGroup /dev/vda1 /dev/vda2",
          "sleep 1",
          "lvcreate --size 1G --name swap MyVolGroup",
          "sleep 1",
          "lvcreate --size 3G --name nixos MyVolGroup",
          "sleep 1",
          "mkswap -f /dev/MyVolGroup/swap -L swap",
          "swapon -L swap",
          "mkfs.xfs -L nixos /dev/MyVolGroup/nixos",
          "mount LABEL=nixos /mnt",
      )
    '';
    postBootCommands = ''
      assert "loaded active" in machine.succeed(
          "systemctl list-units 'lvm2-pvscan@*' -ql --no-legend | tee /dev/stderr"
      )
    '';
  };

  # Boot off an encrypted root partition with the default LUKS header format
  luksroot = makeLuksRootTest "luksroot-format1" "";

  # Boot off an encrypted root partition with LUKS1 format
  luksroot-format1 = makeLuksRootTest "luksroot-format1" "--type=LUKS1";

  # Boot off an encrypted root partition with LUKS2 format
  luksroot-format2 = makeLuksRootTest "luksroot-format2" "--type=LUKS2";

  # Test whether opening encrypted filesystem with keyfile
  # Checks for regression of missing cryptsetup, when no luks device without
  # keyfile is configured
  encryptedFSWithKeyfile = makeInstallerTest "encryptedFSWithKeyfile" {
    createPartitions = ''
      machine.succeed(
          "flock /dev/vda parted --script /dev/vda -- mklabel msdos"
          + " mkpart primary ext2 1M 50MB"  # /boot
          + " mkpart primary linux-swap 50M 1024M"
          + " mkpart primary 1024M 1280M"  # LUKS with keyfile
          + " mkpart primary 1280M -1s",
          "udevadm settle",
          "mkswap /dev/vda2 -L swap",
          "swapon -L swap",
          "mkfs.ext3 -L nixos /dev/vda4",
          "mount LABEL=nixos /mnt",
          "mkfs.ext3 -L boot /dev/vda1",
          "mkdir -p /mnt/boot",
          "mount LABEL=boot /mnt/boot",
          "modprobe dm_mod dm_crypt",
          "echo -n supersecret > /mnt/keyfile",
          "cryptsetup luksFormat -q /dev/vda3 --key-file /mnt/keyfile",
          "cryptsetup luksOpen --key-file /mnt/keyfile /dev/vda3 crypt",
          "mkfs.ext3 -L test /dev/mapper/crypt",
          "cryptsetup luksClose crypt",
          "mkdir -p /mnt/test",
      )
    '';
    extraConfig = ''
      fileSystems."/test" = {
        device = "/dev/disk/by-label/test";
        fsType = "ext3";
        encrypted.enable = true;
        encrypted.blkDev = "/dev/vda3";
        encrypted.label = "crypt";
        encrypted.keyFile = "/mnt-root/keyfile";
      };
    '';
  };

  swraid = makeInstallerTest "swraid" {
    createPartitions = ''
      machine.succeed(
          "flock /dev/vda parted --script /dev/vda --"
          + " mklabel msdos"
          + " mkpart primary ext2 1M 100MB"  # /boot
          + " mkpart extended 100M -1s"
          + " mkpart logical 102M 3102M"  # md0 (root), first device
          + " mkpart logical 3103M 6103M"  # md0 (root), second device
          + " mkpart logical 6104M 6360M"  # md1 (swap), first device
          + " mkpart logical 6361M 6617M",  # md1 (swap), second device
          "udevadm settle",
          "ls -l /dev/vda* >&2",
          "cat /proc/partitions >&2",
          "udevadm control --stop-exec-queue",
          "mdadm --create --force /dev/md0 --metadata 1.2 --level=raid1 "
          + "--raid-devices=2 /dev/vda5 /dev/vda6",
          "mdadm --create --force /dev/md1 --metadata 1.2 --level=raid1 "
          + "--raid-devices=2 /dev/vda7 /dev/vda8",
          "udevadm control --start-exec-queue",
          "udevadm settle",
          "mkswap -f /dev/md1 -L swap",
          "swapon -L swap",
          "mkfs.ext3 -L nixos /dev/md0",
          "mount LABEL=nixos /mnt",
          "mkfs.ext3 -L boot /dev/vda1",
          "mkdir /mnt/boot",
          "mount LABEL=boot /mnt/boot",
          "udevadm settle",
      )
    '';
    preBootCommands = ''
      machine.start()
      machine.fail("dmesg | grep 'immediate safe mode'")
    '';
  };

  bcache = makeInstallerTest "bcache" {
    createPartitions = ''
      machine.succeed(
          "flock /dev/vda parted --script /dev/vda --"
          + " mklabel msdos"
          + " mkpart primary ext2 1M 50MB"  # /boot
          + " mkpart primary 50MB 512MB  "  # swap
          + " mkpart primary 512MB 1024MB"  # Cache (typically SSD)
          + " mkpart primary 1024MB -1s ",  # Backing device (typically HDD)
          "modprobe bcache",
          "udevadm settle",
          "make-bcache -B /dev/vda4 -C /dev/vda3",
          "echo /dev/vda3 > /sys/fs/bcache/register",
          "echo /dev/vda4 > /sys/fs/bcache/register",
          "udevadm settle",
          "mkfs.ext3 -L nixos /dev/bcache0",
          "mount LABEL=nixos /mnt",
          "mkfs.ext3 -L boot /dev/vda1",
          "mkdir /mnt/boot",
          "mount LABEL=boot /mnt/boot",
          "mkswap -f /dev/vda2 -L swap",
          "swapon -L swap",
      )
    '';
  };

  # Test a basic install using GRUB 1.
  grub1 = makeInstallerTest "grub1" {
    createPartitions = ''
      machine.succeed(
          "flock /dev/sda parted --script /dev/sda -- mklabel msdos"
          + " mkpart primary linux-swap 1M 1024M"
          + " mkpart primary ext2 1024M -1s",
          "udevadm settle",
          "mkswap /dev/sda1 -L swap",
          "swapon -L swap",
          "mkfs.ext3 -L nixos /dev/sda2",
          "mount LABEL=nixos /mnt",
          "mkdir -p /mnt/tmp",
      )
    '';
    grubVersion = 1;
    grubDevice = "/dev/sda";
  };

  # Test using labels to identify volumes in grub
  simpleLabels = makeInstallerTest "simpleLabels" {
    createPartitions = ''
      machine.succeed(
          "sgdisk -Z /dev/vda",
          "sgdisk -n 1:0:+1M -n 2:0:+1G -N 3 -t 1:ef02 -t 2:8200 -t 3:8300 -c 3:root /dev/vda",
          "mkswap /dev/vda2 -L swap",
          "swapon -L swap",
          "mkfs.ext4 -L root /dev/vda3",
          "mount LABEL=root /mnt",
      )
    '';
    grubIdentifier = "label";
  };

  # Test using the provided disk name within grub
  # TODO: Fix udev so the symlinks are unneeded in /dev/disks
  simpleProvided = makeInstallerTest "simpleProvided" {
    createPartitions = ''
      uuid = "$(blkid -s UUID -o value /dev/vda2)"
      machine.succeed(
          "sgdisk -Z /dev/vda",
          "sgdisk -n 1:0:+1M -n 2:0:+100M -n 3:0:+1G -N 4 -t 1:ef02 -t 2:8300 "
          + "-t 3:8200 -t 4:8300 -c 2:boot -c 4:root /dev/vda",
          "mkswap /dev/vda3 -L swap",
          "swapon -L swap",
          "mkfs.ext4 -L boot /dev/vda2",
          "mkfs.ext4 -L root /dev/vda4",
      )
      machine.execute(f"ln -s ../../vda2 /dev/disk/by-uuid/{uuid}")
      machine.execute("ln -s ../../vda4 /dev/disk/by-label/root")
      machine.succeed(
          "mount /dev/disk/by-label/root /mnt",
          "mkdir /mnt/boot",
          f"mount /dev/disk/by-uuid/{uuid} /mnt/boot",
      )
    '';
    grubIdentifier = "provided";
  };

  # Simple btrfs grub testing
  btrfsSimple = makeInstallerTest "btrfsSimple" {
    createPartitions = ''
      machine.succeed(
          "sgdisk -Z /dev/vda",
          "sgdisk -n 1:0:+1M -n 2:0:+1G -N 3 -t 1:ef02 -t 2:8200 -t 3:8300 -c 3:root /dev/vda",
          "mkswap /dev/vda2 -L swap",
          "swapon -L swap",
          "mkfs.btrfs -L root /dev/vda3",
          "mount LABEL=root /mnt",
      )
    '';
  };

  # Test to see if we can detect /boot and /nix on subvolumes
  btrfsSubvols = makeInstallerTest "btrfsSubvols" {
    createPartitions = ''
      machine.succeed(
          "sgdisk -Z /dev/vda",
          "sgdisk -n 1:0:+1M -n 2:0:+1G -N 3 -t 1:ef02 -t 2:8200 -t 3:8300 -c 3:root /dev/vda",
          "mkswap /dev/vda2 -L swap",
          "swapon -L swap",
          "mkfs.btrfs -L root /dev/vda3",
          "btrfs device scan",
          "mount LABEL=root /mnt",
          "btrfs subvol create /mnt/boot",
          "btrfs subvol create /mnt/nixos",
          "btrfs subvol create /mnt/nixos/default",
          "umount /mnt",
          "mount -o defaults,subvol=nixos/default LABEL=root /mnt",
          "mkdir /mnt/boot",
          "mount -o defaults,subvol=boot LABEL=root /mnt/boot",
      )
    '';
  };

  # Test to see if we can detect default and aux subvolumes correctly
  btrfsSubvolDefault = makeInstallerTest "btrfsSubvolDefault" {
    createPartitions = ''
      machine.succeed(
          "sgdisk -Z /dev/vda",
          "sgdisk -n 1:0:+1M -n 2:0:+1G -N 3 -t 1:ef02 -t 2:8200 -t 3:8300 -c 3:root /dev/vda",
          "mkswap /dev/vda2 -L swap",
          "swapon -L swap",
          "mkfs.btrfs -L root /dev/vda3",
          "btrfs device scan",
          "mount LABEL=root /mnt",
          "btrfs subvol create /mnt/badpath",
          "btrfs subvol create /mnt/badpath/boot",
          "btrfs subvol create /mnt/nixos",
          "btrfs subvol set-default "
          + "$(btrfs subvol list /mnt | grep 'nixos' | awk '{print $2}') /mnt",
          "umount /mnt",
          "mount -o defaults LABEL=root /mnt",
          "mkdir -p /mnt/badpath/boot",  # Help ensure the detection mechanism
          # is actually looking up subvolumes
          "mkdir /mnt/boot",
          "mount -o defaults,subvol=badpath/boot LABEL=root /mnt/boot",
      )
    '';
  };
}

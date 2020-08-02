import ./make-test-python.nix ({ lib, pkgs, ... }: let

  deviceId1 = "7CFNTQM-IMTJBHJ-3UWRDIU-ZGQJFR6-VCXZ3NB-XUH3KZO-N52ITXR-LAIYUAU";
  deviceId2 = "MOCHECW-MS2ITIU-G73PLU5-WXDV4TG-XEC3FYQ-3HTJ625-DR4BYCH-F7YHTQB";

  # two folders shared with two devices
  baseConfig = {
    services.syncthing = {
      enable = true;
      declarative = {
        devices = {
          deviceName1.id = deviceId1;
          deviceName2.id = deviceId2;
        };
        folders = {
          testFolder1 = {
            path = "/tmp/test1";
            devices = [ "deviceName1" "deviceName2" ];
          };
          testFolder2 = {
            path = "/tmp/test2";
            devices = [ "deviceName1" "deviceName2" ];
          };
        };
      };
    };
  };

in {
  name = "syncthing-init";
  meta.maintainers = with pkgs.stdenv.lib.maintainers; [ lassulus ];

  nodes = {
    machine = {
      imports = [ baseConfig ];
    };

    # one folder shared with one device
    updatedConfig = {
      imports = [ baseConfig ];
      services.syncthing.declarative = {
        devices = lib.mkForce {
          deviceName1.id = deviceId1;
        };
        folders = lib.mkForce {
          testFolder1.devices = [
            "deviceName1"
          ];
        };
      };
    };
  };

  testScript = { nodes, ... }:
    let
      newConfig = nodes.updatedConfig.config.system.build.toplevel;
      switchToNewConfig = "${newConfig}/bin/switch-to-configuration test";
    in ''
      machine.wait_for_unit("syncthing-init.service")
      config = machine.succeed("cat /var/lib/syncthing/.config/syncthing/config.xml")

      assert "testFolder1" in config
      assert "testFolder2" in config
      assert "${deviceId1}" in config
      assert "${deviceId2}" in config

      machine.succeed(
          "${switchToNewConfig}"
      )
      machine.wait_for_unit("syncthing-init.service")
      config = machine.succeed("cat /var/lib/syncthing/.config/syncthing/config.xml")
      assert "testFolder1" in config
      assert not "testFolder2" in config
      assert "${deviceId1}" in config
      assert not "${deviceId2}" in config
    '';
  })


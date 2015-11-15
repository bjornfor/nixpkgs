{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.x2goserver;

in

{

  options = {

    services.x2goserver = {

      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether or not to enable the the X2Go remote desktop server.
        '';
      };

    };

  };

  config = mkIf cfg.enable {

    environment.systemPackages = [ pkgs.x2goserver ];

    environment.etc."x2gosql/sql".text = ''
      backend=sqlite
    '';

    systemd.packages = [ pkgs.x2goserver ];

    users.users.x2gouser = {
      description = "X2Go remote desktop user";
      uid = config.ids.uids.x2gouser;
      #gid = config.ids.gids.x2gouser;
      createHome = true;
      home = "/var/lib/x2go";
    };

    users.users.x2goprint = {
      description = "X2Go remote desktop print user";
      uid = config.ids.uids.x2goprint;
      #gid = config.ids.gids.x2goprint;
      createHome = true;
      home = "/var/spool/x2goprint";
    };

  };
}

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
    systemd.services.x2goserver.preStart = ''
      # X2go homedir + printing spool dir
      install -dm 0770 --owner=x2gouser --group=x2gouser /var/lib/x2go
      install -dm 0770 --owner=x2goprint --group=x2goprint /var/spool/x2goprint
    '';
      ## load fuse module at system start
      #install -dm755 $pkgdir/usr/lib/modules-load.d
      #echo "fuse" > $pkgdir/usr/lib/modules-load.d/x2goserver.conf

      #install -dm 755 "${pkgdir}/usr/share/doc/${pkgname}"
      #install -m 644 "ChangeLog" "${pkgdir}/usr/share/doc/${pkgname}/"

      ## fix permission - see INSTALL file
      #chown root:111 ${pkgdir}/usr/lib/x2go/x2gosqlitewrapper
      #chmod 2755 ${pkgdir}/usr/lib/x2go/x2gosqlitewrapper

      #chown root:112 ${pkgdir}/usr/bin/x2goprint
      #chmod 2755 ${pkgdir}/usr/bin/x2goprint

      #chmod 750 ${pkgdir}/etc/sudoers.d
      #chmod 0440 ${pkgdir}/etc/sudoers.d/x2goserver

    users.users.x2gouser = {
      description = "X2Go remote desktop user";
      uid = config.ids.uids.x2gouser;
      group = "x2gouser";
      #createHome = true;  # let systemd do it (ensures perms are OK)
      home = "/var/lib/x2go";
    };

    users.users.x2goprint = {
      description = "X2Go remote desktop print user";
      uid = config.ids.uids.x2goprint;
      group = "x2goprint";
      #createHome = true;  # let systemd do it (ensures perms are OK)
      home = "/var/spool/x2goprint";
    };

    users.groups.x2gouser.gid = config.ids.gids.x2gouser;
    users.groups.x2goprint.gid = config.ids.gids.x2goprint;

  };
}

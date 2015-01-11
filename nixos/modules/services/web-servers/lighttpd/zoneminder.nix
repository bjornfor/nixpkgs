{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.lighttpd.zoneminder;

in
{

  options.services.lighttpd.zoneminder = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable ZoneMinder, the video security and surveillance
        system. If true, you can access ZoneMinder at
        http://yourserver/zoneminder.
      '';
    };

  };

  config = mkIf cfg.enable {

    # zoneminder suggests (in the log) to run "zmupdate.pl -f" to reload
    # config. Remove it once we have the config under control (that message
    # shouldn't be there in the first place).
    environment.systemPackages = [ pkgs.zoneminder ];

    environment.etc."zm.conf".source = "${pkgs.zoneminder}/etc/zm.conf";
    # FIXME: Blah, zoneminder wants a writeable ZM_PATH_WEB. Provide a
    # writeable zm.conf so we can manipulate it before zoneminder starts.
    environment.etc."zm.conf".mode = "0660";
    environment.etc."zm.conf".gid = 65534; # nogroup (zoneminder)

    # declare module dependencies
    services.lighttpd.enableModules = [ "mod_fastcgi" "mod_alias" ];

    services.lighttpd.extraConfig = ''
      $HTTP["url"] =~ "^/zoneminder" {
        index-file.names += ( "index.php" )

        alias.url += ( "/zoneminder" =>
          "${pkgs.zoneminder}/share/zoneminder/www/" )

        fastcgi.server = (
          ".php" => (
            "localhost" => (
              "socket" => "/run/phpfpm/zoneminder",
            ))
        )
      }
    '';

    services.phpfpm.poolConfigs = {
      zoneminder = ''
        listen = /run/phpfpm/zoneminder
        listen.group = lighttpd
        user = nobody
        pm = dynamic
        pm.max_children = 75
        pm.start_servers = 10
        pm.min_spare_servers = 5
        pm.max_spare_servers = 20
        pm.max_requests = 500
      '';
    };

    services.mysql = {
      enable = true;
      # uhm, selecting a package is probably mandatory...
      #package = pkgs.mysql;
    };

    # FIXME: Handle creating the initial database and granting privileges to
    # 'zmuser'.

    # FIXME: Need to have a proper user (not 'nobody') for zoneminder. This
    # user will need to be in the 'video' group to get access to video cameras.

    systemd.services.zoneminder = {
      description = "ZoneMinder Video Security And Surveillance System";
      after = [ "mysql.target" ];
      wantedBy = [ "multi-user.target" ];
      # zmdc.pl wants to create a unix socket in /tmp/zm
      preStart = ''
        mkdir -p /tmp/zm
        chown nobody /tmp/zm

        # zoneminder wants a writeable ZM_PATH_WEB ...
        ${pkgs.rsync}/bin/rsync -r ${pkgs.zoneminder}/ /var/lib/zoneminder/
        chown -R nobody /var/lib/zoneminder
        sed -i -e "s|ZM_PATH_WEB=.*|ZM_PATH_WEB=/var/lib/zoneminder/share/zoneminder/www|" -i /etc/zm.conf
      '';
      serviceConfig = {
        ExecStart = "${pkgs.zoneminder}/bin/zmpkg.pl start";
        ExecReload = "${pkgs.zoneminder}/bin/zmpkg.pl reload";
        Type = "forking";
        PIDFile = "/run/zm/zm.pid";
        # To get /var/setuid-wrappers into PATH, we have to duplicate the
        # default PATH (systemd.services.<name>.path doesn't work, since it
        # adds /bin to the path). We actually just want to prepend
        # /var/setuid-wrappers, and a few other paths.
        Environment = "PATH=/var/setuid-wrappers:${with pkgs; makeSearchPath "bin" [ procps mysql psmisc coreutils findutils gnugrep gnused systemd ]}";
      };
    };

  };

}

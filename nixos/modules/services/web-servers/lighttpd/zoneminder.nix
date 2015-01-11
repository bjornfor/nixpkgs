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
  };

}

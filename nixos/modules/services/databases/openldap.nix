{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.openldap;
  configFile = pkgs.writeText "slapd.conf" cfg.extraConfig;

in

{

  ###### interface

  options = {

    services.openldap = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "
          Whether to enable the ldap server.
        ";
      };

      user = mkOption {
        type = types.str;
        default = "openldap";
        description = "User account under which slapd runs.";
      };

      group = mkOption {
        type = types.str;
        default = "openldap";
        description = "Group account under which slapd runs.";
      };

      urlList = mkOption {
        type = types.listOf types.str;
        default = [ "ldap:///" ];
        description = "URL list slapd should listen on.";
        example = [ "ldaps:///" ];
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/db/openldap";
        description = "The database directory.";
      };

      configDir = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Use this optional config directory instead of using slapd.conf";
        example = "/var/db/slapd.d";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "
          Text to be added to slapd.conf.
        ";
        example = literalExample ''
          '''
            include ${pkgs.openldap.out}/etc/schema/core.schema
            include ${pkgs.openldap.out}/etc/schema/cosine.schema
            include ${pkgs.openldap.out}/etc/schema/inetorgperson.schema
            include ${pkgs.openldap.out}/etc/schema/nis.schema

            database mdb
            suffix dc=example,dc=org
            rootdn cn=admin,dc=example,dc=org
            # NOTE: change after first start
            rootpw secret
            directory ''${config.services.openldap.dataDir}
          '''
        '';
      };
    };

  };


  ###### implementation

  config = mkIf config.services.openldap.enable {

    assertions = [
      { assertion = cfg.extraConfig != "" || cfg.configDir != null;
        message = ''
          Neither services.openldap.extraConfig nor services.openldap.configDir
          is set, this cannot work.
        '';
      }
    ];

    environment.systemPackages = [ pkgs.openldap ];

    systemd.services.openldap = {
      description = "LDAP server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      preStart = ''
        mkdir -p /var/run/slapd
        chown -R ${cfg.user}:${cfg.group} /var/run/slapd
        mkdir -p ${cfg.dataDir}
        chown -R ${cfg.user}:${cfg.group} ${cfg.dataDir}
      '';
      serviceConfig.ExecStart = "${pkgs.openldap.out}/libexec/slapd"
        + " -u ${cfg.user} -g ${cfg.group} -d 0"
        + " -h \"${concatStringsSep " " cfg.urlList}\""
        + " ${if cfg.configDir == null
              then "-f " + configFile
              else "-F " + cfg.configDir}";
    };

    users.extraUsers.openldap =
      { name = cfg.user;
        group = cfg.group;
        uid = config.ids.uids.openldap;
      };

    users.extraGroups.openldap =
      { name = cfg.group;
        gid = config.ids.gids.openldap;
      };

  };
}

{ config, lib, pkgs, ... }:

let
  cfg = config.services.glauth;

  settingsFormat = pkgs.formats.toml { };
  configFile = settingsFormat.generate "config.toml" cfg.settings;
in
{
  options.services.glauth = {
    enable = lib.mkEnableOption (lib.mdDoc "glauth, a lightweight LDAP server for development, home use, or CI");

    # TODO: TOML configuration isn't the only way -- glauth can also pull
    # config from S3 and a few relational databases. Perhaps allow settings to
    # be URL (string) or attrset, and only if attrset convert to filepath?
    settings = lib.mkOption {
      type = settingsFormat.type;
      default = {};
      description = lib.mdDoc "TODO";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = lib.mdDoc "TODO";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.glauth = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${lib.getExe pkgs.glauth} -c ${configFile} ${lib.escapeShellArgs cfg.extraArgs}";
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        Restart = "on-failure";
      };
    };
  };
}

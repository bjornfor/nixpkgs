{ config, lib, pkgs, ... }:

with lib;

let

  uid = config.ids.uids.gpsd;
  gid = config.ids.gids.gpsd;
  cfg = config.services.gpsd;

in

{

  ###### interface

  options = {

    services.gpsd = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable `gpsd', a GPS service daemon.
        '';
      };

      device = mkOption {
        type = types.str;
        default = "";
        example = "/dev/ttyUSB0";
        description = ''
          If you leave this blank, we'll activate gpsd hotplug support. The
          hotplug scripts do the right thing when a USB device goes active,
          launching gpsd if needed and telling gpsd which device to read data
          from. Then, gpsd deduces a baud rate and GPS/AIS type by looking at
          the data stream.

          If you don't want hotplug:

          A device may be a local serial device for GPS input, or a URL of the form:
          <literal>{dgpsip|ntrip}://[user:passwd@]host[:port][/stream]</literal>
          <literal>gpsd://host[:port][/device][?protocol]</literal>
          in which case it specifies an input source for GPSD, DGPS or ntrip data.
        '';
      };

      readonly = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable the broken-device-safety, otherwise
          known as read-only mode.  Some popular bluetooth and USB
          receivers lock up or become totally inaccessible when
          probed or reconfigured.  This switch prevents gpsd from
          writing to a receiver.  This means that gpsd cannot
          configure the receiver for optimal performance, but it
          also means that gpsd cannot break the receiver.  A better
          solution would be for Bluetooth to not be so fragile.  A
          platform independent method to identify
          serial-over-Bluetooth devices would also be nice.
        '';
      };

      port = mkOption {
        type = types.uniq types.int;
        default = 2947;
        description = ''
          The port where to listen for TCP connections.
        '';
      };

      debugLevel = mkOption {
        type = types.uniq types.int;
        default = 0;
        description = ''
          The debugging level.
        '';
      };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    services.udev.packages = [ pkgs.gpsd ];

    users.extraUsers = singleton
      { name = "gpsd";
        inherit uid;
        description = "gpsd daemon user";
        home = "/var/empty";
      };

    users.extraGroups = singleton
      { name = "gpsd";
        inherit gid;
      };

    # Inspired by upstream unit files
    systemd.services.gpsd = {
      description = "GPS (Global Positioning System) Daemon";
      requires = [ "gpsd.socket" ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.gpsd}/sbin/gpsd -D "${toString cfg.debugLevel}"  \
            -S "${toString cfg.port}" -N                          \
            ${if cfg.readonly then "-b" else ""}                  \
            ${if cfg.device != "" then cfg.device else "-F /run/gpsd.sock"}
        '';
      };
    };

    systemd.sockets.gpsd = {
      description = "GPS (Global Positioning System) Daemon Sockets";
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = [ "/run/gpsd.sock" "127.0.0.1:${toString cfg.port}" ];
        SocketMode = "0600";
      };
    };

  };

}

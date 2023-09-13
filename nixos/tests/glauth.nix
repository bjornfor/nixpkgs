import ./make-test-python.nix {
  name = "glauth";

  nodes.machine = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [ openldap ];

    services.glauth = {
      enable = true;

      settings = {
        debug = true;
        ldap = {
          enabled = true;
          listen = "0.0.0.0:389";
        };
        # TODO: can we remove ldaps?
        ldaps = {
          enabled = false;
        };
        backend = {
          datastore = "config";
          baseDN = "dc=example,dc=com";
          nameformat = "cn";
          groupformat = "ou";
        };
        users = [
          {
            name = "hackers";
            uidnumber = 5001;
            primarygroup = 5501;
            # to create a passSHA256: echo -n "mysecret" | openssl dgst -sha256
            passsha256 = "6478579e37aff45f013e14eeb30b3cc56c72ccdc310123bcdf53e0333e3f416a"; # dogood
            # TODO: How to map this?
            # [[users.customattributes]];
            # employeetype = ["Intern", "Temp"];
            # employeenumber = [12345, 54321];
            # [[users.capabilities]];
            action = "search";
            object = "ou=superheros,dc=example,dc=com";
          }
        ];
        groups = [
          { name = "superheros";
            gidnumber = 5501;
          }
          { name = "svcaccts";
            gidnumber = 5502;
          }
          { name = "vpn";
            gidnumber = 5503;
            includegroups = [ 5501 ];
          }
        ];
        api = {
          enabled = true;
          tls = false; # enable TLS for production!!
          listen = "0.0.0.0:5555";
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("glauth.service")

    with subtest("API is up"):
        machine.succeed("curl -sfL --head http://localhost:5555")

    # TODO: test ldapsearch?
    # TODO: test login from a client machine?
  '';
}

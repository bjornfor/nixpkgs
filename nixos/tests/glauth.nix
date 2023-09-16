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
          #nameformat = "cn";
          #groupformat = "ou";
        };
        users = [
          {
            name = "hackers";
            uidnumber = 5001;
            primarygroup = 5501;
            # to create a passSHA256: echo -n "mysecret" | openssl dgst -sha256
            passsha256 = "6478579e37aff45f013e14eeb30b3cc56c72ccdc310123bcdf53e0333e3f416a"; # dogood
            capabilities = [
              { action = "search";
                #object = "ou=superheros,dc=example,dc=com";
                object = "*";
              }
            ];
          }
          {
            name = "johndoe";
            givenname = "John";
            sn = "Doe";
            mail = "jdoe@example.com";
            uidnumber = 5002;
            primarygroup = 5501;
            loginShell = "/bin/sh";
            homeDir = "/root";
            passsha256 = "6478579e37aff45f013e14eeb30b3cc56c72ccdc310123bcdf53e0333e3f416a"; # dogood
            sshkeys = ["ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA3UKCEllO2IZXgqNygiVb+dDLJJwVw3AJwV34t2jzR+/tUNVeJ9XddKpYQektNHsFmY93lJw5QDSbeH/mAC4KPoUM47EriINKEelRbyG4hC/ko/e2JWqEclPS9LP7GtqGmscXXo4JFkqnKw4TIRD52XI9n1syYM9Y8rJ88fjC/Lpn+01AB0paLVIfppJU35t0Ho9doHAEfEvcQA6tcm7FLJUvklAxc8WUbdziczbRV40KzDroIkXAZRjX7vXXhh/p7XBYnA0GO8oTa2VY4dTQSeDAUJSUxbzevbL0ll9Gi1uYaTDQyE5gbn2NfJSqq0OYA+3eyGtIVjFYZgi+txSuhw== rsa-key-20160209"];
            passappsha256 = [
              "c32255dbf6fd6b64883ec8801f793bccfa2a860f2b1ae1315cd95cdac1338efa" # TestAppPw1
              "c9853d5f2599e90497e9f8cc671bd2022b0fb5d1bd7cfff92f079e8f8f02b8d3" # TestAppPw2
              "4939efa7c87095dacb5e7e8b8cfb3a660fa1f5edcc9108f6d7ec20ea4d6b3a88" # TestAppPw3
            ];
          }
          {
            name = "serviceuser";
            mail = "serviceuser@example.com";
            uidnumber = 5003;
            primarygroup = 5502;
            passsha256 = "652c7dc687d98c9889304ed2e408c74b611e86a40caa51c4b43f1dd5913c5cd0"; # mysecret
            capabilities = [
              {
                action = "search";
                object = "*";
              }
            ];
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

    with subtest("ldapsearch"):
        machine.succeed("ldapsearch -LLL -H ldap://localhost:389 -D cn=hackers,ou=superheros,dc=example,dc=com -w dogood -x -bou=groups,dc=example,dc=com '(&(objectClass=*)(memberOf=ou=superheros,ou=groups,dc=example,dc=com))'")

    # TODO: test login from a client machine?
  '';
}

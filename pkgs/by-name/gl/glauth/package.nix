{ lib
, stdenv
, fetchFromGitHub
, buildGoModule
, oath-toolkit
, openldap
, libressl
, iproute2
}:

let
  # Patch to fix this fatal error from `go mod vendor`:
  # go: replacement path ./vendored/toml inside vendor directory
  mkVendorPatchSnippet = dir:
    ''
      mv ${dir}/vendored ${dir}/_vendored
      pattern='replace github.com/hydronica/toml => ./vendored/toml'
      replace='replace github.com/hydronica/toml => ./_vendored/toml'
      if grep -q "$pattern" ${dir}/go.mod; then
          sed -e "s,$pattern,$replace," -i ${dir}/go.mod
      else
          echo "error: couldn't find \"$pattern\" in ${dir}/go.mod -- please update Nix expr" >&2
          exit 1
      fi
  '';
in
buildGoModule rec {
  pname = "glauth";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "glauth";
    repo = "glauth";
    rev = "v${version}";
    hash = "sha256-sQEfDwgqHi+6LQhUxA5RO0hwzB9loTncrOyP8SXatok=";
  };

  vendorHash = "sha256-Gh9kOaTpcULE3i+EvNW2i6HDfchokrbO9t5mmsekV9g=";

  modRoot = "v2";

  overrideModAttrs = old: {
    postPatch = (old.postPatch or "") + (mkVendorPatchSnippet ".");
  };

  #postPatch = mkVendorPatchSnippet modRoot;

  # Fix running tests in the sandbox by only listening to the loopback
  # interface. FIXME: was it really needed?
  postPatch = (mkVendorPatchSnippet modRoot) + ''
    #sed -e "s/0.0.0.0/127.0.0.1/" -i ${modRoot}/sample-simple.cfg

    patchShebangs ${modRoot}/scripts
  '';

  # Based on ldflags in <glauth>/Makefile.
  ldflags = [
    "-s"
    "-w"
    "-X main.GitClean=1"
    "-X main.LastGitTag=v${version}"
    "-X main.GitTagIsCommit=1"
  ];

  # TODO: Tests require openldap and listening to LDAP ports.
  doCheck = false;

  nativeCheckInputs = [
    oath-toolkit
    openldap

    libressl.nc
    iproute2

    #breakpointHook
  ];

  # Test that we can listen on the loopback interface
  #preBuild = ''
  #  ip addr
  #  nc -l 0.0.0.0 3003 &
  #  echo hello-loopback-test | nc -N 0.0.0.0 3003
  #  wait
  #'';

  # The test script assumes glauth exists where the Makefile put it, but we
  # didn't build via make. Add compat symlink to get tests to pass.
  #preCheck = ''
  #  set -x
  #  find -name glauth
  #  set +x
  #'';

  #checkPhase = ''
  #  find -name glauth
  #  false
  #'';

  # Disable go workspaces to fix build.
  GOWORK = "off";

  meta = with lib; {
    description = "A lightweight LDAP server for development, home use, or CI";
    homepage = "https://github.com/glauth/glauth";
    license = licenses.mit;
    maintainers = with maintainers; [ bjornfor ];
    mainProgram = "glauth";
  };
}

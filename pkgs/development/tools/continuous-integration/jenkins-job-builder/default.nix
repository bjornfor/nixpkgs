{ stdenv, fetchurl, pythonPackages, buildPythonPackage, git }:

let
  upstreamName = "jenkins-job-builder";
  version = "1.3.0";

in

buildPythonPackage rec {
  name = "${upstreamName}-${version}";
  namePrefix = "";  # Don't prepend "pythonX.Y-" to the name

  src = fetchurl {
    url = "https://pypi.python.org/packages/source/j/${upstreamName}/${name}.tar.gz";
    sha256 = "111vpf6hzzb2mcdqi0a9r1dkf28ln9w6sgfqri0qxwf1ffbdqx6x";
  };

  pythonPath = with pythonPackages; [ pip six pyyaml pbr python-jenkins mock
    sphinxcontrib-programoutput testrepository
  ];

  meta = {
    description = "System for configuring Jenkins jobs using simple YAML files";
    homepage = http://ci.openstack.org/jjb.html;
    license = stdenv.lib.licenses.asl20;
  };
}

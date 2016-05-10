{ stdenv, fetchurl, perl, cudatoolkit }:

let
  bits = if stdenv.system == "x86_64-linux" then "64" else "32";
in
stdenv.mkDerivation rec {
  name = "oclhashcat-${version}";
  version = "2.01";

  src = fetchurl {
    name = "${name}.tar.gz";
    url = "https://codeload.github.com/hashcat/oclHashcat/tar.gz/v${version}";
    sha256 = "01wzbci50rafamggl94zab64nzfc77rh3jh60c1gc60pxzhf93sn";
  };

  buildInputs = [ perl cudatoolkit ];

  preBuild = ''
    export GCC=gcc
    export CUDA=${cudatoolkit}
  '';

  buildFlags = [ "linux${bits}" "rules_optimize" "kernels_all" ];
  #configureFlags = "--help"; 

  meta = with stdenv.lib; {
    description = "Fast GPGPU-based password cracker";
    homepage  = "http://hashcat.net/oclhashcat/";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ bjornfor ];
  };
}

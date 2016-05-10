{ stdenv, fetchzip, perl, cudatoolkit }:

let
  bits = if stdenv.system == "x86_64-linux" then "64" else "32";
in
stdenv.mkDerivation rec {
  name = "oclhashcat-${version}";
  version = "2016-05-11";

  src = fetchzip {
    name = "${name}-src";
    url = "https://github.com/hashcat/oclHashcat/archive/aefd3b03a38a56a822d4f64fb5a0e25df85c5b02.zip";
    sha256 = "0imk5b3bbnvh4mc59rnkhw9wcafxwz1pcv7vqcpa1g7i5nzcrb5x";
  };

  buildInputs = [ perl cudatoolkit ];

  ### Old stuff from 'hashcat' (not oclhashcat)
  #preBuild = ''
  #  export GCC=gcc
  #  export CUDA=${cudatoolkit}
  #'';
  #buildFlags = [ "linux${bits}" "rules_optimize" "kernels_all" ];
  #configureFlags = "--help"; 

  makeFlags = [ "PREFIX=$(out)" ];
  preInstall = ''
    mkdir -p "$out/bin"
  '';

  meta = with stdenv.lib; {
    description = "Fast GPGPU-based password cracker";
    homepage  = "http://hashcat.net/oclhashcat/";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ bjornfor ];
  };
}

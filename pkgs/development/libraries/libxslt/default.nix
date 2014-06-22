{ stdenv, fetchurl, libxml2 }:

let
  commonConfigureFlags = [
    "--without-python"
    "--without-crypto"
    "--without-debug"
    "--without-mem-debug"
    "--without-debugger"
  ];
in

stdenv.mkDerivation rec {
  name = "libxslt-1.1.28";

  src = fetchurl {
    url = "ftp://xmlsoft.org/libxml2/${name}.tar.gz";
    sha256 = "13029baw9kkyjgr7q3jccw2mz38amq7mmpr5p3bh775qawd1bisz";
  };

  buildInputs = [ libxml2 ];

  patches = stdenv.lib.optionals stdenv.isSunOS [ ./patch-ah.patch ];

  configureFlags = commonConfigureFlags ++ [
    "--with-libxml-prefix=${libxml2}"
  ];

  postInstall = ''
    mkdir -p $out/nix-support
    ln -s ${libxml2}/nix-support/setup-hook $out/nix-support/
  '';

  crossAttrs = {
    configureFlags = commonConfigureFlags ++ [
      "--with-libxml-prefix=${libxml2.crossDrv}"
    ];
  };

  meta = {
    homepage = http://xmlsoft.org/XSLT/;
    description = "A C library and tools to do XSL transformations";
    license = "bsd";
    platforms = stdenv.lib.platforms.unix;
    maintainers = [ stdenv.lib.maintainers.eelco ];
  };
}

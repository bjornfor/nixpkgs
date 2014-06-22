{ stdenv, fetchurl, libxml2, findXMLCatalogs }:

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
    url = "http://xmlsoft.org/sources/${name}.tar.gz";
    sha256 = "13029baw9kkyjgr7q3jccw2mz38amq7mmpr5p3bh775qawd1bisz";
  };

  outputs = [ "out" "doc" ];

  buildInputs = [ libxml2 ];

  propagatedBuildInputs = [ findXMLCatalogs ];

  patches = stdenv.lib.optionals stdenv.isSunOS [ ./patch-ah.patch ];

  configureFlags = commonConfigureFlags ++ [
    "--with-libxml-prefix=${libxml2}"
  ];

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

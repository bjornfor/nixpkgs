{ stdenv, fetchurl, pkgconfig, kmod
, enableDocumentation ? false, asciidoc
}:

stdenv.mkDerivation rec {
  name = "dracut-${version}";
  version = "046";

  src = fetchurl {
    url = "https://git.kernel.org/pub/scm/boot/dracut/dracut.git/snapshot/${name}.tar.gz";
    sha256 = "1irpwmpz8vl3k2q10d4vp59k5fs9f88gbgriy2cwyap9n6lmidi8";
  };

  # TODO: add patch description
  patches = [ ./path.patch ];

  buildInputs = [ pkgconfig kmod ]
    ++ stdenv.lib.optional enableDocumentation [ asciidoc ];

  preConfigure = ''
    patchShebangs configure
    substituteInPlace dracut.sh --replace @libdir@ $out/lib
    makeFlagsArray+=(prefix="$out")
  '';

  makeFlags = [ ]
    ++ stdenv.lib.optional (!enableDocumentation) [ "enable_documentation=no" ];

  # TODO:
  # meta = with stdenv.lib; {
  # };
}

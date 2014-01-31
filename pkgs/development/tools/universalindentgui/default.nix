{ stdenv, fetchurl, qt4 /*, qscintilla2*/ }:

# TODO: fix build

stdenv.mkDerivation rec {
  name = "universalindentgui-1.2.0";

  src = fetchurl {
    url = "mirror://sourceforge/universalindent/${name}.tar.gz";
    sha256 = "0f43x5q3vbw7f042587hlcr1pgz5rbphr2hi472q044mid9xba3q";
  };

  buildInputs = [ qt4 ];

  configurePhase = "qmake";

  meta = with stdenv.lib; {
    description = "TODO";
    homepage = http://universalindent.sourceforge.net/;
    license = licenses.gpl2;
    maintainers = [ maintainers.bjornfor ];
    platforms = platforms.linux;
  };
}

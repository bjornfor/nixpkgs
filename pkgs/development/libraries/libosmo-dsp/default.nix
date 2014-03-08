{ stdenv, fetchgit, autoreconfHook, pkgconfig, fftwFloat }:

stdenv.mkDerivation rec {
  name = "libosmo-dsp-${version}";
  version = "0.3";

  src = fetchgit {
    url = "git://git.osmocom.org/libosmo-dsp";
    rev = "refs/tags/v${version}";
    sha256 = "15m3izhhh9viim77zb45yxaf0p95yz93mxxhji0pzkxkp44frvkq";
  };

  buildInputs = [ autoreconfHook pkgconfig fftwFloat ];

#  meta = with stdenv.lib; {
#    description = "TODO";
#    homepage = TODO;
#    license = licenses.TODO;
#    platforms = platforms.linux;
#    maintainers = [ maintainers.bjornfor ];
#  };
}

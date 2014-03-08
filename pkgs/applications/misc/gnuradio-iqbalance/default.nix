{ stdenv, fetchgit, cmake, pkgconfig, boost, gnuradio, fftwFloat, python, swig
, libosmo-dsp
}:

# FIXME: Fails to build, maybe because a C++ compiler is used to build a C
# "float complex *data;" snippet, and 'complex' is invalid in C++?

stdenv.mkDerivation rec {
  name = "gnuradio-iqbalance-${version}";
  version = "0.37.1";

  src = fetchgit {
    url = "git://git.osmocom.org/gr-iqbal";
    rev = "refs/tags/v${version}";
    sha256 = "0z5dkv9pbdagnbs9sij1094yvk0415912kj7qnjbm223771jv136";
  };

  buildInputs = [
    cmake pkgconfig boost gnuradio fftwFloat python swig libosmo-dsp
  ];

  meta = with stdenv.lib; {
    description = "Gnuradio I/Q balancing";
    homepage = http://cgit.osmocom.org/gr-iqbal/;
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}

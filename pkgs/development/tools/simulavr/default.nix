{ stdenv, fetchurl, python, tcl, avrgcclibc }:

stdenv.mkDerivation rec {
  name = "simulavr-1.0.0";

  src = fetchurl {
    url = "http://download.savannah.nongnu.org/releases/simulavr/${name}.tar.gz";
    sha256 = "1rwvh23rzj84pfz2lanivmm3dm5liyjdcbb8bzhvxqpa7sm3zn9r";
  };

  buildInputs = [ python tcl avrgcclibc ];

  # TODO: binutils-avr (for libbfd)

  #configureFlags = "--help";

  meta = with stdenv.lib; {
    description = "Simulator for Atmel AVR microcontrollers";
    homepage = http://www.nongnu.org/simulavr/;
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}

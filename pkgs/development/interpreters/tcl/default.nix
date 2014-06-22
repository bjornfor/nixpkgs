{ stdenv, fetchurl }:

stdenv.mkDerivation {
  name = "tcl-8.5.15";

  src = fetchurl {
    url = mirror://sourceforge/tcl/tcl8.5.15-src.tar.gz;
    sha256 = "0kl8lbfwy4v4q4461wjmva95h0pgiprykislpw4nnpkrc7jalkpj";
  };

  preConfigure = "cd unix";

  postInstall = ''
    make install-private-headers
    ln -s $out/bin/tclsh8.5 $out/bin/tclsh
  '';

  crossAttrs = {
    # Tcl configure script makes some pessimistic assumptions when
    # cross-compiling (when AC_TRY_RUN can't run). One of them is guessing
    # libc has no strtod when small test program can't be run. Some AC_TRY_RUN
    # should actually be replaced by AC_TRY_LINK to provide better estimate.
    # Work around this by forcing configure detection.
    configureFlags = "ac_cv_func_strtod=yes tcl_cv_strtod_buggy=1";
  };
  
  meta = {
    description = "The Tcl scription language";
    homepage = http://www.tcl.tk/;
    license = stdenv.lib.licenses.tcltk;
  };
  
  passthru = {
    libdir = "lib/tcl8.5";
  };
}

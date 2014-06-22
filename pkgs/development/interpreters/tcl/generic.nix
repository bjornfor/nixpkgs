{ stdenv, fetchurl

# Version specific stuff
, release, version, src
, ...
}:

stdenv.mkDerivation rec {
  name = "tcl-${version}";

  inherit src;

  preConfigure = ''
    cd unix
  '';

  postInstall = ''
    make install-private-headers
    ln -s $out/bin/tclsh${release} $out/bin/tclsh
  '';
  
  crossAttrs = {
    # Tcl configure script makes some pessimistic assumptions when
    # cross-compiling (when AC_TRY_RUN can't run). One of them is guessing
    # libc has no strtod when small test program can't be run. Some AC_TRY_RUN
    # should actually be replaced by AC_TRY_LINK to provide better estimate.
    # Work around this by forcing configure detection.
    configureFlags = "ac_cv_func_strtod=yes tcl_cv_strtod_buggy=1";
  };

  meta = with stdenv.lib; {
    description = "The Tcl scription language";
    homepage = http://www.tcl.tk/;
    license = licenses.tcltk;
    platforms = platforms.all;
    maintainers = with maintainers; [ wkennington ];
  };
  
  passthru = rec {
    inherit release version;
    libPrefix = "tcl${release}";
    libdir = "lib/${libPrefix}";
  };
}

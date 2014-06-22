{ stdenv, fetchurl, tcl, autoconf }:

let version = "5.45";
in
stdenv.mkDerivation {
  name = "expect-${version}";

  src = fetchurl {
    url = "mirror://sourceforge/expect/Expect/${version}/expect${version}.tar.gz";
    sha256 = "0h60bifxj876afz4im35rmnbnxjx4lbdqp2ja3k30fwa8a8cm3dj";
  };

  buildInputs = [ tcl ];

  #NIX_CFLAGS_COMPILE = "-DHAVE_UNISTD_H";

  # http://wiki.linuxfromscratch.org/lfs/ticket/2126
  #preBuild = ''
  #  substituteInPlace exp_inter.c --replace tcl.h tclInt.h
  #'';

  postPatch = ''
    substituteInPlace configure --replace /bin/stty "$(type -tP stty)"
    sed -e '1i\#include <tclInt.h>' -i exp_inter.c
    export NIX_LDFLAGS="-rpath $out/lib $NIX_LDFLAGS"
  '' + stdenv.lib.optionalString stdenv.isFreeBSD ''
    ln -s libexpect.so.1 libexpect545.so
  '';

  configureFlags = [
    "--with-tcl=${tcl}/lib"
    "--with-tclinclude=${tcl}/include"
    "--exec-prefix=$out"
  ];

  postInstall = let libSuff = if stdenv.isDarwin then "dylib" else "so";
    in "cp expect $out/bin; mkdir -p $out/lib; cp *.${libSuff} $out/lib";

  # Uhm, cross-compilation seems to fail randomly with
  # "checking if WNOHANG requires _POSIX_SOURCE... configure: error: Expect can't be cross compiled"
  # ...as if the below patch isn't applied(!)
  crossAttrs = {
    patches = [
      # From Buildroot.
      # Fixes lots of configure errors: "Expect can't be cross compiled".
      ./expect-enable-cross-compilation.patch
    ];

    # We patched configure.in, must re-generate ./configure
    preConfigure = ''
      ${autoconf}/bin/autoreconf
    '';

    configureFlags = [
      "--with-tcl=${tcl.crossDrv}/lib"
      "--with-tclinclude=${tcl.crossDrv}/include"
      "--exec-prefix=$out"
    ];

    # full "install" tries to run cross-compiled binaries
    installTargets = "install-binaries";
  };

  meta = {
    description = "A tool for automating interactive applications";
    homepage = http://expect.nist.gov/;
  };
}

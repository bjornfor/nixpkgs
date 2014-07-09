{ lib, stdenv, fetchurl, which, file, enableThreading ? true }:

let

  libc = if stdenv.cc.libc or null != null then stdenv.cc.libc else "/usr";

  # perl-cross is an overlay for the perl source tarball that provides a
  # configure/build system that capable of cross-compilation.
  perlCross = fetchurl {
    # GitHub always redirects to HTTPS, which isn't available in fetchurlBoot.
    # Find another mirror, or do some extra bootstrapping; if we're
    # cross-compiling perl we have already built a full fetchurl with SSL
    # support.
    url = "https://github.com/arsv/perl-cross/raw/releases/perl-5.16.3-cross-0.7.4.tar.gz";
    sha256 = "1jc7fpdknbblirdc8x2cnb1ka795hlwvvmp5s5ads07jvabjriis";
  };

in

stdenv.mkDerivation rec {
  name = "perl-5.16.3";

  src = fetchurl {
    url = "mirror://cpan/src/${name}.tar.gz";
    sha256 = "1dpd9lhc4723wmsn4dsn4m320qlqgyw28bvcbhnfqp2nl3f0ikv9";
  };

  patches =
    [ # Do not look in /usr etc. for dependencies.
      ./no-sys-dirs.patch
      ./no-impure-config-time.patch
      ./fixed-man-page-date.patch
      ./no-date-in-perl-binary.patch
    ]
    ++ lib.optional stdenv.isSunOS  ./ld-shared.patch
    ++ lib.optional stdenv.isDarwin [ ./cpp-precomp.patch ./no-libutil.patch ] ;

  # There's an annoying bug on sandboxed Darwin in Perl's Cwd.pm where it looks for pwd
  # in /bin/pwd and /usr/bin/pwd and then falls back on just "pwd" if it can't get them
  # while at the same time erasing the PATH environment variable so it unconditionally
  # fails. The code in question is guarded by a check for Mac OS, but the patch below
  # doesn't have any runtime effect on other platforms.
  postPatch = ''
    pwd="$(type -P pwd)"
    substituteInPlace dist/Cwd/Cwd.pm \
      --replace "pwd_cmd = 'pwd'" "pwd_cmd = '$pwd'"
  '';

  # Build a thread-safe Perl with a dynamic libperls.o.  We need the
  # "installstyle" option to ensure that modules are put under
  # $out/lib/perl5 - this is the general default, but because $out
  # contains the string "perl", Configure would select $out/lib.
  # Miniperl needs -lm. perl needs -lrt.
  configureFlags =
    [ "-de"
      "-Uinstallusrbinperl"
      "-Dinstallstyle=lib/perl5"
      "-Duseshrplib"
      "-Dlocincpth=${libc}/include"
      "-Dloclibpth=${libc}/lib"
    ]
    ++ lib.optional enableThreading "-Dusethreads";

  configureScript = "${stdenv.shell} ./Configure";

  dontAddPrefix = true;

  enableParallelBuilding = true;

  preConfigure =
    ''
      configureFlags="$configureFlags -Dprefix=$out -Dman1dir=$out/share/man/man1 -Dman3dir=$out/share/man/man3"

      ${lib.optionalString stdenv.isArm ''
        configureFlagsArray=(-Dldflags="-lm -lrt")
      ''}

      ${lib.optionalString stdenv.isCygwin ''
        cp cygwin/cygwin.c{,.bak}
        echo "#define PERLIO_NOT_STDIO 0" > tmp
        cat tmp cygwin/cygwin.c.bak > cygwin/cygwin.c
      ''}
    '';

  preBuild = lib.optionalString (!(stdenv ? cc && stdenv.cc.nativeTools))
    ''
      # Make Cwd work on NixOS (where we don't have a /bin/pwd).
      substituteInPlace dist/Cwd/Cwd.pm --replace "'/bin/pwd'" "'$(type -tP pwd)'"
    '';

  setupHook = ./setup-hook.sh;

  passthru.libPrefix = "lib/perl5/site_perl";

  crossAttrs = {

    buildInputs = [ which file ];  # perl-cross fails in mysterious ways without 'which'

    postUnpack = ''
      echo "Applying perl-cross overlay..."
      tar xvf "${perlCross}" --strip-components=1 -C perl-*
      patchShebangs .
    '';

    configurePhase = ''
      ./configure --target=${stdenv.cross.config} --prefix="$out"
      # Configure options from Buildroot
      #  -Dmydomain="" \
      #  -Dmyhostname="nixpkgs" \
      #  -Dmyuname="nixpkgs full-version-number" \
      #  -Dosname=linux \
      #  -Dosvers=$(LINUX_VERSION) \
      #  -Dperladmin=root
    '';

#    configureScript = "./configure";
#
#    # FIXME:
#    #   Checking for linker ... none found
#    #   ERROR: no linker found
#    configureFlags =
#      [ "--target=${stdenv.cross.config}"
#        "--target-tools-prefix=${stdenv.cross.config}-"  # buildroot full path and railing dash, perl-cross documentation uses just the target triplet + '-'
#        "--host-cc=gcc"
#        #"--host-ld=ld"  # invalid flag, trying with --build="" to prevent host tools prefix, but doesn't work :/
#        "--host-ar=ar"
#        "--host-ranlib=ranlib"
#        "--host-objdump=objdump"
#
#        "--build="  # no prefix for host tools (DOESN'T WORK!)
#
#        #"-Uinstallusrbinperl"
#        #"-Dinstallstyle=lib/perl5"
#        #"-Duseshrplib"
#        #"-Dlocincpth=${libc}/include"
#        #"-Dloclibpth=${libc}/lib"
#      ] ++ optional (stdenv ? glibc) "-Dusethreads";
  };
}

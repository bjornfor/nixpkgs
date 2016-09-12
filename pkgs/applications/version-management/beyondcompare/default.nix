{ stdenv, fetchurl, dpkg, bash, zlib, bzip2, libX11, qt4 }:

assert stdenv.system == "i686-linux" || stdenv.system == "x86_64-linux";

let
  # Use the original / non-autoconfiscated bzip2 package, because the other
  # version has incompatible soname. I tried messing with "patchelf
  # --replace-needed ...", but the result was segfault.
  bzip2_orig =
    stdenv.mkDerivation rec {
      name = "bzip2-${version}";
      version = "1.0.6";
      src = fetchurl {
        url = http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz;
        sha256 = "1kfrc7f0ja9fdn6j1y6yir6li818npy6217hvr3wzmnmzhs8z152";
      };
      # Hmm, what to do with this?
      #patches = [
      #  ./CVE-2016-3189.patch
      #];
      postPatch = ''
        sed -i -e '/<sys\\stat\.h>/s|\\|/|' bzip2.c
      '';
      buildFlags = [ "-f" "Makefile-libbz2_so" ];
      installFlags = [ "PREFIX=$(out)" ];
      postInstall = ''
        cp *.so* "$out/lib"
      '';
    };

  libPath = stdenv.lib.makeLibraryPath [ zlib bzip2_orig libX11 stdenv.cc.cc.lib qt4 ];
in

stdenv.mkDerivation rec {
  name = "beyondcompare-${version}";
  version = "4.1.9.21719";

  src = fetchurl {
    # TODO: 32-bit
    url = "http://www.scootersoftware.com/bcompare-${version}_amd64.deb";
    sha256 = "0m6kz6rxp3fczy0z41ii28ghw0baga0yljmi4s35m9b2nahc2ddf";
  };

  buildInputs = [ dpkg ];

  unpackPhase = "dpkg -x ${src} ./";

  installPhase = ''
    mkdir -p "$out/bin"

    cp -r usr/* "$out"

    substituteInPlace "$out/bin/bcompare" \
        --replace BC_LIB=/usr/lib "BC_LIB=$out/lib" \
        --replace /bin/bash "${bash}/bin/bash"

    # "patchelf --set-rpath" cause breakage:
    #
    #   ./result/lib/beyondcompare/BCompare: no version information available (required by ./result/lib/beyondcompare/BCompare)
    #
    # Using LD_LIBRARY_PATH instead.

    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        "$out/lib/beyondcompare/BCompare"

    sed -e "2i export LD_LIBRARY_PATH=${libPath}" -i "$out/bin/bcompare"

    # It requires "libbz2.so.1.0" whereas our version has an extra ".6" at the
    # end. Fix it.
    # FIXME: It causes segfault.
    #patchelf --replace-needed libbz2.so.1.0 libbz2.so.1.0.6 "$out"/lib/beyondcompare/BCompare
  '';

  #meta = ...
}

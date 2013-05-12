{ stdenv, fetchurl, mono, libgdiplus, libX11, mesa, patchelf }:  # for building binary distribution
#{ stdenv, fetchgit, mono, libgdiplus, pkgconfig, patchelf, opentk }:  # for building from source

# NOTE: We use the binary distribution of Repetier-Host until someone figures
# out how to build it from source.

stdenv.mkDerivation rec {
  version = "0.85c";
  name = "repetier-host-${version}";

  src = fetchurl {
    name = "${name}.tar.gz";
    url = "http://www.repetier.com/?wpdmact=process&did=MzUuaG90bGluaw==";
    sha256 = "1ny22lf9s3yb9bhx9gdxkflvz6q62crzpvza1x449nr6dc2c9w42";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/repetier-host
    cp -r . $out/repetier-host

    pwd
    ls -l

    # Make a wrapper that invokes Mono + Repetier-Host
    cat > $out/bin/repetier-host << EOF
    #!${stdenv.shell}
    #export LD_LIBRARY_PATH=${libgdiplus}/lib:${libX11}/lib
    export LD_LIBRARY_PATH=${libX11}/lib:${mesa}/lib
    ${mono}/bin/mono $out/repetier-host/RepetierHost.exe
    EOF
    chmod a+x $out/bin/repetier-host
  '';

  ## TODO: Build from source
  #
  ## Repetier-Host doesn't seem to put out tarballs, only git is available
  #src = fetchgit {
  #  url = "git://github.com/repetier/Repetier-Host.git";
  #  rev = "refs/tags/v${version}";
  #  #sha256 = "0sjjj9z1dhilhpc8pq4154czrb79z9cm044jvn75kxcjv6v5l2m5";
  #  #rev = "05c108534abf10dc2e70258bf960c04047312328";
  #  sha256 = "1d38ax4szhjvppymgkbk9x1778w130r9ffgksq8pms4j2xd6z0dw";
  #};
  #
  #buildInputs = [ mono libgdiplus pkgconfig opentk ];
  #
  #buildPhase = ''
  #  export LD_LIBRARY_PATH=${libgdiplus}/lib
  #  # Become case insensitive and map unix/win path separators:
  #  export MONO_IOMAP=all
  #  #echo "MONO_PATH from env: $(env | grep MONO_PATH)"
  #  export MONO_PATH=${opentk}/lib
  #  #export PKG_CONFIG_PATH=${opentk}/lib/pkgconfig
  #  export XBUILD_LOG_REFERENCE_RESOLVER=1
  #  xbuild /verbosity:detailed src/RepetierHost/RepetierHost.sln
  #'';
  #
  #doCheck = false;

  # stripping is supposed to break all mono stuff (is it true?)
  #dontStrip = true;

  #postFixup = ''
    #${patchelf}/bin/patchelf
  #'';

  meta = {
    description = "Software for controlling 3D printers";
    longDescription = ''
      Software for controlling RepRap style 3D-printer like Mendel, Darwin or
      Prusa mendel. Works with most firmware types. It is optimized to work
      with Repetier-Firmware Other working firmware is Sprinter, Teacup, Marlin
      and all compatible firmwares.
    '';
    homepage = http://www.repetier.com/;
    license = stdenv.lib.licenses.asl20;
  };
}

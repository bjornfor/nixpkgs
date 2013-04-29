{ stdenv, fetchgit, mono, libgdiplus, pkgconfig, patchelf, opentk }:
# gtksharp, pkgconfig

stdenv.mkDerivation rec {
  version = "0.85";
  name = "repetier-host-${version}";

  # Repetier-Host doesn't seem to put out tarballs, only git is available
  src = fetchgit {
    url = "git://github.com/repetier/Repetier-Host.git";
    #rev = "refs/tags/v${version}";
    #sha256 = "0sjjj9z1dhilhpc8pq4154czrb79z9cm044jvn75kxcjv6v5l2m5";
    rev = "05c108534abf10dc2e70258bf960c04047312328";
    sha256 = "1d38ax4szhjvppymgkbk9x1778w130r9ffgksq8pms4j2xd6z0dw";
  };

  buildInputs = [ mono libgdiplus pkgconfig opentk ];

  buildPhase = ''
    export LD_LIBRARY_PATH=${libgdiplus}/lib
    # Become case insensitive and map unix/win path separators:
    export MONO_IOMAP=all
    xbuild src/RepetierHost/RepetierHost.sln
  '';

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

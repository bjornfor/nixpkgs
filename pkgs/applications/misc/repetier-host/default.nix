{ stdenv, fetchurl, mono, libgdiplus, libX11, mesa, perl }:

# NOTE: We use the binary distribution of Repetier-Host until someone figures
# out how to build it from source.

stdenv.mkDerivation rec {
  version = "0.90c";
  name = "repetier-host-${version}";

  src = fetchurl {
    name = "${name}.tar.gz";
    url = "http://www.repetier.com/?wpdmact=process&did=NDAuaG90bGluaw==";
    sha256 = "1a008bsf2yprf8jchwrw4ag1a7vlw2d6mc7jyyb314ni48lffbpa";
  };

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p "$out/bin"
    mkdir -p "$out/repetier-host"
    cp -r . "$out/repetier-host"

    # Make a wrapper that invokes Mono + Repetier-Host
    cat > "$out/bin/repetier-host" << EOF
    #!${stdenv.shell}
    export PATH=\$PATH:${perl}/bin
    export LD_LIBRARY_PATH=${libX11}/lib:${libgdiplus}/lib:${mesa}/lib:${mono}/lib
    ${mono}/bin/mono $out/repetier-host/RepetierHost.exe
    EOF
    chmod a+x $out/bin/repetier-host
  '';

  meta = with stdenv.lib; {
    description = "Software for controlling 3D printers";
    longDescription = ''
      Software for controlling RepRap style 3D-printer like Mendel, Darwin or
      Prusa mendel. Works with most firmware types. It is optimized to work
      with Repetier-Firmware Other working firmware is Sprinter, Teacup, Marlin
      and all compatible firmwares.
    '';
    homepage = http://www.repetier.com/;
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}

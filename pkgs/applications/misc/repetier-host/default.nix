{ stdenv, fetchurl, bash, mono, makeDesktopItem }:

stdenv.mkDerivation rec {
  name = "repetier-host-1.5.4";

  src = fetchurl {
    url = "http://download.repetier.com/files/host/linux/repetierHostLinux_1_5_4.tgz";
    sha256 = "08j35n6d01gkfn6xy5j46cdlxa1yxqhmg0zjxbg9h43rgml01can";
  };

  desktopItem = makeDesktopItem {
    name = "repetier-host";
    exec = "repetierHost";
    icon = "repetier-logo";
    comment = "Repetier-Host 3d printer host software";
    desktopName = "Repetier-Host";
    genericName = "3d printer host software";
    categories = "Application;Development;";
  };

  installPhase = ''
    mkdir -p "$out/bin"
    mkdir -p "$out/repetier-host"
    mkdir -p "$out/share/applications"
    mkdir -p "$out/share/icons"

    cp -r . "$out/repetier-host"

    cp "${desktopItem}/share/applications/"* "$out/share/applications/"
    ln -sr "$out/repetier-host/repetier-logo.png" "$out/share/icons/"

    # repetier developers wants the binary to be named 'repetierHost'
    cat > "$out/bin/repetierHost" << __EOF__
    #!${bash}/bin/bash
    exec ${mono}/bin/mono "$out"/repetier-host/RepetierHost.exe -home "$out"
    __EOF__
    chmod a+x "$out/bin/"*
  '';

  meta = with stdenv.lib; {
    description = "3D printer host software";
    homepage = http://www.repetier.com/;
    license = licenses.unfree;
    # Available for other platforms, but this binary package is linux only.
    platforms = platforms.linux;
  };
}

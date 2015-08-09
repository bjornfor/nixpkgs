#with import <nixpkgs> {};
with import /home/bfo/code/forks/nixpkgs {};

#{ stdenv, fetchurl, mono, makeDesktopItem }:

stdenv.mkDerivation rec {
  name = "repetier-host-1.0.6";

  src = fetchurl {
    name = "${name}.tgz";
    url = "http://www.repetier.com/w/?wpdmdl=1785";  # no stable url?
    sha256 = "1a24zpf5csidkb4lrdigb5xqkw640cdwgv34i8gxnqzqg8cs3r6f";
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

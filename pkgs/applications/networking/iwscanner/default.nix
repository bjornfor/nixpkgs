{ stdenv, fetchurl, python, pyGtkGlade
#pkgconfig, perl, flex, bison, libpcap, libnl, c-are
#, gnutls, libgcrypt, geoip, heimdal, lua5, gtk, makeDesktopItem, pytho
#, libcap
}:

stdenv.mkDerivation rec {
  name = "iwscanner-0.2.4";

  src = fetchurl {
    url = "http://kuthulu.com/iwscanner/${name}.tgz";
    sha256 = "0gshqb4gszqpkl66axb2w8bb7qcb8508l747hnwxxdlh19hvq0cs";
  };

  propagatedBuildInputs = [
    python pyGtkGlade
    #bison flex perl pkgconfig libpcap lua5 heimdal libgcrypt gnutls
    #geoip libnl c-ares gtk python libcap
  ];

#  desktopItem = makeDesktopItem {
#    name = "Wireshark";
#    exec = "wireshark";
#    icon = "wireshark";
#    comment = "Powerful network protocol analysis suite";
#    desktopName = "Wireshark";
#    genericName = "Network packet analyzer";
#    categories = "Network;System";
#  };
#
#  postInstall = ''
#    mkdir -p "$out"/share/applications/
#    mkdir -p "$out"/share/icons/
#    cp "$desktopItem/share/applications/"* "$out/share/applications/"
#    cp image/wsicon.svg "$out"/share/icons/wireshark.svg
#  '';
#
#  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p "$out/bin"
    mkdir -p "$out/libexec"
    cp iwscanner.py "$out/libexec"
    cat > "$out/bin/iwscanner" << __EOF__
    #!${stdenv.shell}
    export PYTHONPATH="$PYTHONPATH"
    exec ${python.executable} "$out/libexec/iwscanner.py"
    __EOF__
    chmod +x "$out/bin/"*
  '';

  meta = with stdenv.lib; {
    description = "Wireless network (Wi-Fi) scanner with an easy to use graphic interface";
    #longDescription = ''
    #'';
    homepage = http://kuthulu.com/iwscanner/;
    #license = licenses.TODO;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}

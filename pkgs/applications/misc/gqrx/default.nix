{ stdenv, fetchFromGitHub, cmake, qtbase, qtsvg, gnuradio, boost, gnuradio-osmosdr
, lndir
# drivers (optional):
, rtl-sdr, hackrf
, pulseaudioSupport ? true, libpulseaudio
}:

assert pulseaudioSupport -> libpulseaudio != null;

stdenv.mkDerivation rec {
  name = "gqrx-${version}";
  version = "2.6.1";

  src = fetchFromGitHub {
    owner = "csete";
    repo = "gqrx";
    rev = "v${version}";
    sha256 = "0lhma6wqkka007vq4jpxxz0ws9kvg0b5insgfbplqhpb0pp99rc9";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    qtbase qtsvg gnuradio boost gnuradio-osmosdr rtl-sdr hackrf
  ] ++ stdenv.lib.optionals pulseaudioSupport [ libpulseaudio ];

  enableParallelBuilding = true;

  # * Work around broken auto-detection in gqrx
  # * Require Qt Svg module, or else there will be build time failure
  preConfigure = ''
    export GNURADIO_OSMOSDR_DIR="${gnuradio-osmosdr}"

    sed -e "s/\(find_package(Qt5 COMPONENTS Core Network Widgets\)/\1 Svg/" \
        -i CMakeLists.txt
  '';

  postInstall = ''
    mkdir -p "$out/share/applications"
    mkdir -p "$out/share/icons"

    cp ../gqrx.desktop "$out/share/applications/"
    cp ../resources/icons/gqrx.svg "$out/share/icons/"

    # Make qtsvg plugin discoverable for gqrx (Qt) without needing to install
    # it (qtsvg) in a profile. The trick relies on a nixpkgs Qt patch to look
    # for plugins relative to $PATH/bin.
    dst="$out/${qtbase.qtPluginPrefix}"
    mkdir -p "$dst"
    for pkg in "${qtsvg.bin}"; do
        src="$pkg/${qtbase.qtPluginPrefix}"
        if [ -d "$src" ]; then
            "${lndir}/bin/lndir" "$src" "$dst"
        fi
    done
  '';

  meta = with stdenv.lib; {
    description = "Software defined radio (SDR) receiver";
    longDescription = ''
      Gqrx is a software defined radio receiver powered by GNU Radio and the Qt
      GUI toolkit. It can process I/Q data from many types of input devices,
      including Funcube Dongle Pro/Pro+, rtl-sdr, HackRF, and Universal
      Software Radio Peripheral (USRP) devices.
    '';
    homepage = http://gqrx.dk/;
    # Some of the code comes from the Cutesdr project, with a BSD license, but
    # it's currently unknown which version of the BSD license that is.
    license = licenses.gpl3Plus;
    platforms = platforms.linux;  # should work on Darwin / OS X too
    maintainers = with maintainers; [ bjornfor the-kenny fpletz ];
  };
}

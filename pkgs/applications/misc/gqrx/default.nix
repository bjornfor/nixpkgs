{ stdenv, fetchFromGitHub, qmakeHook, qtbase, qtsvg, gnuradio, boost, gnuradio-osmosdr
# drivers (optional):
, rtl-sdr, hackrf
, pulseaudioSupport ? true, libpulseaudio
}:

assert pulseaudioSupport -> libpulseaudio != null;

stdenv.mkDerivation rec {
  name = "gqrx-${version}";
  version = "2.6";

  src = fetchFromGitHub {
    owner = "csete";
    repo = "gqrx";
    rev = "v${version}";
    sha256 = "12hhvdr8icgmh6rds1awbx501xqxkqb9bpg9zasx4znf71hfrkx6";
  };

  nativeBuildInputs = [ qmakeHook ];

  buildInputs = [
    qtbase qtsvg gnuradio boost gnuradio-osmosdr rtl-sdr hackrf
  ] ++ stdenv.lib.optionals pulseaudioSupport [ libpulseaudio ];

  enableParallelBuilding = true;

  postInstall = ''
    mkdir -p "$out/share/applications"
    mkdir -p "$out/share/icons"

    cp gqrx.desktop "$out/share/applications/"
    cp resources/icons/gqrx.svg "$out/share/icons/"
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

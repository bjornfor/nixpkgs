{ stdenv, fetchurl, cmake, pkgconfig, qt4, gstreamer, gst_plugins_base
, gst_python, gst_plugins_good, gst_plugins_bad, ffmpeg, libxml2
}:

stdenv.mkDerivation rec {
  name = "qstopmotion-1.0.1";

  src = fetchurl {
    url = "mirror://sourceforge/project/qstopmotion/Version_1_0_1/${name}-Source.tar.gz";
    sha256 = "139k0qc319m58lxlnbrxf8br56lkkr2jkkn1yjdm507w5wgv789v";
  };

  buildInputs = [
    cmake pkgconfig qt4 gstreamer gst_plugins_base gst_python gst_plugins_good
    gst_plugins_bad ffmpeg libxml2
  ];

  patches = [ ./qstopmotion-fix-gstreamer-include-dir.patch ];

  meta = with stdenv.lib; {
    description = "Create stop-motion animation movies";
    longDescription = ''
      qStopMotion is a fork of Linux Stopmotion. The main differences
      between Linux Stopmotion and qStopMotion are: Run on Linux and
      Windows operating systems. And probably also on MacOS, Redesigned user
      interface, Minimized using of external tools and replace with Qt
      functionality, No command line input from the user in the preferences
      menu.
    '';
    homepage = http://www.qstopmotion.org/;
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}

{ stdenv, fetchurl, cmake, gtk, libjpeg, libpng, libtiff, jasper, ffmpeg
, pkgconfig, gstreamer, xineLib, glib, python27, python27Packages
, buildExamples ? true
}:

let v = "2.4.7"; in

stdenv.mkDerivation rec {
  name = "opencv-${v}";

  src = fetchurl {
    url = "mirror://sourceforge/opencvlibrary/opencv-${v}.tar.gz";
    sha256 = "0hravl3yhyv4r4n7vb055d4qnp893q2hc0fcmmncfh7sbdrnr3f4";
  };

  buildInputs = [ gtk glib libjpeg libpng libtiff jasper ffmpeg xineLib gstreamer
    python27 python27Packages.numpy ];

  nativeBuildInputs = [ cmake pkgconfig ];

  cmakeFlags = stdenv.lib.optionals buildExamples [
    "-DBUILD_EXAMPLES=ON"
    "-DINSTALL_C_EXAMPLES=ON"
    "-DINSTALL_PYTHON_EXAMPLES=ON"
  ];

  # Python examples are not installed, despite -DINSTALL_PYTHON_EXAMPLES=ON.
  # Install them ourself.
  postInstall = stdenv.lib.optionalString buildExamples ''
    cp -r ../src/samples/python ../src/samples/python2 $out/share/OpenCV/samples/
  '';

  enableParallelBuilding = true;

  meta = {
    description = "Open Computer Vision Library with more than 500 algorithms";
    homepage = http://opencv.willowgarage.com/;
    license = "BSD";
    maintainers = with stdenv.lib.maintainers; [viric];
    platforms = with stdenv.lib.platforms; linux;
  };
}

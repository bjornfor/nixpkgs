{ stdenv, fetchurl, libjpeg, ffmpeg, linuxHeaders }:

# TODO: motion needs either mysql or postgresql

# Build system is impure: it detects CPU used for the build
#   ./configure
#   [...]
#   Detected CPU: Intel(R) Core(TM) i5-3570K CPU @ 3.40GHz

# FIXME: build fails:
#
# building motion.o
# gcc -g -O2 -DHAVE_FFMPEG -I/nix/store/7axlcvsq13vgf0y8ag6lnr1nfiz8qryy-ffmpeg-0.10/include -DFFMPEG_NEW_INCLUDES -DHAVE_FFMPEG_NEW -DMOTION_V4L2 -DMOTION_V4L2_OLD -DTYPE_32BIT="int" -DHAVE_BSWAP    -Wall -DVERSION=\"3.2.12\" -Dsysconfdir=\"/nix/store/dp8vlzczmfbgc22dvnwjqb6y0a0zxpk6-motion-3.2.12/etc\"    -c -o motion.o motion.c
# motion.c: In function 'motion_init':
# motion.c:585:26: error: 'VIDEO_PALETTE_YUV420P' undeclared (first use in this function)
# motion.c:585:26: note: each undeclared identifier is reported only once for each function it appears in
# make: *** [motion.o] Error 1
# builder for `/nix/store/q42l7p3k35fva87b75n1j17yn9cdivir-motion-3.2.12.drv' failed with exit code 2
# error: build of `/nix/store/q42l7p3k35fva87b75n1j17yn9cdivir-motion-3.2.12.drv' failed
# 

stdenv.mkDerivation rec {
  name = "motion-3.2.12";

  src = fetchurl {
    url = "mirror://sourceforge/motion/${name}.tar.gz";
    sha256 = "02ig9fkww9r0cin2a3dfq80zw5wpspm4wb3jcbxwbwqbxkbzi5x5";
  };

  buildInputs = [ libjpeg ffmpeg ];

  patches = [ ./v4l2.patch ];

  configureFlags = "--with-ffmpeg=${ffmpeg}"; # --with-mysql-lib=${mysql}";

  meta = with stdenv.lib; {
    description = "Video capture program supporting motion detection";
    homepage    = http://www.lavrsen.dk/foswiki/bin/view/Motion/WebHome;
    license     = licenses.gpl2Plus;
    maintainers = with maintainers; [ bjornfor ];
    platforms   = platforms.linux;
  };
}

{ stdenv, fetchurl, pkgconfig, popt, ncurses, babeltrace, libuuid, glib }:

stdenv.mkDerivation rec {
  name = "lttngtop-0.2";

  src = fetchurl {
    url = "http://lttng.org/files/lttngtop/${name}.tar.bz2";
    sha256 = "0hxw22ik6k9lmzh04j6q4gf5ndbziaz1cchvpvw83ihnjk9bs39z";
  };

  buildInputs = [ pkgconfig popt ncurses babeltrace libuuid glib ];

  meta = with stdenv.lib; {
    description = "A top-like, ncurses-based utility to analyze trace information";
    homepage = http://lttng.org/;
    # The only license info I could find was in the man page.
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };

}

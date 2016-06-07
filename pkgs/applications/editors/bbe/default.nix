{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "bbe-${version}";
  version = "0.2.2";

  src = fetchurl {
    url = "mirror://sourceforge/bbe-/bbe/${version}/${name}.tar.gz";
    sha256 = "1nyxdqi4425sffjrylh7gl57lrssyk4018afb7mvrnd6fmbszbms";
  };

  meta = with stdenv.lib; {
    description = "A sed-like editor for binary files";
    homepage = http://bbe-.sourceforge.net/;
    license = licenses.gpl2Plus;
    platforms = platforms.all;
    maintainers = [ maintainers.bjornfor ];
  };
}

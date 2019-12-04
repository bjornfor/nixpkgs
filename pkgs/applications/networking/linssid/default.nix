{ lib, stdenv, fetchurl, qtbase, qtsvg, qmake, pkg-config, boost, wirelesstools, iw, qwt6_1, wrapQtAppsHook }:

stdenv.mkDerivation rec {
  pname = "linssid";
  version = "3.6";

  src2 = fetchurl {
    url = "mirror://sourceforge/project/linssid/LinSSID_${version}/linssid_${version}.orig.tar.gz";
    sha256 = "1774wcr90jk0zil3psd545zz60l5f57bys366492b3vh7zliwc2p";
  };
  src = ../../../../linssid-3.6/.;

  nativeBuildInputs = [ pkg-config qmake wrapQtAppsHook ];
  buildInputs = [ qtbase qtsvg boost qwt6_1 ];

  #patches = [ ./0001-unbundled-qwt.patch ];

  #qmakeFlags = [ "PREFIX=/foobar" ];
  postUnpack = "set -x";
  preFixup = ''
    find "$out"
    ls -l "$out/bin/linssid" || true
  '';

  #postPatch = ''
  #  sed -e "s|/usr/include/qt5.*$|& ${qwt}/include|" -i linssid-app/linssid-app.pro
  #  sed -e "s|/usr/include/|/nonexistent/|g" -i linssid-app/*.pro
  #  sed -e 's|^LIBS .*= .*libboost_regex.a|LIBS += -lboost_regex|' \
  #      -e "s|/usr|$out|g" \
  #      -i linssid-app/linssid-app.pro linssid-app/linssid.desktop
  #  sed -e "s|\.\./\.\./\.\./\.\./usr|$out|g" -i linssid-app/*.ui

  #  # Remove bundled qwt
  #  rm -fr qwt-lib
  #'';

  #qtWrapperArgs =
  #  [ ''--prefix PATH : ${lib.makeBinPath [ wirelesstools iw ]}'' ];

  meta = with lib; {
    description = "Graphical wireless scanning for Linux";
    homepage = "https://sourceforge.net/projects/linssid/";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}

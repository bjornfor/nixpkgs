{ stdenv, fetchurl, cdparanoia, flac
, ruby, ruby-gtk
, withGui ? true, gtk2
, makeWrapper }:

assert withGui -> gtk2 != null;

stdenv.mkDerivation rec {
  version = "0.6.2";
  name = "rubyripper-${version}";

  src = fetchurl {
    url = "https://rubyripper.googlecode.com/files/rubyripper-${version}.tar.bz2";
    sha256 = "1fwyk3y0f45l2vi3a481qd7drsy82ccqdb8g2flakv58m45q0yl1";
  };

  buildInputs = [ ruby cdparanoia flac makeWrapper ] ++ stdenv.lib.optional withGui gtk2;

  configureFlags = [ "--enable-cli" ] ++ stdenv.lib.optional withGui "--enable-gtk2";

  preConfigure = "patchShebangs .";

  postInstall = ''
    wrapProgram "$out/bin/rrip_cli" \
      --prefix PATH : "${ruby}/bin" \
      --prefix PATH : "${cdparanoia}/bin"
  '';

  meta = with stdenv.lib; {
    description = "A secure audiodisc ripper (rips multiple times and corrects differences)";
    homepage = https://code.google.com/p/rubyripper/;
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}

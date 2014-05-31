{ stdenv, fetchurl }:

# Mailing list has one entry from 2004... this is dead..

stdenv.mkDerivation rec {
  name = "libhid-0.2.16";

  # FIXME: cannot download from debian... IT REQUIRES LOGIN!!
  src = fetchurl {
    url = https://alioth.debian.org/frs/download.php/file/1958/libhid-0.2.16.tar.gz;
    sha256 = "0000000000000000000000000b6bqa3wygdkxqvbffaki2ld833a";
  };

  #configureFlags = "";

  #buildInputs = [ ];

  meta = with stdenv.lib; {
    description = "User-space USB HID access library written in C";
    homepage = http://libhid.alioth.debian.org/;
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}

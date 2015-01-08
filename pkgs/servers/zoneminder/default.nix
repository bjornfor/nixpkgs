{ stdenv, fetchzip, cmake, libjpeg, mysql, gnutls, perl, zlib, makeWrapper, polkit, pkgconfig, glib
# optional
, ffmpeg ? null, curl ? null, openssl ? null, pcre ? null # AVFormat AVCodec AVDevice AVUtil SWScale libVLC

# mandatory perl modules:
, DBI, DBDmysql, DateManip, LWPUserAgent, SysMmap
# optional perl modules (or no longer used?)
, MIMELite ? null, MIMEtools ? null, NetSFTPForeign ? null, ArchiveZip ? null
, Expect ? null, HTTPMessage ? null, URI ? null, HTTPDate ? null
}:

# FIXME:
# ./result/bin/zmpkg.pl start    # fails
# ./result/bin/zmdc.pl startup   # succeeds

stdenv.mkDerivation rec {
  name = "zoneminder-1.28.0";

  src = fetchzip {
    url = "https://github.com/ZoneMinder/ZoneMinder/archive/v1.28.0.tar.gz";
    sha256 = "1ghf48sz8abavzs34hqcmwxi2ppmw58dx2vw2xm45wrs1q0m6466";
  };

  patches = [
    ./zoneminder-fix-install-paths.patch
    ./dont-touch-path-and-shell-env-vars.patch
  ];

  cmakeFlags = "-DZM_WEB_USER=nobody -DZM_WEB_GROUP=nogroup";

  buildInputs = [
    cmake libjpeg mysql gnutls perl zlib makeWrapper polkit pkgconfig glib
    # optional:
    ffmpeg curl openssl pcre

    # perl modules:
    DBI DBDmysql DateManip LWPUserAgent SysMmap
    # optional perl modules (or no longer used in >1.25?)
#    MIMELite
#    MIMEtools NetSFTPForeign ArchiveZip Expect HTTPMessage
#    URI HTTPDate


    # perl modules:
    DBI DBDmysql DateManip LWPUserAgent SysMmap
  ];

#  # - Fixup some impurities:
#  # - Remove perl -T argument, because it causes PERL5LIB to be ignored.
#  # - Make Perl scripts find their dependencies, using wrappers.
  postInstall = ''
    for file in "$out/bin"/*.pl; do
        sed -i "s|perl -wT|perl -w|" "$file"

        wrapProgram "$file" --prefix PERL5LIB : "${stdenv.lib.makePerlPath [ DBI DBDmysql DateManip LWPUserAgent SysMmap MIMELite MIMEtools NetSFTPForeign ArchiveZip Expect HTTPMessage URI HTTPDate ]}:$out/lib/perl5/site_perl" \
                            --prefix PATH : "$out/bin"
    done
  '';

  meta = with stdenv.lib; {
    description = "Video camera security and surveillance solution";
    homepage = http://www.zoneminder.com/;
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}

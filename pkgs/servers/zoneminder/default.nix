{ stdenv, fetchurl, mysql, ffmpeg, libjpeg, gnutls, libgcrypt, bzip2, zlib
, pcre, perl, makeWrapper
# perl modules:
, DBI, DBDmysql, DateManip, LWPUserAgent, SysMmap, MIMELite
, MIMEtools, NetSFTPForeign, ArchiveZip, Expect, HTTPMessage
, URI, HTTPDate
}:

# FIXME:
# ./result/bin/zmpkg.pl start    # fails
# ./result/bin/zmdc.pl startup   # succeeds

stdenv.mkDerivation rec {
  name = "zoneminder-1.25.0";

  src = fetchurl {
    url = "http://www2.zoneminder.com/downloads/ZoneMinder-1.25.0.tar.gz";
    sha256 = "0pdvv5sykgc217qxfbb88r8q0s39vvqlzj1v3br8mjzlv13yyqzc";
  };

  patches = [ ./dont-touch-path-and-shell-env-vars.patch ];

  # - __STDC_CONSTANT_MACROS is needed to bring in UINT64_C (and similar
  #   (U)INTn_C macros) from stdint.h when building with a C++ compiler
  #   (zoneminder buildsystem should have done this for us)
  # - The -fpermissinve flag changes errors like these to warnings (of course,
  #   it'd be better to fix zoneminder code):
  #   zm_local_camera.cpp:742:49: error: invalid conversion from '__u32 {aka unsigned int}' to 'v4l2_buf_type' [-fpermissive]
  preConfigure = ''
    export CXXFLAGS="-D__STDC_CONSTANT_MACROS -fpermissive"
    configureFlags="\
        --with-libarch=lib \
        --with-mysql=${mysql} \
        --with-ffmpeg=${ffmpeg} \
        --with-webdir=$out/share/zoneminder/webdir \
        --with-cgidir=$out/share/zoneminder/cgi-bin \
        --with-webuser=nobody \
        --with-webgroup=nobody \
        --with-webhost=localhost.example \
        --disable-crashtrace \
        --enable-mmap=yes \
        "
  '';

  buildInputs = [
    mysql ffmpeg libjpeg gnutls libgcrypt bzip2 zlib pcre perl makeWrapper
    # perl modules:
    DBI DBDmysql DateManip LWPUserAgent SysMmap MIMELite
    MIMEtools NetSFTPForeign ArchiveZip Expect HTTPMessage
    URI HTTPDate
  ];

  # Remove the install-data-hook target and actions, which attempts to chmod
  # and chown stuff in the nix store for the webuser, and make directories in
  # /var. Even the zoneminder developers call it a hack!
  postBuild = ''
    sed -i -e "/^install-data-hook:/,+4d" Makefile
    sed -i -e "/^install-data-hook:/,+7d" web/Makefile
  '';

  # - Fixup some impurities:
  #   - ZM_PATH_BUILD: Path to build directory, used mostly for finding DB upgrade scripts
  #   - ZM_TIME_BUILD: Build time, used to record when to trigger various checks
  # - Remove perl -T argument, because it causes PERL5LIB to be ignored.
  # - Make Perl scripts find their dependencies, using wrappers.
  # - Copy the *.sql files (why aren't these installed automatically?)
  postInstall = ''
    sed -i -e "s|ZM_PATH_BUILD=.*|ZM_PATH_BUILD=/tmp/zoneminder|" \
           -e "s|ZM_TIME_BUILD=.*|ZM_TIME_BUILD=0|" \
           "$out/etc/zm.conf"

    for file in "$out/bin"/*.pl; do
        sed -i "s|perl -wT|perl -w|" "$file"
        wrapProgram "$file" --prefix PERL5LIB : "${stdenv.lib.makePerlPath [ DBI DBDmysql DateManip LWPUserAgent SysMmap MIMELite MIMEtools NetSFTPForeign ArchiveZip Expect HTTPMessage URI HTTPDate ]}:$out/lib/perl5/site_perl" \
                            --prefix PATH : "$out/bin"
    done

    mkdir -p "$out/share/zoneminder/db/"
    cp db/*.sql "$out/share/zoneminder/db/"
  '';

  meta = with stdenv.lib; {
    description = "Video camera security and surveillance solution";
    homepage = http://www.zoneminder.com/;
    license = licenses.gpl2;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}

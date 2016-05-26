{ stdenv, fetchurl, gnome3, pkgconfig, intltool, glib, evolution_data_server, gtk, libsoup, sqlite, evolution, webkitgtk, libmspack }:

stdenv.mkDerivation rec {
  name = "evolution-ews-${gnome3.version}.4";

  src = fetchurl {
    url = "mirror://gnome/sources/evolution-ews/${gnome3.version}/${name}.tar.xz";
    sha256 = "01y706dfi95dfiwnsyba35iz921b5j3qmwvmmjj2abn3y7qx91cj";
  };

  buildInputs = with gnome3;
     [ pkgconfig intltool glib evolution_data_server gtk libsoup sqlite evolution webkitgtk libmspack ];
  #  [ pkgconfig glib python intltool libsoup libxml2 gtk gnome_online_accounts
  #    gcr p11_kit libgweather libgdata gperf makeWrapper icu sqlite gsettings_desktop_schemas ]
  #  ++ stdenv.lib.optional valaSupport vala;

  #propagatedBuildInputs = [ libsecret nss nspr libical db ];

  # Make EWS install to its own directory instead of the installation directory
  # of evolution-data-server. Found by looking at config.log in a failed build.
  preConfigure = ''
    sed -e "s|\<ewsdatadir=.*|ewsdatadir=$out/share/evolution-data-server/ews|" \
        -e "s|\<privincludedir=.*|privincludedir=$out/include/evolution-data-server/ews|" \
        -e "s|\<privlibdir=.*|privlibdir=$out/lib/evolution-data-server/ews|" \
        -e "s|\<camel_providerdir=.*|camel_providerdir=$out/lib/evolution-data-server/camel-providers|" \
        -e "s|\<ebook_backenddir=.*|ebook_backenddir=$out/lib/evolution-data-server/addressbook-backend|" \
        -e "s|\<ecal_backenddir=.*|ecal_backenddir=$out/lib/evolution-data-server/calendar-backends|" \
        -e "s|\<edataserver_privincludedir=.*|edataserver_privincludedir=$out/include/evolution-data-server|" \
        -e "s|\<eds_moduledir=.*|eds_moduledir=$out/lib/evolution-data-server/registry-modules|" \
        -e "s|\<errordir=.*|errordir=$out/share/evolution/errors|" \
        -e "s|\<evo_moduledir=.*|evo_moduledir=$out/lib/evolution/modules|" \
        -i configure
  '';

  # uoa irrelevant for now
  #configureFlags = [ "--disable-uoa" ]
  #                 ++ stdenv.lib.optional valaSupport "--enable-vala-bindings";

  #preFixup = ''
  #  for f in "$out/libexec/"*; do
  #    wrapProgram "$f" --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
  #  done
  #'';

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "MS Exchange integration through Exchange Web Services";
    license = licensees.lgpl21;
    platforms = platforms.linux;
    maintainers = gnome3.maintainers;
  };
}

#{ fetchurl, stdenv, pkgconfig, gnome3, python
#, intltool, libsoup, libxml2, libsecret, icu, sqlite
#, p11_kit, db, nspr, nss, libical, gperf, makeWrapper, valaSupport ? true, vala }:
#
#
#stdenv.mkDerivation rec {
#  name = "evolution-data-server-${gnome3.version}.3";
#
#  src = fetchurl {
#    url = "mirror://gnome/sources/evolution-data-server/${gnome3.version}/${name}.tar.xz";
#    sha256 = "19dcvhlqh25pkkd29hhm9yik8xxfy01hcakikrai0x1a04aa2s7f";
#  };
#
#  buildInputs = with gnome3;
#    [ pkgconfig glib python intltool libsoup libxml2 gtk gnome_online_accounts
#      gcr p11_kit libgweather libgdata gperf makeWrapper icu sqlite gsettings_desktop_schemas ]
#    ++ stdenv.lib.optional valaSupport vala;
#
#  propagatedBuildInputs = [ libsecret nss nspr libical db ];
#
#  # uoa irrelevant for now
#  configureFlags = [ "--disable-uoa" ]
#                   ++ stdenv.lib.optional valaSupport "--enable-vala-bindings";
#
#  preFixup = ''
#    for f in "$out/libexec/"*; do
#      wrapProgram "$f" --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
#    done
#  '';
#
#  meta = with stdenv.lib; {
#    platforms = platforms.linux;
#    maintainers = gnome3.maintainers;
#  };
#
#}

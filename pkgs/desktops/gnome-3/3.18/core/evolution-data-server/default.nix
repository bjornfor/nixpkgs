{ fetchurl, stdenv, pkgconfig, gnome3, python
, intltool, libsoup, libxml2, libsecret, icu, sqlite
, p11_kit, db, nspr, nss, libical, gperf, makeWrapper, valaSupport ? true, vala
, enableEws ? true, /*evolution ? null,*/ webkitgtk ? null, libmspack ? null
}:

assert enableEws -> /*evolution != null &&*/ webkitgtk != null && libmspack != null;

let
  ews = rec {
    name = "evolution-ews-${gnome3.version}.4";
    src = fetchurl {
      url = "mirror://gnome/sources/evolution-ews/${gnome3.version}/${name}.tar.xz";
      sha256 = "01y706dfi95dfiwnsyba35iz921b5j3qmwvmmjj2abn3y7qx91cj";
    };
  };
in
stdenv.mkDerivation rec {
  inherit (import ./src.nix fetchurl) name src;

  buildInputs = with gnome3;
    [ pkgconfig glib python intltool libsoup libxml2 gtk gnome_online_accounts
      gcr p11_kit libgweather libgdata gperf makeWrapper icu sqlite gsettings_desktop_schemas ]
    ++ stdenv.lib.optional valaSupport vala
    ++ stdenv.lib.optionals enableEws [ /*webkitgtk*/ libmspack ];

  propagatedBuildInputs = [ libsecret nss nspr libical db ];

  # uoa irrelevant for now
  configureFlags = [ "--disable-uoa" ]
                   ++ stdenv.lib.optional valaSupport "--enable-vala-bindings";

  preFixup = ''
    for f in "$out/libexec/"*; do
      wrapProgram "$f" --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
    done
  '';

  # EWS really wants to be inside evolution_data_server, so let it. (It's not
  # that big.)
  postInstall = stdenv.lib.optional enableEws ''
    echo "Building EWS"
    tar xvf ${ews.src}
    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$out/lib/pkgconfig"
    (cd ${ews.name} && ./configure --prefix=$out && make && make install)
  '';

  meta = with stdenv.lib; {
    platforms = platforms.linux;
    maintainers = gnome3.maintainers;
  };

}

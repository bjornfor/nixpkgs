{ stdenv, evolution_data_server, evolution, evolution-ews, wrapGAppsHook }:

# Getting evolution to find external plugins requires patching. Brute force
# solution: make a derivation with Evolution + EDS + plugins all in one store
# path.

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "evolution-with-plugins"; # TODO: version

  srcs = [ evolution_data_server.src evolution.src evolution-ews.src ];

  # - Why are the buildInputs from $pkg not available as 'buildInputs', but
  #   instead as 'nativeBuildInputs'?
  # - Filter out some paths that we must not be available in this build (or
  #   else this build will depend on those paths instead of this new "union"
  #   path).
  buildInputs = filter (x: x != evolution && x != evolution_data_server && x != evolution-ews)
    (evolution_data_server.buildInputs
      ++ evolution.buildInputs
      ++ evolution-ews.buildInputs
      ++ evolution_data_server.nativeBuildInputs
      ++ evolution.nativeBuildInputs
      ++ evolution-ews.nativeBuildInputs
      ++ [ wrapGAppsHook ]
    );

  propagatedBuildInputs = filter (x: x != evolution && x != evolution_data_server && x != evolution-ews)
    (evolution_data_server.propagatedBuildInputs
      ++ evolution.propagatedBuildInputs
      ++ evolution-ews.propagatedBuildInputs
    );

  buildCommand = ''
    for src in $srcs; do
        tar xf "$src"
    done

    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$out/lib/pkgconfig"

    echo
    echo "### Building evolution-data-server"
    echo
    pushd ${evolution_data_server.name}
    ./configure --prefix=$out ${concatStringsSep " " evolution_data_server.configureFlags or []}
    make
    make install
    popd

    echo
    echo "### Building evolution"
    echo
    pushd ${evolution.name}
    # Save NIX_CFLAGS_COMPILE
    export ORIG_NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE"
    export NIX_CFLAGS_COMPILE="$ORIG_NIX_CFLAGS_COMPILE ${evolution.NIX_CFLAGS_COMPILE}"
    ./configure --prefix=$out ${concatStringsSep " " evolution.configureFlags or []}
    make
    make install
    popd
    # Restore NIX_CFLAGS_COMPILE
    export NIX_CFLAGS_COMPILE="$ORIG_NIX_CFLAGS_COMPILE"

    echo
    echo "### Building evolution-ews"
    echo
    pushd ${evolution-ews.name}
    ${evolution-ews.preConfigure or ""}
    ./configure --prefix=$out ${concatStringsSep " " evolution-ews.configureFlags or []}
    make
    make install
    popd

    fixupPhase
  '';

  meta = with stdenv.lib; {
    description = "Personal information management application that provides integrated mail, calendaring and address book functionality (bundled with plugins)";
    homepage = https://wiki.gnome.org/Apps/Evolution;
    license = licenses.lgpl2Plus;
    platforms = platforms.linux;
    maintainers = gnome3.maintainers;
  };
}

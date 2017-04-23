{ stdenv, fetchurl, bash, cabextract, curl, gnupg, libX11, mesa, perl, wineStaging
, strace
 }:

let
  wine_custom = wineStaging;

  mozillaPluginPath = "/lib/mozilla/plugins";


in stdenv.mkDerivation rec {

  version = "0.2.8";

  name = "pipelight-${version}";

  src = fetchurl {
    url = "https://bitbucket.org/mmueller2012/pipelight/get/v${version}.tar.gz";
    sha256 = "1i440rf22fmd2w86dlm1mpi3nb7410rfczc0yldnhgsvp5p3sm5f";
  };

  buildInputs = [ wine_custom libX11 mesa curl ];

  propagatedbuildInputs = [ curl cabextract ];

  patches = [ ./pipelight.patch ];

  configurePhase = ''
    patchShebangs .
    grep -rl "/usr/bin/id" . | \
        while read f; do
            sed -i -e "s|/usr/bin/id|id|g" "$f"
        done
    ./configure \
      --prefix=$out \
      --moz-plugin-path=$out/${mozillaPluginPath} \
      --wine-path=${wine_custom}/bin/wine \
      --gpg-exec=${gnupg}/bin/gpg2 \
      --bash-interp=${bash}/bin/bash \
      --downloader=${curl.bin}/bin/curl
      $configureFlags
  '';

  passthru = {
    mozillaPlugin = mozillaPluginPath;
    wine = wine_custom;
  };

  postInstall = ''
    echo "Running pipelight-plugin --create-mozilla-plugins"
    ${strace}/bin/strace -o$out/out.strace -f -s300 \
    $out/bin/pipelight-plugin --create-mozilla-plugins

    cp config.make "$out"

    cp -r $out/lib/pipelight/. $out/lib/mozilla/plugins/
  '';

    #substituteInPlace $out/share/pipelight/install-dependency \
    #  --replace cabextract ${cabextract}/bin/cabextract
  preFixup = ''
    sed -e "s|\<cabextract\>|${cabextract}/bin/cabextract|g" \
        -i "$out/share/pipelight/install-dependency"
  '';

  enableParallelBuilding = true;

  meta = {
    homepage = "http://pipelight.net/";
    license = with stdenv.lib.licenses; [ mpl11 gpl2 lgpl21 ];
    description = "A wrapper for using Windows plugins in Linux browsers";
    maintainers = with stdenv.lib.maintainers; [ skeidel ];
    platforms = with stdenv.lib.platforms; linux;
  };
}

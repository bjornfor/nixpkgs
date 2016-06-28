{ stdenv, fetchurl, which, man, xwininfo, bc, makeWrapper
, perl, ConfigSimple, DBI, DBDSQLite, CaptureTiny, FileBaseDir, FileWhich
}:

stdenv.mkDerivation rec {
  version = "4.0.1.19";
  name = "x2goserver-${version}";

  src = fetchurl {
    url = "http://code.x2go.org/releases/source/x2goserver/${name}.tar.gz";
    sha256 = "1k130saz8syrgi587xzl77wlcxnkz3shhszxc23s74kr993c3m9x";
  };

  buildInputs = [ which man perl ];
  nativeBuildInputs = [ makeWrapper ];

  patches = [ ./0001-buildsys-make-Nix-friendly.patch ];

  makeFlags = [
    "PREFIX=$(out)"
    "ETCDIR=$(out)/etc"
  ];

  # * Should x2godbwrapper.pm stay impure?
  # * The 'build-indep' Makefile target builds HTML files from manpages with
  #   the man2html tool. Since we don't have that in nixpkgs, and it's not
  #   strictly needed for the software to work, I'm patching it out.
  postPatch = ''
    #sed -i -e "s|/etc/x2go/|$out/etc/x2go/|g" x2goserver/lib/x2godbwrapper.pm
    sed -i -e "s|build: build-arch build-indep|build: build-arch|" Makefile
  '';

  postInstall = ''
    for prog in "$out/bin/"* "$out/sbin/"*; do
        wrapProgram "$prog" --prefix PATH : "$out/bin:${xwininfo}/bin:${bc}/bin" \
            --set PERL5LIB \
            "$out/lib/x2go:${stdenv.lib.makePerlPath [ ConfigSimple DBI DBDSQLite CaptureTiny FileBaseDir FileWhich ]}"
    done

    sed -i -e "s|/usr|$out|" x2goserver.service
    install -Dm 644 x2goserver.service "$out/lib/systemd/system/x2goserver.service"
  '';

  meta = with stdenv.lib; {
    description = "Remote desktop server software";
    homepage = http://x2go.org/;
    license = licenses.gpl2;
    platforms = platforms.all;
    maintainers = [ maintainers.bjornfor ];
  };
}

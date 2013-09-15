{ stdenv, fetchurl, python, sip, qt4, pyqt4, qwt, numpy }:

stdenv.mkDerivation rec {
  version = "5.2.0";
  name = "pyqwt-${version}";
  
  src = fetchurl {
    url = "mirror://sourceforge/project/pyqwt/pyqwt5/PyQwt-${version}/PyQwt-${version}.tar.gz";
    sha256 = "02z7g60sjm3hx7b21dd8cjv73w057dwpgyyz24f701vdqzhcga4q";
  };
  
  buildInputs = [ python sip qt4 pyqt4 qwt numpy ];

  patches = [ ./0001-Fix-sip-install-dir-for-Nix.patch ];

  configurePhase = ''
    cd configure
    python configure.py -I${qwt} -lqwt --module-install-path="/tmp/foobar"
    # Neither fixes the sip install path:
    #  --module-install-path="$out"
    #  --module-install-path="$out/lib/python2.7/site-packages/PyQt4/Qwt5"
    # make install will still try to install stuff to the sip nix store path.
  '';

  preInstall = "set -x"; # help debugging install failure

  # error: invalid command 'test'
  doCheck = false;

  meta = with stdenv.lib; {
    description = "Python bindings for the Qwt library (Qt widgets for technical applications)";
    homepage = http://pyqwt.sourceforge.net/;
    # GNU GPLv2+ with exceptions for use with non-free versions of Qt and PyQt
    license = "PyQwt LICENSE, Version 3";
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}

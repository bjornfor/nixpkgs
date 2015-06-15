{ stdenv, fetchzip, buildPythonPackage, pkgconfig, boost, numpy, wxPython30
, gtkglextmm, pangox_compat, libXmu
}:

# TODO:
#
# Does it work for all python versions?
#  disabled = isPy3k;
#
# What license does it have?

buildPythonPackage rec {
  name = "vpython-${version}";
  version = "6.11";

  src = fetchzip {
    name = "${name}-src";
    url = "https://github.com/BruceSherwood/vpython-wx/archive/v${version}.tar.gz";
    sha256 = "0ynyjwdz15s6dxsxb73zvqiz4ra1lc9wm0qr630dzin2h1sdm13j";
  };

  buildInputs = [ pkgconfig pangox_compat boost libXmu numpy wxPython30 gtkglextmm ];

  # rename library dependency: boost_python-py + version => boost_python
  preBuild = ''
    sed -i -e "s/boost_python-py.*/boost_python')/" setup.py
  '';

  # figure out what should be in propagatedBuildInputs
  #propagatedBuildInputs = [ numpy wxPython30 gtkglextmm ];

  meta = with stdenv.lib; {
    # descriptions copied from setup.py
    description = "3D programming for ordinary mortals";
    longDescription = ''
      VPython is the Python programming language plus a 3D graphics module
      called "Visual" originated by David Scherer in 2000. VPython makes it
      easy to create navigable 3D displays and animations, even for those with
      limited programming experience. Because it is based on Python, it also
      has much to offer for experienced programmers and researchers.
    '';
    #license = licenses...  # TODO
    platforms = platforms.all;
    maintainers = [ maintainers.bjornfor ];
  };
}

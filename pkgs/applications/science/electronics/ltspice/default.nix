{stdenv, fetchurl, wine, makeWrapper }:

# FIXME: how to unpack the interactive .exe installer?
# Hm, maybe this isn't worth it, the .exe is quick to install and runs without
# issues on NixOS.

stdenv.mkDerivation rec {
  # The version number is the date of the last update
  name = "ltspice-20130820";

  src = fetchurl {
    inherit name;
    # Unfortunately, there is no archive of old versions. Only the
    # latest-and-greatest exist at any time.
    url = http://ltspice.linear.com/software/LTspiceIV.exe;
    sha256 = "0psqbf80v3qwbnhx9xbkyjb02aczdxswdnzxilanqyscfdl42k5l";
  };

  buildInputs = [ wine makeWrapper ];

  #phases = [ "installPhase" ];

  # Copied from the teamviewer expression
  installPhase = ''
    mkdir -p "$out/share/ltspice" "$out/bin"
    #cp -a .tvscript/* "$out/share/ltspice"
    #cp -a .wine/drive_c "$out/share/ltspice"
    #sed -i -e 's/^tv_Run//' \
    #    -e 's/^  setup_tar_env//' \
    #    -e 's/^  setup_env//' \
    #    -e 's,^  TV_Wine_dir=.*,  TV_Wine_dir=${wine},' \
    #    -e 's,progsrc=.*drive_c,progsrc='$out'"/share/ltspice/drive_c,' \
    #    "$out/share/ltspice/wrapper"

    echo "find $out:"
    find "$out"
    #cat > "$out/bin/ltspice" << EOF
    ##!${stdenv.shell}
    #"$out/share/ltspice/wrapper" wine "c:\Program Files\LTC\LTspiceIV\scad3.exe" "\$@"
    #EOF
    #chmod +x $out/bin/ltspice
  '';


  meta = with stdenv.lib; {
    description = "SPICE simulator, schematic capture and waveform viewer from Linear Technology";
    homepage = http://www.linear.com/designtools/software/;
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}

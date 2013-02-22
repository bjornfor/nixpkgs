{ stdenv, fetchurl, cmake, pkgconfig, qt48, file, libXcomposite, libXdamage,
  libXau, libXdmcp, libpthreadstubs,
  pulseaudio ? null,
  polkit_qt_1 ? null,
  lm_sensors ? null,
  doxygen ? null,  # to build documentation
  # TODO: LightDM with Qt4 support (for LightDM greeter) (OPTIONAL)
  # TODO: libstatgrab (panel's CPU and Network Monitor plugins) (OPTIONAL)
  openbox  # one of many possible windowmanagers
}:

stdenv.mkDerivation rec {
  name = "razorqt-0.5.2";
  
  src = fetchurl {
    url = "http://razor-qt.org/downloads/${name}.tar.bz2";
    sha256 = "1bg1w2q00izz4ywv3qf1jwwqa0b01h1ab9qf5h5a493sp878k2mc";
  };

  patches = [ ./0001-Use-RAZOR_ETC_XDG_DIRECTORY-instead-of-hardcoding-et.patch
              ./0002-Use-CMAKE_INSTALL_PREFIX-instead-of-hardcoding-usr.patch ];

  # TODO:
  # Use multiple outputs: bin, doc ?

  # -- RAZOR_ETC_XDG_DIRECTORY will be autodetected now
  # -- You can set it manually with -DRAZOR_ETC_XDG_DIRECTORY=<value>
  # -- RAZOR_ETC_XDG_DIRECTORY autodetected as '/etc/xdg'

  # '$out' is not expanded ($out/etc):
  #   Installing: /nix/store/n0nfhvk292nddp1dgip6lgn8d22n-razor-qt-0.5.2/$out/etc/razor/razor.conf
  # But relative path seems to work.
  cmakeFlags = "-DRAZOR_ETC_XDG_DIRECTORY=etc/xdg";

  buildInputs = [ cmake pkgconfig qt48 file libXcomposite libXdamage libXau
                  libXdmcp libpthreadstubs pulseaudio polkit_qt_1 lm_sensors
                  doxygen ];

  # FIXME: this files seems to be ignored. If the same is put in ~/.config/razor/session.conf it works.
  fixupPhase = "printf '[General]\nwindowmanager=${openbox}/bin/openbox' >> $out/etc/xdg/razor/session.conf";

  meta = {
    description = "Lightweight desktop environment based on Qt technologies";
    longDescription = ''
      Razor-qt is an advanced, easy-to-use, and fast desktop environment based
      on Qt technologies. It has been tailored for users who value simplicity,
      speed, and an intuitive interface. Unlike desktop environments, Razor-qt
      also works fine with weak machines and low requirements software. This
      metapackage provides all the components of Razor-qt
    '';
    homepage = http://www.razor-qt.org/;
    license = "GPLv2 and LGPLv2.1+";
    platforms = stdenv.lib.platforms.linux;
  };
}

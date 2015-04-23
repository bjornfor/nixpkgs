{ stdenv, fetchurl, pkgconfig, libnih, dbus, autoreconfHook }:

stdenv.mkDerivation rec {
  name = "cgmanager-0.36";

  src = fetchurl {
    url = "https://linuxcontainers.org/downloads/cgmanager/${name}.tar.gz";
    sha256 = "039azd4ghpmiccd95ki8fna321kccapff00rib6hrdgg600pyw7l";
  };

  buildInputs = [ pkgconfig libnih dbus autoreconfHook ];

  # Patch already merged upstream (https://github.com/lxc/cgmanager/pulls/8)
  postPatch = ''
    sed -i -e 's|$(DESTDIR)/usr/share|$(datarootdir)|' Makefile.am
  '';

  meta = with stdenv.lib; {
    description = "Linux cgroup manager";  # FIXME?
    longDescription = ''
      CGManager is a central privileged daemon that manages all your cgroups
      for you through a simple DBus API.  It's designed to work with nested LXC
      containers as well as accepting unprivileged requests including resolving
      user namespaces UIDs/GIDs.
    '';
    # TODO
  };
}

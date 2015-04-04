{ stdenv, fetchurl, fuse }:

# $ ./result/bin/djmount -f ~/av
# [I] Charset : successfully initialised charset='UTF-8'
# [I] UPnP Initialized (192.168.1.140:49153)
# [I] Add new device : Name='NixOS Media Server' Id='uuid:4d696e69-444c-164e-9d41-00012e496794' descURL='http://192.168.1.140:8200/rootDesc.xml'
# [E] Error Subscribing to ContentDir EventURL -- -104
# [E] Error Subscribing to Service EventURL -- -104
# [E] Error Subscribing to Service EventURL -- -104
# [I] Add new device : Name='RT-N66U' Id='uuid:4d696e69-444c-164e-9d41-d850e6ae52c8' descURL='http://192.168.1.1:8200/rootDesc.xml'
# [E] Error Subscribing to ContentDir EventURL -- -104
# [E] Error Subscribing to Service EventURL -- -104
# [E] Error Subscribing to Service EventURL -- -104
# [E] Error obtaining device description from url 'http://192.168.1.1:44983/rootDesc.xml' : -104 (UPNP_E_OUTOF_MEMOR)
# [E] Error obtaining device description from url 'http://192.168.1.1:44983/rootDesc.xml' : -104 (UPNP_E_OUTOF_MEMOR)
# [E] Error obtaining device description from url 'http://192.168.1.1:44983/rootDesc.xml' : -104 (UPNP_E_OUTOF_MEMOR)
# [E] Error obtaining device description from url 'http://192.168.1.1:44983/rootDesc.xml' : -104 (UPNP_E_OUTOF_MEMOR)
# [E] Error obtaining device description from url 'http://192.168.1.1:44983/rootDesc.xml' : -104 (UPNP_E_OUTOF_MEMOR)
# [E] Error obtaining device description from url 'http://192.168.1.1:44983/rootDesc.xml' : -104 (UPNP_E_OUTOF_MEMOR)
# [E] Error obtaining device description from url 'http://192.168.1.1:44983/rootDesc.xml' : -104 (UPNP_E_OUTOF_MEMOR)
# [E] Error obtaining device description from url 'http://192.168.1.1:44983/rootDesc.xml' : -104 (UPNP_E_OUTOF_MEMOR)

stdenv.mkDerivation rec {
  name = "djmount-${version}";
  version = "0.71";

  src = fetchurl {
    url = "mirror://sourceforge/djmount/${version}/${name}.tar.gz";
    sha256 = "0kqf0cy3h4cfiy5a2sigmisx0lvvsi1n0fbyb9ll5gacmy1b8nxa";
  };

  buildInputs = [ fuse ];

  meta = with stdenv.lib; {
    description = "UPnP client that mounts AV devices as a filesystem (using FUSE)";
    longDescription = ''
      djmount is a UPnP AV client. It mounts as a Linux filesystem (using FUSE)
      the media content of compatible UPnP AV devices: the Audio and Video
      content on the network is automatically discovered, and can be browsed as
      a standard directory tree.
    '';
    homepage = http://djmount.sourceforge.net/;
    license = license.gpl2Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.bjornfor ];
  };
}

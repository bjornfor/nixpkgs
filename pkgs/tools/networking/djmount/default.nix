{ stdenv, fetchurl, fuse, libupnp }:

# Problem 1, if not using libupnp (djmount will use a copy it has):
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

# Problem 2, if using libupnp (tested v1.6.19):
#
# gcc -DHAVE_CONFIG_H -I. -I. -I..    -I../gl -I../talloc/talloc -I/nix/store/hmynal598zr4jbqwplblw15pawl190n6-libupnp-1.6.19/include   -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=22  -g -O2 -Wall -pthread -c upnp_util.c
# In file included from upnp_util.c:31:0:
# upnp_util.h:49:8: error: unknown type name 'Upnp_EventType'
#      IN Upnp_EventType eventType, 
#         ^
# upnp_util.h:58:33: error: unknown type name 'Upnp_EventType'
#  UpnpUtil_GetEventTypeString (IN Upnp_EventType e);
#                                  ^
# upnp_util.c:43:33: error: unknown type name 'Upnp_EventType'
#  UpnpUtil_GetEventTypeString (IN Upnp_EventType e)
#                                  ^
# upnp_util.c:84:8: error: unknown type name 'Upnp_EventType'
#      IN Upnp_EventType eventType, 
#         ^
# upnp_util.c: In function 'UpnpUtil_ResolveURL':
# upnp_util.c:283:2: warning: implicit declaration of function 'strlen' [-Wimplicit-function-declaration]
#   char resolved [(base ? strlen(base):0) + (rel ? strlen(rel):0) + 2];
#   ^
# upnp_util.c:283:25: warning: incompatible implicit declaration of built-in function 'strlen' [enabled by default]
#   char resolved [(base ? strlen(base):0) + (rel ? strlen(rel):0) + 2];
#                          ^
# upnp_util.c:288:13: error: 'UPNP_E_SUCCESS' undeclared (first use in this function)
#    if (rc != UPNP_E_SUCCESS) {
#              ^
# upnp_util.c:288:13: note: each undeclared identifier is reported only once for each function it appears in
# Makefile:540: recipe for target 'upnp_util.o' failed
# make[3]: *** [upnp_util.o] Error 1

stdenv.mkDerivation rec {
  name = "djmount-${version}";
  version = "0.71";

  src = fetchurl {
    url = "mirror://sourceforge/djmount/${version}/${name}.tar.gz";
    sha256 = "0kqf0cy3h4cfiy5a2sigmisx0lvvsi1n0fbyb9ll5gacmy1b8nxa";
  };

  buildInputs = [ fuse ];

  configureFlags = "--with-external-libupnp --with-libupnp-prefix=${libupnp}";

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

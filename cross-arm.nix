let
  pkgsFun = import ./default.nix;   # The root nixpkgs default.nix
  pkgs = pkgsFun { };

in

pkgsFun {
  crossSystem = {
    config = "arm-unknown-linux-gnueabi";
    bigEndian = true;
    arch = "arm";
    float = "soft";
    withTLS = true;
    libc = "glibc";
    #platform = pkgs.platforms.sheevaplug;  # re-use platforms defined in nixpkgs
    platform = {
      name = "olimex";
      kernelMajor = "2.6";
      kernelBaseConfig = "vexpress_defconfig";
      kernelHeadersBaseConfig = "integrator_defconfig";
      uboot = null;
      kernelArch = "arm";
      kernelAutoModules = false;
      kernelTarget = "zImage";  # results in $out/vmlinux and $out/zImage
    };
    openssl.system = "linux-generic32";
    #gcc = {
    #  arch = "generic-arm";
    #};
  };
}

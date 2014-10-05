{ stdenv, fetchurl, makeWrapper, makeDesktopItem, jdk, jre, ant
, unzip, sweethome3dAppSrc
}:

let

  sweetExec = with stdenv.lib;
    m: "sweethome3d-"
    + removeSuffix "libraryeditor" (toLower m)
    + "-editor";
  sweetName = m: v: sweetExec m + "-" + v;

  mkEditorProject =
  { name, module, version, src, license, description }:

  stdenv.mkDerivation rec {
    sweethome3d_sourcetree = stdenv.mkDerivation {
      name = "sweethome3d-source";
      src = sweethome3dAppSrc;
      buildInputs = [ unzip ];
      installPhase = ''
        mkdir -p "$out/src"
        cp -r "$src" "$out/src"
      '';
    };
    inherit name module version src description;
    exec = sweetExec module;
    editorItem = makeDesktopItem {
      inherit name exec;
      comment =  description;
      desktopName = name;
      genericName = "Computer Aided (Interior) Design";
      categories = "Application;CAD;";
    };

    buildInputs = [ ant jre jdk makeWrapper unzip ];

    patchPhase = ''
      sed -i -e 's,../SweetHome3D,${sweethome3d_sourcetree},g' build.xml
    '';

    buildPhase = ''
      ant -lib ${sweethome3d_sourcetree}/libtest -lib ${sweethome3d_sourcetree}/lib -lib ${jdk}/lib
    '';

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share/{java,applications}
      cp ${module}-${version}.jar $out/share/java/.
      cp ${editorItem}/share/applications/* $out/share/applications
      makeWrapper ${jre}/bin/java $out/bin/$exec \
        --add-flags "-jar $out/share/java/${module}-${version}.jar ${if stdenv.system == "x86_64-linux" then "-d64" else "-d32"}"
    '';

    dontStrip = true;

    meta = {
      homepage = "http://www.sweethome3d.com/index.jsp";
      inherit description;
      inherit license;
      maintainers = [ stdenv.lib.maintainers.edwtjo ];
      platforms = stdenv.lib.platforms.linux;
    };

  };

in rec {

  textures-editor = mkEditorProject rec {
    version = "1.4";
    module = "TexturesLibraryEditor";
    name = sweetName module version;
    description = "Easily create SH3T files and edit the properties of the texture images it contain";
    license = stdenv.lib.licenses.gpl2Plus;
    src = fetchurl {
      url = "mirror://sourceforge/project/sweethome3d/TexturesLibraryEditor-source/TexturesLibraryEditor-${version}-src.zip";
      sha256 = "00000000000j5dr7w2swnlbvkb3q1jdjr1zgjn1k07d0fxh0ikbx";
    };
  };

  furniture-editor = mkEditorProject rec {
    version = "1.14";
    module = "FurnitureLibraryEditor";
    name = sweetName module version;
    description = "Quickly create SH3F files and edit the properties of the 3D models it contain";
    license = stdenv.lib.licenses.gpl2;
    src = fetchurl {
      url = "mirror://sourceforge/project/sweethome3d/FurnitureLibraryEditor-source/FurnitureLibraryEditor-${version}-src.zip";
      sha256 = "07qahqxwmfp94ppmqxy4hr12vfb675rfg7g2svkqpz85isgcjbsm";
    };
  };

}

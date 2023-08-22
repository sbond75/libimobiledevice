{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, libtool
, pkg-config
, gnutls
, libgcrypt
, libtasn1
, callPackage
, openssl
, enablePython ? false
, python3
}:

stdenv.mkDerivation rec {
  pname = "libimobiledevice";
  version = "unstable-2023-4-30";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "860ffb707af3af94467d2ece4ad258dda957c6cd";
    sha256 = "01wgkqb186kvycn061rmws22cw6jxjx3ixww7a6529l68vw032wq";
  };

  outputs = [ "out" "dev" ];

  postPatch = ''
    echo '${version}' > .tarball-version
  '';

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  propagatedBuildInputs = [
    #gnutls
    #libgcrypt
    (callPackage ./libplist_new.nix {enablePython=enablePython;})
    #libtasn1
    (callPackage ./libusbmuxd_new.nix {enablePython=enablePython;})
    (callPackage ./libimobiledevice-glue_new.nix {enablePython=enablePython;})
    #openssl
    ] ++ (if enablePython then [
      python3
    ] else []) ++ [
  ];

  # patches = [
  #   ./2b05e9ea4c34b62f1d32f9e348877883f2e4683f.patch
  # ];

  #configureFlags = [ "--disable-openssl" "--without-cython" ];
  #configureFlags = [ ''PACKAGE_VERSION=${version}'' ];
  configureFlags = [ "--enable-debug" ];
  
  #preConfigure = ''
  #  export PACKAGE_VERSION="${version}"
  #  echo "AAAAAAAAAAAA:" $PACKAGE_VERSION
  #'';

  #preConfigure = "./autogen.sh --enable-debug";

  meta = with lib; {
    homepage = "https://github.com/libimobiledevice/libimobiledevice";
    description = "A software library that talks the protocols to support iPhone®, iPod Touch® and iPad® devices on Linux";
    longDescription = ''
      libimobiledevice is a software library that talks the protocols to support
      iPhone®, iPod Touch® and iPad® devices on Linux. Unlike other projects, it
      does not depend on using any existing proprietary libraries and does not
      require jailbreaking. It allows other software to easily access the
      device's filesystem, retrieve information about the device and it's
      internals, backup/restore the device, manage SpringBoard® icons, manage
      installed applications, retrieve addressbook/calendars/notes and bookmarks
      and synchronize music and video to the device. The library is in
      development since August 2007 with the goal to bring support for these
      devices to the Linux Desktop.
    '';
    license = licenses.lgpl21Plus;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ infinisil ];
  };
}

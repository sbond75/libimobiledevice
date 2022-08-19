{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, libtool
, pkg-config
, gnutls
, libgcrypt
, libtasn1
, glib
, libplist
, libusbmuxd
, callPackage
, openssl
}:

stdenv.mkDerivation rec {
  pname = "libimobiledevice";
  version = "unstable-2022-5-10";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "dec0438c89a020995229b08aeaee96c403c5daed";
    sha256 = "0awz7w3qza9izc5ifr439idajdzf0b0iqlyia8ac005213x7k5h5";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    autoreconfHook
    libtool
    pkg-config
  ];

  propagatedBuildInputs = [
    glib
    gnutls
    libgcrypt
    libplist
    libtasn1
    #libusbmuxd
    #(enableDebugging (callPackage ./libusbmuxd.nix {}))
    (callPackage ./libusbmuxd.nix {})
    (callPackage ./libimobiledevice-glue.nix {})
    openssl
  ];

  patches = [
    #./2b05e9ea4c34b62f1d32f9e348877883f2e4683f.patch
  ];

  #configureFlags = [ "--disable-openssl" "--without-cython" ];
  configureFlags = [ ''PACKAGE_VERSION=${version}'' "--enable-debug" ];

  dontStrip = true;
  
  #preConfigure = ''
  #  export PACKAGE_VERSION="${version}"
  #  echo "AAAAAAAAAAAA:" $PACKAGE_VERSION
  #'';

  #preConfigure = "./autogen.sh --enable-debug";

  patchPhase = ''
    substituteInPlace src/idevice.c --replace 'if (res > 0) {' 'printf("usbmuxd_get_device returned: %d\n", res); if (res > 0) {' \

    substituteInPlace common/debug.c --replace "void internal_set_debug_level(int level)
    {" "void internal_set_debug_level(int level) { libusbmuxd_set_debug_level(level > 1 ? 99 : level); // (This requires debug level 2 or higher for libusbmuxd logs to show and uses 99 as an arbitrary large number. Tip: in the usbmuxd2 command line, use `-debug -debug` to get debug level of 2)"
    # (^last `--replace` is optional)
  '';
      
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

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
, libusb
, git
, autoconf
, avahi
}:

stdenv.mkDerivation rec {
  pname = "usbmuxd2";
  version = "753b79eaf317c56df6c8b1fb6da5847cc54a0bb0";

  src = fetchFromGitHub {
    owner = "tihmstar";
    repo = pname;
    rev = "753b79eaf317c56df6c8b1fb6da5847cc54a0bb0";
    sha256 = "0n3xgqj03vwf1wvp9iz2vil4s5lhc7q5svp17mfmmh49lgffvmjg";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    autoreconfHook
    libtool
    pkg-config
    git
    autoconf
    (callPackage ./libgeneral.nix {})
  ];

  propagatedBuildInputs = [
    glib
    libusb
    (callPackage ./libimobiledevice.nix {})
    libplist
    libusbmuxd
    (callPackage ./libimobiledevice-glue.nix {})
    avahi
  ];

  patchPhase = ''
    #git clone --bare https://github.com/tihmstar/libgeneral.git .git

    substituteInPlace configure.ac \
      --replace "m4_esyscmd([git rev-list --count HEAD | tr -d '\n'])" 46 \
      --replace "m4_esyscmd([git rev-parse HEAD | tr -d '\n'])" 753b79eaf317c56df6c8b1fb6da5847cc54a0bb0 \
      --replace "PKG_CHECK_MODULES(libimobiledevice, libimobiledevice-1.0 >= 1.2.1, have_limd=yes, have_limd=no)" "have_limd=yes" \
      --replace "CXXFLAGS+=\" -std=c++17\"" "
        CXXFLAGS+=\" -std=c++17\"
        LDFLAGS+=\" $($PKG_CONFIG --libs libimobiledevice-1.0) -limobiledevice-1.0\"
      " #AC_MSG_ERROR([$($PKG_CONFIG --list-all 2>&1)]) #<--doesn't work for testing purposes

      #--replace "udev/Makefile" "" \
      #--replace "systemd/Makefile" ""

    substituteInPlace usbmuxd2/Muxer.cpp \
      --replace "#include \"Muxer.hpp\"" "
        #include \"Muxer.hpp\"
        #include \"Manager/WIFIDeviceManager-avahi.hpp\"
      "
    substituteInPlace usbmuxd2/Manager/WIFIDeviceManager.cpp \
      --replace "#include \"WIFIDeviceManager.hpp\"" "
        #include \"WIFIDeviceManager.hpp\"
        #include \"Manager/WIFIDeviceManager-avahi.hpp\"
      "
  '';

  #configureFlags = [ "--disable-openssl" "--without-cython" ];
  #configureFlags = [ "--with-udevrulesdir=${out}/lib/udev" ];

  preConfigure = ''
    configureFlags="$configureFlags --with-udevrulesdir=$out/lib/udev/rules.d"
    configureFlags="$configureFlags --with-systemdsystemunitdir=$out/lib/systemd/system"
    #configureFlags="$configureFlags --with-libimobiledevice"
  '';

  meta = with lib; {
    homepage = "https://github.com/tihmstar/usbmuxd2";
    platforms = platforms.linux ++ platforms.darwin;
  };
}


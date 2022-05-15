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
      --replace "m4_esyscmd([git rev-parse HEAD | tr -d '\n'])" 753b79eaf317c56df6c8b1fb6da5847cc54a0bb0
  '';

  #configureFlags = [ "--disable-openssl" "--without-cython" ];

  meta = with lib; {
    homepage = "https://github.com/tihmstar/usbmuxd2";
    platforms = platforms.linux ++ platforms.darwin;
  };
}


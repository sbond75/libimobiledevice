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
  pname = "libgeneral";
  version = "63-017d71edb0a12ff4fa01a39d12cd297d8b3d8d34";

  src = fetchFromGitHub {
    owner = "tihmstar";
    repo = pname;
    rev = "017d71edb0a12ff4fa01a39d12cd297d8b3d8d34";
    sha256 = "013j7ckcxf903jjbxfqz0hpczbaaamj1q4r6hqd7qywa2zyabd1n";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    autoreconfHook
    libtool
    pkg-config
  ];

  propagatedBuildInputs = [
    glib
  ];

  patchPhase = ''
    #git clone --bare https://github.com/tihmstar/libgeneral.git .git

    substituteInPlace configure.ac \
      --replace "m4_esyscmd([git rev-list --count HEAD | tr -d '\n'])" 63 \
      --replace "m4_esyscmd([git rev-parse HEAD | tr -d '\n'])" 017d71edb0a12ff4fa01a39d12cd297d8b3d8d34
  '';

  #configureFlags = [ "--disable-openssl" "--without-cython" ];

  meta = with lib; {
    homepage = "https://github.com/tihmstar/libgeneral";
    platforms = platforms.linux ++ platforms.darwin;
  };
}


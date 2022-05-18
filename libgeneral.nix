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

    # Optional, fixes what appears to be a potential bug/race condition since the mutex isn't locked for this variable despite it being locked seemingly for it elsewhere: #
    substituteInPlace libgeneral/Event.cpp \
      --replace "uint64_t Event::members() const{" "uint64_t Event::members() const{ std::unique_lock<std::mutex> lk(_m);"
    substituteInPlace include/libgeneral/Event.hpp \
      --replace "std::mutex _m;" "mutable std::mutex _m;" # https://stackoverflow.com/questions/48133164/how-to-use-a-stdlock-guard-without-violating-const-correctness
    # #
  '';

  #configureFlags = [ "--disable-openssl" "--without-cython" ];

  meta = with lib; {
    homepage = "https://github.com/tihmstar/libgeneral";
    platforms = platforms.linux ++ platforms.darwin;
  };
}


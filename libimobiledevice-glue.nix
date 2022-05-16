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
}:

stdenv.mkDerivation rec {
  pname = "libimobiledevice-glue";
  version = "unstable-2022-4-22"; #"unstable-2021-11-25";

  src = fetchFromGitHub {
    owner = "libimobiledevice";
    repo = pname;
    rev = "c2e237ab5449b42461639c8e1eabbc61d0c386b7"; #"3cb687baa8e69fbf57c5e05f4865184eb44abf67";
    sha256 = "1l80fp685qh1xqvk55xh74s7pb9z99kifcnq13sm2pkszy4by5sq"; #"17q9n07fnj3q8fy09wp38zsh8wkpwp64pk662xyqb96mwc2rmhqg";
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
    libusbmuxd
    libtool
  ];

  meta = with lib; {
    homepage = "https://github.com/libimobiledevice/libimobiledevice-glue";
    description = "A library with common code used by libraries and tools around the libimobiledevice project";
    license = licenses.lgpl21Plus;
    platforms = platforms.linux ++ platforms.darwin;
    #maintainers = with maintainers; [ infinisil ];
  };
}

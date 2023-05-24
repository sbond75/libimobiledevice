# Based on https://github.com/NixOS/nixpkgs/blob/nixos-22.11/pkgs/development/libraries/libusbmuxd/default.nix#L36

{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, pkg-config
, libplist
, callPackage
, enablePython ? false
}:

stdenv.mkDerivation rec {
  pname = "libusbmuxd";
  version = "2.0.2+date=2023-04-30";

  src = fetchFromGitHub {
    owner = "libimobiledevice";
    repo = pname;
    rev = "f47c36f5bd2a653a3bd7fb1cf1d2c50b0e6193fb";
    sha256 = "1kh934z346hv8jnlyh3mgi6bjhff63lids3f7x5x4w957la6fcd2";
  };

    postPatch = ''
    echo '${version}' > .tarball-version
  '';

    nativeBuildInputs = [
      autoreconfHook
      pkg-config
    ];

    buildInputs = [
      (callPackage ./libplist_new.nix {enablePython=enablePython;})
      (callPackage ./libimobiledevice-glue_new.nix {})
    ];

    meta = with lib; {
      description = "A client library to multiplex connections from and to iOS devices";
      homepage = "https://github.com/libimobiledevice/libusbmuxd";
      license = licenses.lgpl21Plus;
      platforms = platforms.unix;
      maintainers = with maintainers; [ infinisil ];
    };
}

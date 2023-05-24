# Based on https://github.com/NixOS/nixpkgs/blob/nixos-22.11/pkgs/development/libraries/libimobiledevice-glue/default.nix#L33

{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, pkg-config
, callPackage
, enablePython ? false
}:

stdenv.mkDerivation rec {
  pname = "libimobiledevice-glue";
  version = "1.0.0+date=2023-05-12";

  outputs = [ "out" "dev" ];

  postPatch = ''
    echo '${version}' > .tarball-version
  '';
  
  src = fetchFromGitHub {
    owner = "libimobiledevice";
    repo = pname;
    rev = "214bafdde6a1434ead87357afe6cb41b32318495";
    sha256 = "1pvdg98q5djdl36f1sy980z5pvcmns407xx2cm5sl44y6a221pr1";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  propagatedBuildInputs = [
    (callPackage ./libplist_new.nix {enablePython=enablePython;})
  ];

  meta = with lib; {
    homepage = "https://github.com/libimobiledevice/libimobiledevice-glue";
    description = "Library with common code used by the libraries and tools around the libimobiledevice project.";
    license = licenses.lgpl21Plus;
    platforms = platforms.unix;
    maintainers = with maintainers; [ infinisil ];
  };
}

# Based on https://github.com/NixOS/nixpkgs/blob/nixos-22.11/pkgs/development/libraries/libplist/default.nix#L47

{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, pkg-config

, enablePython ? false
, python3
}:

stdenv.mkDerivation rec {
  pname = "libplist";
  version = "2.3.0+date=2023-05-14";

  outputs = [ "bin" "dev" "out" ] ++ lib.optional enablePython "py";

  src = fetchFromGitHub {
    owner = "libimobiledevice";
    repo = pname;
    rev = "21a432bc746e9d3897d4972a9c17ee99b0c1ecc0";
    sha256 = "1kx94jcl65mz46x2q2baknxyjrdvqjswbzy08hdb80jgc3gcmf41";
  };

    postPatch = ''
    echo '${version}' > .tarball-version
  '';

    nativeBuildInputs = [
      autoreconfHook
      pkg-config
    ];

    buildInputs = lib.optionals enablePython [
      python3
      python3.pkgs.cython
    ];

    configureFlags = lib.optionals (!enablePython) [
      "--without-cython"
    ];

      postFixup = lib.optionalString enablePython ''
    moveToOutput "lib/${python3.libPrefix}" "$py"
  '';

      meta = with lib; {
        description = "A library to handle Apple Property List format in binary or XML";
        homepage = "https://github.com/libimobiledevice/libplist";
        license = licenses.lgpl21Plus;
        maintainers = with maintainers; [ infinisil ];
        platforms = platforms.unix;
      };
}

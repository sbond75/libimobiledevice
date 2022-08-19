# Based on https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/development/libraries/libusbmuxd/default.nix#L18

{ lib, stdenv, fetchFromGitHub, autoreconfHook, pkg-config, libplist }:

stdenv.mkDerivation rec {
  pname = "libusbmuxd";
  version = "unstable-2021-02-06";

  src = fetchFromGitHub {
    owner = "libimobiledevice";
    repo = pname;
    rev = "3eb50a07bad4c2222e76df93b23a0161922150d1";
    sha256 = "sha256-pBPBgE6s8JYKJYEV8CcumNki+6jD5r7HzQ0nZ8yQLdM=";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config ];
  buildInputs = [ libplist ];

  #configureFlags = [ "--enable-debug" ];
  #configureFlags = [ "'CXXFLAGS=-O0 -g'" ];
  
  dontStrip = true;

  patchPhase = ''
    substituteInPlace include/usbmuxd-proto.h --replace "/var/run/usbmuxd" "/var/run/usbmuxd.d/usbmuxd" # Optional, corresponds to the custom usbmuxd implementation in usbmuxd2.nix
  '';

  meta = with lib; {
    description = "A client library to multiplex connections from and to iOS devices";
    homepage    = "https://github.com/libimobiledevice/libusbmuxd";
    license     = licenses.lgpl21Plus;
    platforms   = platforms.linux ++ platforms.darwin;
    maintainers = with maintainers; [ infinisil ];
  };
}

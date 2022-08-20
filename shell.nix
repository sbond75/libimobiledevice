{ pkgs ? import (builtins.fetchTarball { # https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs :
  # Descriptive name to make the store path easier to identify
  name = "nixos-unstable-2020-09-03";
  # Commit hash for nixos-unstable as of the date above
  url = "https://github.com/NixOS/nixpkgs/archive/702d1834218e483ab630a3414a47f3a537f94182.tar.gz";
  # Hash obtained using `nix-prefetch-url --unpack <url>`
  sha256 = "1vs08avqidij5mznb475k5qb74dkjvnsd745aix27qcw55rm0pwb";
}) { }}:
with pkgs;

mkShell {
  buildInputs = [
    #(callPackage ./libimobiledevice.nix {})
    #(enableDebugging (callPackage ./libimobiledevice_unstable-2021-11-24.nix {}))
    (callPackage ./libimobiledevice_unstable-2021-11-24.nix {})
    #libimobiledevice
    
    #usbmuxd
    #(enableDebugging (callPackage ./usbmuxd2.nix {}))
    (callPackage ./usbmuxd2.nix {})
    pkg-config
  ];
}

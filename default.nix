{ nixpkgs ? import <nixpkgs> { } }:

nixpkgs.mkShell rec {
  buildInputs = [ nixpkgs.clang-tools nixpkgs.zig nixpkgs.zls ];
}

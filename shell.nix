{ pkgs ? import <nixpkgs> { } }:

with pkgs;

mkShell { buildInputs = [ urbit nodejs ]; }

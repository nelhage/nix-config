{ config, pkgs, ... }:
{
  home.file.bin = {
    target = "bin";
    recursive = true;
    source = ./bin;
  };
}

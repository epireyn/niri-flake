{ lib, config, ... }:
{
  options.niri-flake.cache.enable = lib.mkEnableOption "the niri-flake binary cache" // {
    default = true;
  };

  config = lib.mkIf config.niri-flake.cache.enable {
    nix.settings = {
      substituters = [ "https://niri-epireyn.cachix.org" ];
      trusted-public-keys = [ "niri-epireyn.cachix.org-1:tlVyFN7CtsDT+ZcLPS+ekFWeT1X6X4OqvWqbBMyIzFA=" ];
    };
  };
}

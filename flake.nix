{
  description = "Home Manager modules to declaratively manage TF2 mods (budhud, mastercomfig)";

  # Only used for budhud's image converter Python (Pillow + srctools), so a
  # nixpkgs update can't silently change how menu backgrounds are converted.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    homeManagerModules = {
      budhud = { lib, pkgs, ... }: {
        imports = [ ./modules/budhud ];
        programs.budhud.python = lib.mkDefault
          (nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.python3.withPackages
            (p: [ p.pillow p.srctools ]));
      };
      mastercomfig = ./modules/mastercomfig;
      default = {
        imports = [ self.homeManagerModules.budhud self.homeManagerModules.mastercomfig ];
      };
    };
  };
}

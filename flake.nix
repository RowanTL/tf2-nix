{
  description = "Home Manager modules to declaratively manage TF2 mods (budhud, mastercomfig, tf2-preload)";

  # Only used for the Python (Pillow, srctools, valve_parsers) behind budhud's
  # image converter and tf2-preload's VPK and particle builders, so a nixpkgs
  # update can't silently change their output.
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
      tf2-preload = { lib, pkgs, ... }: {
        imports = [ ./modules/tf2-preload ];
        programs.tf2-preload.python = lib.mkDefault
          (nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.python3.withPackages
            (p: [ p.srctools (p.callPackage ./modules/tf2-preload/valve-parsers.nix { }) ]));
      };
      default = {
        imports = [
          self.homeManagerModules.budhud
          self.homeManagerModules.mastercomfig
          self.homeManagerModules.tf2-preload
        ];
      };
    };
  };
}

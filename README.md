# Overview

Home-manager modules to declaratively manage Team Fortress 2 mods:

| Module | Manages | Docs |
| --- | --- | --- |
| `programs.budhud` | [budhud](https://github.com/rbjaxter/budhud) | [docs/budhud.md](docs/budhud.md) |
| `programs.mastercomfig` | [mastercomfig](https://github.com/mastercomfig/mastercomfig) | [docs/mastercomfig.md](docs/mastercomfig.md) |
| `programs.tf2-preload` | Custom VPKs (reskins), preloaded like [casual-pre-loader](https://github.com/cueki/casual-pre-loader) | [docs/tf2-preload.md](docs/tf2-preload.md) |

# Usage

At the top of `flake.nix` in your inputs:

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  tf2-nix.url = "github:RowanTL/tf2-nix";
};
```

Place `imports = [ tf2-nix.homeManagerModules.default ];` somewhere under your `home-manager.users.<username>`,
and you're ready to configure. `default` imports every module; nothing is installed until you set
`programs.<module>.enable = true`. To import only one, use `tf2-nix.homeManagerModules.budhud`,
`tf2-nix.homeManagerModules.mastercomfig` or `tf2-nix.homeManagerModules.tf2-preload` (which also needs
mastercomfig).

The flake pins its own nixpkgs, which is only used for the Python (Pillow and srctools) that converts
budhud's [`menuBackground`](docs/budhud.md#menu-background) images and repacks tf2-preload's VPKs. Don't set `inputs.nixpkgs.follows` on it
unless you want that to follow your nixpkgs instead.

You can also use it without the flake: add the input with `flake = false;` and import
`"${tf2-nix}/modules/budhud"`, `"${tf2-nix}/modules/mastercomfig"` and/or `"${tf2-nix}/modules/tf2-preload"`.
That Python then comes from your own `pkgs`.

A basic example is:

```nix
programs.mastercomfig = {
  enable = true;
  preset = "low";
  addons = [ "no-pyroland" "null-canceling-movement" ];
};

programs.budhud = {
  enable = true;
  customizations = {
    player_boxes = true;
    menu_hidenews = true;
  };
};
```

budhud and mastercomfig default to the Steam install at `.local/share/Steam/steamapps/common/Team Fortress 2/tf`.
If yours is elsewhere, set `tfDir` on each of them you use; tf2-preload uses mastercomfig's.

See the docs for each module's full set of options:

- [budhud](docs/budhud.md)
- [mastercomfig](docs/mastercomfig.md)
- [tf2-preload](docs/tf2-preload.md)

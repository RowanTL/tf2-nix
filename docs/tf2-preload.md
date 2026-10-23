# tf2-preload

`programs.tf2-preload` installs custom VPKs, such as weapon reskins, and preloads them the way
[casual-pre-loader](https://github.com/cueki/casual-pre-loader) does, so they keep working on `sv_pure`
servers. It requires [`programs.mastercomfig`](mastercomfig.md), whose autoexec runs the preload and
whose `tfDir` it uses. See the [README](../README.md#usage) for how to add the module to your configuration.

A basic example is:

```nix
programs.mastercomfig.enable = true;

programs.tf2-preload = {
  enable = true;
  # Every .vpk in this folder of your configuration repo.
  vpkDir = ./tf2-mods;
  # Or one at a time, from a file or a download.
  vpks = {
    shovel.source = ./shovel.vpk;
    rocket-launcher = {
      url = "https://example.com/rocket-launcher.vpk";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };
};
```

Get a download's `hash` with `nix store prefetch-file <url>`. For a mod that comes as a zip, unpack it
with `fetchzip` and point `source` at the VPK inside:
`source = "${pkgs.fetchzip { url = "..."; hash = "..."; stripRoot = false; }}/shovel.vpk";`.

## Options

All options live under `programs.tf2-preload`.

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Install and preload the VPKs. |
| `vpkDir` | `null` or path | `null` | Folder of VPKs. Each `<name>.vpk`, or split `<name>_dir.vpk` with its `_000` chunks, is installed as `custom/<name>.vpk`. |
| `vpks` | attrs of submodules | `{ }` | VPKs installed as `custom/<name>.vpk`. Each needs `source`, or `url` and `hash`. |
| `autoexec` | bool | `true` | Run the preload from mastercomfig's autoexec. Set to `false` to run `exec tf2-preload` yourself, e.g. as the launch option `+exec tf2-preload`. |
| `map` | string | `"itemtest"` | Offline map loaded to cache the assets. |
| `python` | package | Python with srctools | Python used to repack the VPKs. The flake's module sets this from its pinned nixpkgs. |

## How it works

- **Build.** Each VPK is repacked into a single-file VPK in the Nix store, then linked into `custom/`.
  Like casual-pre-loader, the repack blanks any `$ignorez 1`, which makes things render through walls.
  It also adds a VMT for every texture under `materials/models/weapons/` or `materials/patterns/` that
  doesn't have one. That VMT is copied from the game's own when there is one (taken from
  [gametracking-tf2](https://github.com/ReplayCoding/gametracking-tf2)); otherwise it's a generic one.
  The build log lists every change.
- **Activation.** Every `home-manager switch` comments out `type multiplayer_only` in
  `tf/gameinfo.txt`. Steam puts the line back when it updates the game or verifies its files, so switch
  again after either. Disabling the module doesn't restore the line; verify the game files in Steam to do
  that.
- **Startup.** The last line of mastercomfig's `app/autoexec.cfg` runs `exec tf2-preload`, which runs
  `sv_pure -1; map itemtest; wait 10; disconnect`. Assets loaded on that offline map stay cached when you
  join a server.

## Notes

- mastercomfig's `restore_config` and `apply_overrides` aliases rerun the autoexec, and with it the
  preload. Running either while on a server disconnects you.
- Particles (`.pcf`) aren't supported, since casual-pre-loader has to patch those into the game's own
  VPKs to get past `sv_pure`.
- casual-pre-loader's own installer can be used alongside this module. It only replaces its own
  `_casual_preloader*.vpk` files.
- Competitive leagues may not allow modified assets. Check their rules.

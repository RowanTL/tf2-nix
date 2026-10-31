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
If the URL doesn't end in `.zip`, add `extension = "zip";`. For a RAR, use `extension = "rar";` and
`nativeBuildInputs = [ pkgs.unar ];`; if the RAR has several files at its top level, unar unpacks them
into a folder named after the download, usually `download/`.

## Particles

Particle mods (`.pcf`) only get past `sv_pure` from the game's own `tf2_misc_dir.vpk`, so they're patched
into it in place, like casual-pre-loader does. Pick which vanilla particle files to replace and which mod
to take each from:

```nix
programs.tf2-preload = {
  enable = true;
  particleMods.toon-explosions.source = "${pkgs.fetchzip {
    url = "https://gamebanana.com/dl/39707";
    extension = "rar";
    nativeBuildInputs = [ pkgs.unar ];
    stripRoot = false;
    hash = "sha256-yrnpQ6KzMNheem2bkWlSgLA7vaomULRGt4BTwBS6CRQ=";
  }}/download/toon_explosions_v1.1.vpk";
  # explosion.pcf has the rocket, stickybomb and grenade explosions.
  particles.explosion = "toon-explosions";
};
```

A key of `particles` is a vanilla particle file without `.pcf`, or one of casual-pre-loader's groups:
`explosions`, `fire`, `bullets`, `blood`, `weapons`, `maps`, `game_modes`, `unusuals_hats`,
`unusual_weapons`, `player`, `buildings` or `misc` (see `PARTICLE_GROUP_MAPPING` in its
[`core/constants.py`](https://github.com/cueki/casual-pre-loader/blob/main/core/constants.py)). If the mod
has nothing for a key, the build fails and lists the particle files it does have.

## Options

All options live under `programs.tf2-preload`.

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Install and preload the VPKs. |
| `vpkDir` | `null` or path | `null` | Folder of VPKs. Each `<name>.vpk`, or split `<name>_dir.vpk` with its `_000` chunks, is installed as `custom/<name>.vpk`. |
| `vpks` | attrs of submodules | `{ }` | VPKs installed as `custom/<name>.vpk`. Each needs `source`, or `url` and `hash`. |
| `autoexec` | bool | `true` | Run the preload from mastercomfig's autoexec. Set to `false` to run `exec tf2-preload` yourself, e.g. as the launch option `+exec tf2-preload`. |
| `map` | string | `"itemtest"` | Offline map loaded to cache the assets. |
| `particleMods` | attrs of submodules | `{ }` | Particle mods, for `particles`. Each needs `source` (a VPK or an unpacked mod folder), or `url` and `hash` of a VPK. |
| `particles` | attrs of strings | `{ }` | Vanilla particle files or groups to replace, each mapped to a `particleMods` name. See [Particles](#particles). |
| `casualPreLoader` | path | casual-pre-loader, pinned | casual-pre-loader's source, whose particle code, particle map and vanilla particle files build and restore `particles`. It has to match the installed game. |
| `python` | package | Python with srctools and valve_parsers | Python used to build the VPKs and particles. The flake's module sets this from its pinned nixpkgs. |

## How it works

- **Build.** Each VPK is repacked into a single-file VPK in the Nix store, then linked into `custom/`.
  Like casual-pre-loader, the repack blanks any `$ignorez 1`, which makes things render through walls.
  It also adds a VMT for every texture under `materials/models/weapons/` or `materials/patterns/` that
  doesn't have one. That VMT is copied from the game's own when there is one (taken from
  [gametracking-tf2](https://github.com/ReplayCoding/gametracking-tf2)); otherwise it's a generic one.
  The build log lists every change.
- **Particle build.** casual-pre-loader's own code (imported from `casualPreLoader`, not copied, since
  it's GPL-3.0) splits each particle mod's systems by the vanilla file they belong to and fills in the
  rest from the vanilla files. The selected files are compressed and padded to exactly the vanilla size;
  the build fails if one is still too big. Like casual-pre-loader, `item_fx`, `halloween`, `bigboom`
  and `dirty_explode` are always rewritten without their copies of other files' systems, so those don't
  override the mod, and the materials the selected particles use go in `custom/tf2-preload-particles.vpk`.
- **Activation.** Every `home-manager switch` comments out `type multiplayer_only` in
  `tf/gameinfo.txt`. Steam puts the line back when it updates the game or verifies its files, so switch
  again after either. Disabling the module doesn't restore the line; verify the game files in Steam to do
  that.
- **Particle activation.** Every switch also patches the built particle files into `tf2_misc_dir.vpk`
  and restores deselected ones from casual-pre-loader's vanilla copies. It only overwrites a file that is
  still that vanilla copy or what it last wrote, recorded in `~/.local/state/tf2-preload/particles.json`.
  After a TF2 update replaces one, it's left alone with a warning until `casualPreLoader` (or tf2-nix)
  is updated to vanilla files matching the new game. Verifying the game files in Steam also undoes the
  patch; switch again afterwards. Disabling the whole module leaves the files patched, so set
  `particles = { }` and switch first, or verify the game files.
- **Startup.** The last line of mastercomfig's `app/autoexec.cfg` runs `exec tf2-preload`, which runs
  `sv_pure -1; map itemtest; wait 10; disconnect`. Assets loaded on that offline map stay cached when you
  join a server.

## Notes

- mastercomfig's `restore_config` and `apply_overrides` aliases rerun the autoexec, and with it the
  preload. Running either while on a server disconnects you.
- Patching while TF2 is running isn't blocked, but the game only reads the new particles on its next
  start.
- casual-pre-loader's own installer can be used alongside this module for everything but particles. Both
  patch `tf2_misc_dir.vpk`, so after it installs particles this module sees them as a TF2 update and
  leaves those files alone.
- Competitive leagues may not allow modified assets. Check their rules.

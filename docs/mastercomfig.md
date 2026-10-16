# mastercomfig

`programs.mastercomfig` declaratively manages [mastercomfig](https://github.com/mastercomfig/mastercomfig),
installing it the same way the [comfig.app](https://comfig.app) downloader does, pinned to a release.
See the [README](../README.md#usage) for how to add the module to your configuration.

A basic example is:

```nix
programs.mastercomfig = {
  enable = true;
  preset = "low";
  addons = [ "no-pyroland" "null-canceling-movement" ];
};
```

## Options

All options live under `programs.mastercomfig`.

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Install mastercomfig. |
| `tfDir` | string | `.local/share/Steam/steamapps/common/Team Fortress 2/tf` | Path to the game's `tf` directory, relative to the home directory. |
| `preset` | `null` or one of the presets below | `"medium"` | Base preset. `null` selects the website's "custom" preset (no preset line is written). |
| `addons` | list of addons | `[]` | Addons to install. |
| `modules` | attrs of strings | `{ }` | Module overrides, written to `cfg/overrides/modules.cfg`. |
| `binds` | attrs of string or list of strings | `{ }` | Key binds. |
| `bindLayers` | attrs of binds | `{ }` | Binds that only apply in a class or custom layer. |
| `crosshairs` | submodule | `{ }` | Crosshair color, scale, and weapon crosshairs. |
| `classes` | submodule | `{ }` | Extra commands run when a class is selected. |
| `gameOverrides` | lines | `""` | Extra commands run at the start of every game. |
| `autoexec` | lines | `""` | Extra commands run at the end of startup. |

### Presets

| Preset | Description |
| --- | --- |
| `ultra` | Highest quality. |
| `high` | High quality. |
| `medium` | Balanced (default). |
| `low` | Low quality, higher FPS. |
| `destitute` | Lowest quality, for very weak hardware. |

### Addons

| Addon | Description |
| --- | --- |
| `flat-mouse` | Flat mouse input: stable input, no acceleration, and 1:1 zoom sensitivity. |
| `lowmem` | Optimizations for low memory (2GB RAM and lower) systems that generally don't affect quality. |
| `no-footsteps` | Removes footstep sounds. |
| `no-pyroland` | Removes Pyroland map textures. |
| `no-soundscapes` | Removes soundscapes (ambient map noise) and bird noises. |
| `no-tutorial` | Disables tutorial messages and other popups. |
| `null-canceling-movement` | Pressing two opposing directions no longer stops you. Also switches the movement actions in `binds` to the null-canceling versions. |
| `transparent-viewmodels` | Enables support for transparent viewmodels. |

### Modules

`modules` is an attribute set of `module = "value"` pairs, for example
`modules = { lod = "high"; sound = "low"; decals = "off"; };`.
Modules not set here follow the selected preset. See the
[mastercomfig module docs](https://docs.comfig.app/latest/customization/modules/)
for what each level does and its CPU/GPU cost.

`sound = "low"` and `decals = "off"` are baked into an extra `override-N` addon, like the website does,
so they are installed automatically.

| Category | Module | Values |
| --- | --- | --- |
| Networking | `packet_rate` | `congestion`, `standard` |
| | `snapshot_buffer` | `auto`, `off`, `x1`, `x2`, `custom`, `anim` |
| | `packet_size` | `small`, `conservative`, `large` |
| | `bandwidth` | `128Kbps`, `192Kbps`, `384Kbps`, `512Kbps`, `762Kbps`, `1.0Mbps`, `1.5Mbps`, `2.0Mbps`, `2.5Mbps`, `3.0Mbps`, `4.0Mbps`, `6.0Mbps` |
| | `download` | `custom`, `all`, `nosounds`, `mapsonly`, `nothing` |
| Graphics | `lod` | `low`, `medium`, `high`, `ultra` |
| | `lighting` | `very_low`, `low`, `medium`, `high`, `ultra` |
| | `shading` | `low`, `medium`, `high` |
| | `phong` | `off`, `on`, `rim` |
| | `shadows` | `off`, `low`, `medium`, `high`, `ultra` |
| | `flashlight` | `off`, `on` |
| | `effects` | `very_low`, `low`, `medium`, `high`, `ultra` |
| | `tracers` | `low`, `medium`, `high` |
| | `water` | `very_low`, `low`, `medium`, `high`, `ultra` |
| | `post_processing` | `off`, `low`, `default`, `calm`, `vivid`, `washed`, `dreamy` |
| | `color_filter` | `off`, `grayscale`, `desaturated`, `warm`, `cool` |
| | `pyrovision` | `low`, `medium`, `high` |
| | `romevision` | `off`, `on` |
| | `motion_blur` | `off`, `low`, `high` |
| | `anti_aliasing` | `off`, `msaa_2x`, `msaa_4x`, `msaa_8x` |
| | `characters` | `very_low`, `low`, `medium`, `high` |
| | `decals` | `off`, `low`, `medium`, `high`, `ultra` |
| | `decals_models` | `off`, `low`, `medium`, `high` |
| | `decals_art` | `off`, `on` |
| | `sprays` | `off`, `on`, `keep` |
| | `gibs` | `off`, `low`, `high` |
| | `sillygibs` | `auto`, `off`, `on` |
| | `props` | `low`, `high`, `ultra` |
| | `ragdolls` | `off`, `medium`, `high` |
| | `3dsky` | `off`, `on` |
| | `jigglebones` | `off`, `on`, `force_on` |
| | `sheens_speed` | `off`, `slow`, `medium`, `fast` |
| | `sheens_tint` | `low`, `medium`, `high`, `full` |
| | `texture_quality` | `low`, `medium`, `high`, `very_high`, `ultra` |
| | `texture_filter` | `blocky`, `trilinear`, `aniso2x`, `aniso4x`, `aniso8x`, `aniso16x` |
| | `ropes` | `off`, `low`, `high`, `ultra` |
| | `fpscap` | `powersaver`, `30`, `60`, `75`, `120`, `144`, `160`, `165`, `180`, `200`, `240`, `300`, `360`, `400`, `1000`, `unlimited` |
| | `vsync` | `off`, `on` |
| | `outlines` | `off`, `low`, `medium`, `high`, `ultra` |
| HUD | `hud_player_model` | `off`, `on` |
| | `hud_server_text` | `off`, `on` |
| | `hud_contracts` | `custom`, `hide`, `all`, `active` |
| | `hud_panels` | `off`, `low`, `high` |
| | `hud_avatars` | `off`, `everyone`, `friends` |
| | `match_hud` | `off`, `on` |
| | `messages` | `off`, `hide`, `on` |
| | `killfeed` | `off`, `on` |
| | `killstreaks` | `off`, `low`, `high` |
| | `hud_achievement` | `off`, `on` |
| | `console` | `off`, `on` |
| | `htmlmotd` | `off`, `on` |
| Misc | `dynamic_background` | `off`, `dustbowl` |
| | `sound` | `low`, `medium`, `high`, `very_high`, `ultra` |
| | `voice_chat` | `off`, `hidden`, `on` |
| | `party_mode` | `open`, `request`, `invite` |
| | `logo` | `off`, `on` |

### Binds

`binds` maps a Source engine key name (`w`, `mouse4`, `kp_enter`, `semicolon`, ...) to one of:

| Value | Meaning |
| --- | --- |
| A comfig.app action name, e.g. `"Move Forward"`, `"Weapon slot 1"`, `"Call MEDIC!"` | Resolved to its console command. The full list is `actionMappings` in [`modules/mastercomfig/default.nix`](../modules/mastercomfig/default.nix). |
| A raw console command, e.g. `"say_team ubered"` | Bound as written (double quotes are stripped). |
| A list of the above, e.g. `[ "Jump" "Duck" ]` | Run together on the same key. |
| `"unbind"` | Unbinds the key. |

`bindLayers` takes the same values, grouped by layer name:

| Layer name | When it applies |
| --- | --- |
| `scout`, `soldier`, `pyro`, `demoman`, `heavy`, `engineer`, `medic`, `sniper`, `spy` | While playing that class. |
| Anything else (letters, digits, underscores) | While a key bound to `+layer_<name>` is held. |

Keys bound in a layer revert to their `binds` value (or are unbound) on every class change.

```nix
programs.mastercomfig = {
  binds = {
    w = "Move Forward";
    a = "Move Left";
    r = "Move Back";
    s = "Move Right";
    mouse4 = [ "Jump" "Duck" ];
    shift = "+layer_alt"; # hold shift for the "alt" layer
  };
  bindLayers = {
    medic = { mouse3 = "voicemenu 1 6"; };
    alt = { e = "Weapon slot 3"; };
  };
};
```

### Crosshairs

| Option | Type | Description |
| --- | --- | --- |
| `crosshairs.color` | `{ default, scout, ..., spy }`, each `{ r, g, b, a = 255; }` (0-255) | Crosshair color, as a default and/or per class. |
| `crosshairs.scale` | `{ default, scout, ..., spy }`, each a positive int | `cl_crosshair_scale`, as a default and/or per class. |
| `crosshairs.weapons` | attrs of strings | Weapon crosshairs, applied by overriding weapon scripts like comfig.app does. |
| `crosshairs.zoom` | attrs of strings | Zoomed crosshairs for sniper rifles, same values as `weapons`. |

#### Weapon crosshair targets

The keys of `crosshairs.weapons`, from lowest to highest precedence:

| Target | Applies to |
| --- | --- |
| `default` | Every weapon. |
| `default_slot_<Slot>` | Every weapon in a slot. |
| `default_<class>`, `default_<class>_<Slot>` | Every weapon of a class, optionally in one slot. |
| `default_all`, `default_all_actionitem`, `default_all_utility` | All-class items. |
| A weapon classname, e.g. `tf_weapon_rocketlauncher` | That weapon class. |

Slots are `Primary`, `Secondary`, `Melee`, `PDA`, `Building`, `Action Item` and `Utility`.

#### Weapon crosshair values

| Value | Meaning |
| --- | --- |
| A [comfig.app crosshair texture](https://github.com/mastercomfig/comfig-app/tree/main/public/assets/app/crosshairs) name, e.g. `crosshair5OL` | Use that texture. |
| `none` | No crosshair. |
| `sprites/crosshairs.<key>` | A stock sprite. `<key>` is one of `_64_64` (large circle), `_32_32` (circle), `_64_0` (sniper), `_64_-1` (sniper center fix), `_0_64` (medic cross), `_0_0` (brackets) or `_0_48` (square bracket). |

```nix
programs.mastercomfig.crosshairs = {
  color.default = { r = 0; g = 255; b = 0; };
  scale.soldier = 24;
  weapons = {
    default = "crosshair5OL";
    default_slot_Melee = "none";
    tf_weapon_rocketlauncher = "tob_rocketcross";
  };
  zoom.tf_weapon_sniperrifle = "sprites/crosshairs._64_-1";
};
```

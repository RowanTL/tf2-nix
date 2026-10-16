# budhud

`programs.budhud` declaratively manages [budhud](https://github.com/rbjaxter/budhud).
See the [README](../README.md#usage) for how to add the module to your configuration.

The HUD is built in the Nix store with your customizations applied, then linked to
`tf/custom/budhud`. Toggling a customization moves its file into `#customization/_enabled`
for you, the same way the budhud wiki tells you to move it by hand.

A basic example is:

```nix
programs.budhud = {
  enable = true;
  customizations = {
    player_boxes = true;
    menu_hidenews = true;
  };
};
```

> [!IMPORTANT]
> If you already have a `tf/custom/budhud` folder, delete it first. home-manager won't overwrite it.
>
> The installed HUD is read-only. Change it through these options, not by editing files in `tf/custom/budhud`.

## Options

All options live under `programs.budhud`.

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Install budhud. |
| `tfDir` | string | `.local/share/Steam/steamapps/common/Team Fortress 2/tf` | Path to the game's `tf` directory, relative to the home directory. |
| `src` | path | budhud release `2511_01` | budhud source tree. See [Using a newer budhud](#using-a-newer-budhud). |
| `customizations` | attrs of bool | see below | Customizations to enable. |
| `crosshairs` | list of crosshairs (max 3) | `[]` | HUD crosshairs. |
| `menuBackground` | `null` or path to a `.png`, `.jpg`/`.jpeg` or `.vtf` | `null` | Main menu background image. |
| `python` | package | pinned by the flake (see the [README](../README.md#usage)) | Python with Pillow and srctools, used to convert `menuBackground`. |
| `streamMode` | bool | `false` | Streamer HUD: hides player names. |
| `userPreset` | `null` or one of `dane`, `jayhyunpae`, `powah`, `truktruk`, `whisker`, `zenith` | `null` | Enable a contributor's HUD variant from `#users`. |
| `language` | `null` or a language | `null` | Show HUD text in this language while the game is in English. |
| `customFiles` | attrs of `{ text; source; }` | `{ }` | Your own override files, placed in `#users/custom`. |

### Customizations

Each name is budhud's file name in `#customization` without the `bh_` prefix and extension.
Set it to `true` to enable it or `false` to disable it. The ones marked **on** are enabled by default, like upstream.

| Customization | Default | Description |
| --- | --- | --- |
| `animate_foreground` | | Animate the health and ammo numbers themselves when buffed or low. |
| `animate_hidedisguiseanimation` | | Hide the Spy disguise animation. |
| `chat_lowerleft` | | Move chat to the lower left. |
| `chat_upperleft` | | Move chat to the upper left. |
| `crosshairs` | **on** | HUD crosshair panels. Required by `crosshairs`. |
| `crosshairs_tf2crosshairs` | **on** | TF2Crosshairs fonts used by the HUD crosshairs. Required by `crosshairs`. |
| `crosshairs_fog` | | Fog's legacy crosshair fonts. |
| `crosshairs_knuckles` | | Knuckles' legacy crosshair fonts. |
| `crosshairs_whayay` | | whayay's legacy crosshair fonts. |
| `feeling_festive` | | Festive main menu. |
| `feeling_spooky` | | Spooky main menu. |
| `game_hidecontracker` | | Hide the contract tracker. |
| `matchstatus_6v6` | | Larger match status player panels, sized for 6v6. |
| `medic_rainbowcharge` | | Rainbow ÜberCharge meter. |
| `menu_defaultbackground` | | Use TF2's default main menu backgrounds. |
| `menu_hidefavorites` | **on** | Hide the server favorites on the main menu. |
| `menu_hidefriends` | | Hide the friends list on the main menu. |
| `menu_hidegif` | | Hide the main menu background image. |
| `menu_hidenews` | | Hide the news on the main menu. |
| `menu_hidestats` | | Hide the stats on the main menu. |
| `player_boxes` | | Boxes behind health, ammo and über. |
| `player_centereddamagedone` | | Center the damage done number. |
| `player_healthcross` | | Health cross next to your health. Use at most one health cross. |
| `player_healthcross_inset` | | Health cross with your health inside it. Use at most one health cross. |
| `player_hideclassmodel` | | Hide the class model in the bottom left. |
| `player_hidedamageindicator` | | Hide the directional damage indicator. |
| `player_hidestaticdamage` | | Hide the static damage done number. |
| `player_largeammo` | | Larger ammo numbers. |
| `player_largehealth` | | Larger health numbers. |
| `player_showcontrolpointprogressbar` | | Show the control point progress bar. |
| `player_showvoiceavatars` | | Show avatars next to voice chat names. |
| `player_teamindicator` | | Team colored bar along the bottom of the screen. |
| `player_transparentviewmodels` | | Transparent viewmodels (DX9+). May also need `exec bh_transparentviewmodels`. |
| `player_uicentered` | | Centered player UI. Marked work in progress upstream. |
| `speedometer` | | Show a speedometer. |
| `stats_customimage` | | Use the map background image on the loading/stats screen. |
| `stats_hidebackground` | | Hide the loading/stats screen background. |
| `stats_hideloadingstats` | | Hide the stats on the loading screen. |
| `targetid_depleting` | **on** | Depleting health bar on target IDs. Must be off for `targetid_healthcross`. |
| `targetid_healthcross` | | Health cross on target IDs. Requires `targetid_depleting = false`. |
| `targetid_largehealth` | | Larger health numbers on target IDs. |
| `targetid_showavatars` | | Show avatars on target IDs. |
| `tournamentpanels_lowered` | | Lower the tournament spectator player panels. |
| `uber_largeuberpercentage` | | Larger über percentage. |
| `uber_longchargemeter` | | Longer über charge meter. |
| `uber_percentagenearcrosshair` | | Über percentage below the crosshair (broken with the Vaccinator). |

### Crosshairs

`crosshairs` is a list of up to three crosshairs, which become budhud's `hud_crosshair_1` to `hud_crosshair_3`.
The characters are shown in `#customization/_enabled/Unified Crosshairs.png` inside the HUD folder.

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `character` | single character | required | TF2Crosshairs character to draw. |
| `size` | int, 10-30 | `17` | Crosshair font size. |
| `outline` | bool | `true` | Draw an outline around the crosshair. |
| `color` | `{ r, g, b, a = 255; }` (0-255) | white | Crosshair color. |
| `flashColor` | `{ r, g, b, a = 255; }` (0-255) | `240 134 49` | Crosshair color when you deal damage. |
| `xpos`, `ypos` | `null` or string | `null` | Override the crosshair's position, e.g. `"cs-0.4999"`. |

```nix
programs.budhud.crosshairs = [
  { character = "F"; size = 18; color = { r = 0; g = 255; b = 0; }; }
];
```

These are separate from the game's own crosshair, so set `crosshair 0` if you only want the HUD one
(for example in [`programs.mastercomfig.autoexec`](mastercomfig.md)).

The crosshairs are written to `#users/custom/#customization/_enabled/bh_crosshairs.res` and
`#users/custom/resource/clientscheme_custom.res`. You can't also set those two files in `customFiles`;
if you want to write them yourself, leave `crosshairs` empty.

### Menu background

```nix
programs.budhud.menuBackground = ./wallpaper.png;
```

PNG and JPG images are converted to a VTF (Source's texture format) when the HUD is built. A `.vtf` is used as is.

- Each side is resized to the nearest power of two (a 1920x1080 image becomes 2048x1024), which VTFs require.
  The HUD stretches it back over the whole screen, so it looks the same in game.
- Transparent areas are filled with black.
- The texture is uncompressed (about 8 MB at 2048x1024) and keeps full quality at any texture quality setting.

The image is installed at `materials/vgui/replay/thumbnails/tf2-nix/menu_background` inside the HUD, so
servers with `sv_pure` still allow it. It's shown through `#users/custom/resource/ui/mainmenuoverride.res`, so you
can't also set that file in `customFiles`. It can't be combined with `menu_defaultbackground`, `menu_hidegif`,
`feeling_spooky` or `feeling_festive`, which all replace or hide the menu background.

### Custom files

`customFiles` puts your own files in `#users/custom`, which budhud loads before everything else. Paths
mirror the HUD folder. Use `text` for inline contents, or `source` for a file or directory.

```nix
programs.budhud.customFiles = {
  "resource/clientscheme_custom.res".text = ''
    Scheme
    {
        Colors
        {
            "bh_Health_Buff"    "0 200 255 255"
        }
    }
  '';
  "resource/ui/hudplayerhealth.res".source = ./hudplayerhealth.res;
};
```

Useful paths include `resource/clientscheme_custom.res` (colors and fonts), `resource/ui/<file>.res`,
`scripts/hudlayout.res`, `scripts/hudanimations_custom.txt` and `#customization/_enabled/<customization file>`
(your own version of a customization).

### Streamer HUD

`streamMode = true` renames `_stream_` to `_stream`, which hides player names. To also hide chat and
voice chat, run `exec bh_stream_on` (and `exec bh_stream_off` to undo it).

### Config files

budhud's configs in `cfg/` (`bh_recommendedcommands`, `bh_captions`, `bh_transparentviewmodels`, ...)
can be run with `exec <name>`. budhud also ships a `valve.rc`, which still runs your `autoexec.cfg`, so it
works alongside [`programs.mastercomfig`](mastercomfig.md).

## Using a newer budhud

The module is pinned to budhud release `2511_01`. To follow `master` instead, add it as an input and pass it
to `src`:

```nix
inputs.budhud-src = {
  url = "github:rbjaxter/budhud";
  flake = false;
};
```

```nix
programs.budhud.src = budhud-src;
```

The build fails with a clear message if a customization you enabled no longer exists in that source.

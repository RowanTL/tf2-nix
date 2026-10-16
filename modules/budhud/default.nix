# Home Manager module that installs budhud declaratively, pinned to a release,
# doing the folder shuffling the wiki asks for (moving customizations into
# `_enabled`, renaming `_stream_` and `#users/<name>_`) at build time.
#
# Layout produced (relative to `programs.budhud.tfDir`):
#   custom/budhud/                                  (read-only symlink into the store)
#   custom/budhud/#customization/_enabled/<customization>
#   custom/budhud/#users/custom/<customFiles>
#   custom/budhud/materials/vgui/replay/thumbnails/tf2-nix/menu_background.{vtf,vmt}
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.budhud;

  version = "2511_01";

  # GitHub's tarball honours budhud's export-ignore rules, so this matches the
  # release's budhud.zip.
  defaultSrc = pkgs.fetchFromGitHub {
    owner = "rbjaxter";
    repo = "budhud";
    rev = version;
    hash = "sha256-Bgc+jC1uBGAs6un8mEClKNuWQmuzC0aDLqnOnDwzFmQ=";
  };

  # Everything that can be dropped into `#customization/_enabled`.
  # `src` is relative to the HUD root; `dst` is the name the HUD's #base and
  # manifest entries look for, when it differs from the source name.
  customizationList = {
    animate_foreground = { src = "#customization/bh_animate_foreground.txt"; description = "Animate the health and ammo numbers themselves when buffed or low."; };
    animate_hidedisguiseanimation = {
      src = "#customization/bh_animate_hidedisguiseanimation.txt";
      # The manifest loads this name; the shipped file name is never loaded.
      dst = "bh_spy_hidedisguiseicon.txt";
      description = "Hide the Spy disguise animation.";
    };
    chat_lowerleft = { src = "#customization/bh_chat_lowerleft.res"; description = "Move chat to the lower left."; };
    chat_upperleft = { src = "#customization/bh_chat_upperleft.res"; description = "Move chat to the upper left."; };
    crosshairs = { src = "#customization/_enabled/bh_crosshairs.res"; default = true; description = "HUD crosshair panels. Required by `programs.budhud.crosshairs`."; };
    crosshairs_tf2crosshairs = { src = "#customization/_enabled/bh_crosshairs_tf2crosshairs.res"; default = true; description = "TF2Crosshairs fonts used by the HUD crosshairs. Required by `programs.budhud.crosshairs`."; };
    crosshairs_fog = { src = "#customization/bh_crosshairs_fog.res"; description = "Fog's legacy crosshair fonts."; };
    crosshairs_knuckles = { src = "#customization/bh_crosshairs_knuckles.res"; description = "Knuckles' legacy crosshair fonts."; };
    crosshairs_whayay = { src = "#customization/bh_crosshairs_whayay.res"; description = "whayay's legacy crosshair fonts."; };
    feeling_festive = { src = "#customization/bh_feeling_festive.res"; description = "Festive main menu."; };
    feeling_spooky = { src = "#customization/bh_feeling_spooky.res"; description = "Spooky main menu."; };
    game_hidecontracker = { src = "#customization/bh_game_hidecontracker.res"; description = "Hide the contract tracker."; };
    matchstatus_6v6 = { src = "#customization/bh_matchstatus_6v6.res"; description = "Larger match status player panels, sized for 6v6."; };
    medic_rainbowcharge = { src = "#customization/bh_medic_rainbowcharge.txt"; description = "Rainbow ÜberCharge meter."; };
    menu_defaultbackground = { src = "#customization/bh_menu_defaultbackground"; description = "Use TF2's default main menu backgrounds."; };
    menu_hidefavorites = { src = "#customization/_enabled/bh_menu_hidefavorites.res"; default = true; description = "Hide the server favorites on the main menu."; };
    menu_hidefriends = { src = "#customization/bh_menu_hidefriends.res"; description = "Hide the friends list on the main menu."; };
    menu_hidegif = { src = "#customization/bh_menu_hidegif.res"; description = "Hide the main menu background image."; };
    menu_hidenews = { src = "#customization/bh_menu_hidenews.res"; description = "Hide the news on the main menu."; };
    menu_hidestats = { src = "#customization/bh_menu_hidestats.res"; description = "Hide the stats on the main menu."; };
    player_boxes = { src = "#customization/bh_player_boxes"; description = "Boxes behind health, ammo and über."; };
    player_centereddamagedone = { src = "#customization/bh_player_centereddamagedone.res"; description = "Center the damage done number."; };
    player_healthcross = { src = "#customization/bh_player_healthcross.res"; description = "Health cross next to your health. Use at most one health cross."; };
    player_healthcross_inset = { src = "#customization/bh_player_healthcross_inset.res"; description = "Health cross with your health inside it. Use at most one health cross."; };
    player_hideclassmodel = { src = "#customization/bh_player_hideclassmodel.res"; description = "Hide the class model in the bottom left."; };
    player_hidedamageindicator = { src = "#customization/bh_player_hidedamageindicator.res"; description = "Hide the directional damage indicator."; };
    player_hidestaticdamage = { src = "#customization/bh_player_hidestaticdamage.res"; description = "Hide the static damage done number."; };
    player_largeammo = { src = "#customization/bh_player_largeammo.res"; description = "Larger ammo numbers."; };
    player_largehealth = { src = "#customization/bh_player_largehealth.res"; description = "Larger health numbers."; };
    player_showcontrolpointprogressbar = { src = "#customization/bh_player_showcontrolpointprogressbar.res"; description = "Show the control point progress bar."; };
    player_showvoiceavatars = { src = "#customization/bh_player_showvoiceavatars.res"; description = "Show avatars next to voice chat names."; };
    player_teamindicator = { src = "#customization/bh_player_teamindicator.res"; description = "Team colored bar along the bottom of the screen."; };
    player_transparentviewmodels = { src = "#customization/bh_player_transparentviewmodels.res"; description = "Transparent viewmodels (DX9+). May also need `exec bh_transparentviewmodels`."; };
    player_uicentered = {
      src = "#customization/WIPbh_player_uicentered";
      dst = "bh_player_uicentered";
      description = "Centered player UI. Marked work in progress upstream.";
    };
    speedometer = { src = "#customization/bh_speedometer.res"; description = "Show a speedometer."; };
    stats_customimage = { src = "#customization/bh_stats_customimage.res"; description = "Use the map background image on the loading/stats screen."; };
    stats_hidebackground = { src = "#customization/bh_stats_hidebackground.res"; description = "Hide the loading/stats screen background."; };
    stats_hideloadingstats = { src = "#customization/bh_stats_hideloadingstats.res"; description = "Hide the stats on the loading screen."; };
    targetid_depleting = { src = "#customization/_enabled/bh_targetid_depleting.res"; default = true; description = "Depleting health bar on target IDs. Must be off for `targetid_healthcross`."; };
    targetid_healthcross = { src = "#customization/bh_targetid_healthcross"; description = "Health cross on target IDs. Requires `targetid_depleting = false`."; };
    targetid_largehealth = { src = "#customization/bh_targetid_largehealth.res"; description = "Larger health numbers on target IDs."; };
    targetid_showavatars = { src = "#customization/bh_targetid_showavatars.res"; description = "Show avatars on target IDs."; };
    tournamentpanels_lowered = { src = "#customization/bh_tournamentpanels_lowered.res"; description = "Lower the tournament spectator player panels."; };
    uber_largeuberpercentage = { src = "#customization/bh_uber_largeuberpercentage.res"; description = "Larger über percentage."; };
    uber_longchargemeter = { src = "#customization/bh_uber_longchargemeter.res"; description = "Longer über charge meter."; };
    uber_percentagenearcrosshair = { src = "#customization/bh_uber_percentagenearcrosshair.res"; description = "Über percentage below the crosshair (broken with the Vaccinator)."; };
  };

  userPresets = [ "dane" "jayhyunpae" "powah" "truktruk" "whisker" "zenith" ];

  languages = [
    "brazilian"
    "czech"
    "finnish"
    "french"
    "german"
    "italian"
    "japanese"
    "norwegian"
    "polish"
    "romanian"
    "russian"
    "schinese"
    "spanish"
    "tchinese"
    "turkish"
    "ukrainian"
  ];

  enabledCustomizations = lib.filterAttrs (n: _: cfg.customizations.${n}) customizationList;

  colorString = c: "${toString c.r} ${toString c.g} ${toString c.b} ${toString c.a}";

  # VDF block with one `"key" "value"` line per attribute.
  vdfBlock = indent: name: attrs:
    let pad = lib.fixedWidthString indent " " ""; in
    "${pad}\"${name}\"\n${pad}{\n"
    + lib.concatStrings (lib.mapAttrsToList (k: v: "${pad}    \"${k}\"    \"${v}\"\n") attrs)
    + "${pad}}\n";

  crosshairPanel = i: c: vdfBlock 4 "hud_crosshair_${toString i}" ({
    visible = "1";
    enabled = "1";
    labeltext = c.character;
    font = "Crosshair: TF2Crosshairs | Size: ${toString c.size} | Outline: ${if c.outline then "On" else "Off"}";
  }
  // lib.optionalAttrs (c.xpos != null) { inherit (c) xpos; }
  // lib.optionalAttrs (c.ypos != null) { inherit (c) ypos; });

  crosshairColors = lib.concatStrings (lib.imap1
    (i: c: ''
      "hud_crosshair_${toString i}"    "${colorString c.color}"
      "hud_crosshair_${toString i}_flash"    "${colorString c.flashColor}"
    '')
    cfg.crosshairs);

  # Overrides layered on top of budhud's own crosshair files via #users/custom.
  generatedFiles = lib.optionalAttrs (cfg.crosshairs != [ ]) {
    "#customization/_enabled/bh_crosshairs.res".text =
      "\"Resource/UI/HudPlayerClass.res\"\n{\n"
      + lib.concatStrings (lib.imap1 crosshairPanel cfg.crosshairs)
      + "}\n";
    "resource/clientscheme_custom.res".text =
      "Scheme\n{\n    Colors\n    {\n"
      + lib.concatMapStrings (l: "        ${l}\n") (lib.splitString "\n" (lib.removeSuffix "\n" crosshairColors))
      + "    }\n}\n";
  };

  # Under replay/thumbnails so sv_pure servers still allow it.
  backgroundMaterial = "replay/thumbnails/tf2-nix/menu_background";

  backgroundExt = lib.toLower (lib.last (lib.splitString "." (baseNameOf cfg.menuBackground)));

  backgroundFiles = lib.optionalAttrs (cfg.menuBackground != null) {
    # Every #base after #users/custom loses to this, so it beats budhud's own image
    # and `menu_hidegif`'s hiding of the panel.
    "resource/ui/mainmenuoverride.res".text = ''
      "Resource/UI/MainMenuOverride.res"
      {
          "MainMenuOverride"
          {
          }
      ${vdfBlock 4 "Background" { visible = "1"; enabled = "1"; ypos = "0"; image = backgroundMaterial; }}}
    '';
  };

  backgroundVmt = pkgs.writeText "menu_background.vmt" ''
    "UnlitGeneric"
    {
        "$baseTexture"    "vgui/${backgroundMaterial}"
        "$translucent"    "0"
        "$vertexcolor"    "1"
        "$vertexalpha"    "1"
    }
  '';

  menuSeasonalCustomizations = [ "menu_defaultbackground" "feeling_spooky" "feeling_festive" "menu_hidegif" ];

  generatedNames = lib.attrNames generatedFiles ++ lib.attrNames backgroundFiles;

  usersCustomFiles = generatedFiles // backgroundFiles // cfg.customFiles;

  customFileSource = name: f:
    if f.source or null != null then f.source else pkgs.writeText (baseNameOf name) f.text;

  sh = lib.escapeShellArg;

  hud = pkgs.runCommand "budhud-${version}" { } ''
    cp -r --no-preserve=mode ${sh "${cfg.src}"} "$out"
    cd "$out"

    # Rebuild _enabled from only the selected customizations.
    rm -rf '#customization/_enabled/'bh_*
    ${lib.concatStrings (lib.mapAttrsToList (n: c: ''
      if [ ! -e ${sh "${cfg.src}/${c.src}"} ]; then
        echo ${sh "budhud: customization '${n}' (${c.src}) is missing from the HUD source"} >&2
        exit 1
      fi
      cp -r --no-preserve=mode ${sh "${cfg.src}/${c.src}"} ${sh "#customization/_enabled/${c.dst or (baseNameOf c.src)}"}
    '') enabledCustomizations)}
    ${lib.optionalString cfg.streamMode ''
      mv _stream_ _stream
    ''}
    ${lib.optionalString (cfg.userPreset != null) ''
      mv ${sh "#users/${cfg.userPreset}_"} ${sh "#users/${cfg.userPreset}"}
    ''}
    ${lib.optionalString (cfg.language != null) ''
      cp ${sh "resource/chat_${cfg.language}.txt"} resource/chat_english.txt
    ''}
    ${lib.optionalString (cfg.menuBackground != null) ''
      mkdir -p ${sh "materials/vgui/${dirOf backgroundMaterial}"}
      ${if backgroundExt == "vtf" then ''
        cp ${sh "${cfg.menuBackground}"} ${sh "materials/vgui/${backgroundMaterial}.vtf"}
      '' else ''
        ${cfg.python.interpreter} -I ${./image-to-vtf.py} ${sh "${cfg.menuBackground}"} ${sh "materials/vgui/${backgroundMaterial}.vtf"}
      ''}
      cp ${backgroundVmt} ${sh "materials/vgui/${backgroundMaterial}.vmt"}
    ''}
    ${lib.concatStrings (lib.mapAttrsToList (name: f: ''
      mkdir -p "$(dirname ${sh "#users/custom/${name}"})"
      cp -r --no-preserve=mode ${sh "${customFileSource name f}"} ${sh "#users/custom/${name}"}
    '') usersCustomFiles)}
  '';

  colorType = lib.types.submodule {
    options = {
      r = lib.mkOption { type = lib.types.ints.u8; description = "Red."; };
      g = lib.mkOption { type = lib.types.ints.u8; description = "Green."; };
      b = lib.mkOption { type = lib.types.ints.u8; description = "Blue."; };
      a = lib.mkOption { type = lib.types.ints.u8; default = 255; description = "Alpha."; };
    };
  };

  crosshairType = lib.types.submodule {
    options = {
      character = lib.mkOption {
        type = lib.types.strMatching ".";
        example = "F";
        description = ''
          TF2Crosshairs character to draw. See `#customization/_enabled/Unified Crosshairs.png`
          in the budhud source for the available characters.
        '';
      };
      size = lib.mkOption {
        type = lib.types.ints.between 10 30;
        default = 17;
        description = "Crosshair font size.";
      };
      outline = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Draw an outline around the crosshair.";
      };
      color = lib.mkOption {
        type = colorType;
        default = { r = 255; g = 255; b = 255; };
        description = "Crosshair color.";
      };
      flashColor = lib.mkOption {
        type = colorType;
        default = { r = 240; g = 134; b = 49; };
        description = "Crosshair color when you deal damage.";
      };
      xpos = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "cs-0.4999";
        description = "Override the crosshair's `xpos`.";
      };
      ypos = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "cs-0.4990";
        description = "Override the crosshair's `ypos`.";
      };
    };
  };

  customFileType = lib.types.submodule {
    options = {
      text = lib.mkOption {
        type = lib.types.nullOr lib.types.lines;
        default = null;
        description = "File contents.";
      };
      source = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "File or directory to copy. Takes precedence over `text`.";
      };
    };
  };
in
{
  options.programs.budhud = {
    enable = lib.mkEnableOption "budhud TF2 HUD";

    tfDir = lib.mkOption {
      type = lib.types.str;
      default = ".local/share/Steam/steamapps/common/Team Fortress 2/tf";
      description = "Path to the game's `tf` directory, relative to the home directory.";
    };

    src = lib.mkOption {
      type = lib.types.path;
      default = defaultSrc;
      defaultText = lib.literalMD "budhud release `${version}` from GitHub";
      description = "budhud source tree, e.g. a flake input tracking `master`.";
    };

    customizations = lib.mkOption {
      type = lib.types.submodule {
        options = lib.mapAttrs
          (_: c: lib.mkOption {
            type = lib.types.bool;
            default = c.default or false;
            inherit (c) description;
          })
          customizationList;
      };
      default = { };
      example = { player_boxes = true; menu_hidefavorites = false; };
      description = ''
        Customizations to move into `#customization/_enabled`. Names are budhud's
        file names without the `bh_` prefix and extension. `crosshairs`,
        `crosshairs_tf2crosshairs`, `menu_hidefavorites` and `targetid_depleting`
        are on by default, like upstream.
      '';
    };

    crosshairs = lib.mkOption {
      type = lib.types.listOf crosshairType;
      default = [ ];
      example = [ { character = "F"; size = 18; color = { r = 0; g = 255; b = 0; }; } ];
      description = ''
        Up to three HUD crosshairs (`hud_crosshair_1` to `hud_crosshair_3`). Written to
        `#users/custom/#customization/_enabled/bh_crosshairs.res` and
        `#users/custom/resource/clientscheme_custom.res`. Remember to hide the game's
        crosshair (`crosshair 0`) if you don't want both.
      '';
    };

    menuBackground = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./wallpaper.png";
      description = ''
        Main menu background image: a PNG or JPG (converted to a VTF at build time,
        with each side resized to the nearest power of two) or a ready-made VTF.
        Written to `materials/vgui/${backgroundMaterial}` and
        `#users/custom/resource/ui/mainmenuoverride.res`.
      '';
    };

    python = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python3.withPackages (p: [ p.pillow p.srctools ]);
      defaultText = lib.literalExpression "pkgs.python3.withPackages (p: [ p.pillow p.srctools ])";
      description = ''
        Python with Pillow and srctools, used to convert `menuBackground`. The flake's
        module sets this from its own pinned nixpkgs.
      '';
    };

    streamMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable the streamer HUD, which hides player names (renames `_stream_` to
        `_stream`). Pair with `exec bh_stream_on` to also hide chat and voice.
      '';
    };

    userPreset = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum userPresets);
      default = null;
      description = "Enable one of the contributor HUD variants in `#users`.";
    };

    language = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum languages);
      default = null;
      description = ''
        Use this translation for HUD text while the game is in English (copies
        `chat_<language>.txt` over `chat_english.txt`, like the updater script).
      '';
    };

    customFiles = lib.mkOption {
      type = lib.types.attrsOf customFileType;
      default = { };
      example = lib.literalExpression ''
        {
          "resource/clientscheme_custom.res".text = '''
            Scheme
            {
                Colors
                {
                    "bh_Health_Buff"    "0 200 255 255"
                }
            }
          ''';
          "resource/ui/hudplayerhealth.res".source = ./hudplayerhealth.res;
        }
      '';
      description = ''
        Files placed in `#users/custom`, budhud's folder for personal overrides. These
        take priority over the rest of the HUD. Paths mirror the HUD root, e.g.
        `resource/ui/<file>.res`, `scripts/hudlayout.res`,
        `scripts/hudanimations_custom.txt` or `#customization/_enabled/<file>`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.customizations.targetid_healthcross && cfg.customizations.targetid_depleting);
        message = "programs.budhud.customizations: targetid_healthcross requires targetid_depleting = false.";
      }
      {
        assertion = lib.length cfg.crosshairs <= 3;
        message = "programs.budhud.crosshairs: budhud has at most 3 HUD crosshairs.";
      }
      {
        assertion = cfg.crosshairs == [ ] || (cfg.customizations.crosshairs && cfg.customizations.crosshairs_tf2crosshairs);
        message = "programs.budhud.crosshairs requires customizations.crosshairs and customizations.crosshairs_tf2crosshairs.";
      }
      {
        assertion = cfg.menuBackground == null || lib.elem backgroundExt [ "png" "jpg" "jpeg" "vtf" ];
        message = "programs.budhud.menuBackground must be a .png, .jpg, .jpeg or .vtf file.";
      }
    ] ++ map
      (n: {
        assertion = cfg.menuBackground == null || !cfg.customizations.${n};
        message = "programs.budhud.menuBackground can't be used with customizations.${n}, which also changes the main menu background.";
      })
      menuSeasonalCustomizations
    ++ map
      (name: {
        assertion = !(cfg.customFiles ? ${name});
        message = "programs.budhud.customFiles.\"${name}\" conflicts with a file generated by programs.budhud.${if generatedFiles ? ${name} then "crosshairs" else "menuBackground"}; write that setting into your file instead.";
      })
      generatedNames
    ++ lib.mapAttrsToList
      (name: f: {
        assertion = f.text != null || f.source != null;
        message = "programs.budhud.customFiles.\"${name}\" needs `text` or `source`.";
      })
      cfg.customFiles;

    home.file."${cfg.tfDir}/custom/budhud".source = hud;
  };
}

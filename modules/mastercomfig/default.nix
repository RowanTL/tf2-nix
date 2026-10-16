# Home Manager module that installs mastercomfig the same way the comfig.app
# downloader does, but declaratively and pinned to a release.
#
# Layout produced (relative to `programs.mastercomfig.tfDir`):
#   custom/mastercomfig-base.vpk
#   custom/mastercomfig-addon-<name>.vpk
#   custom/comfig-custom/cfg/app/{setup_hook,addons,autoexec,...}.cfg
#   custom/comfig-custom/scripts/tf_weapon_<name>.txt
#   custom/comfig-custom/materials/vgui/replay/thumbnails/<crosshair>.{vtf,vmt}
#   cfg/overrides/modules.cfg
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.mastercomfig;

  version = "9.100.1";

  releaseUrl = "https://github.com/mastercomfig/mastercomfig/releases/download/${version}";

  hashes = {
    base = "sha256-zavIJRhkoasu9/f/7RtE9SgQlW5HbWIYO41+PpYNhlA=";
    flat-mouse = "sha256-mQkpxHNn2Z+riys7s0pbBViJHkQnUcnk0r2vo8QVG60=";
    lowmem = "sha256-qTSFcyNdps6PRYNtqkvtNeJY2HwGEsbd89yfp4UCc/c=";
    no-footsteps = "sha256-7WIWwV2PnwRM79I7vOdfRggQi/NUS+6GHkAAyo8ap2I=";
    no-pyroland = "sha256-oWI71JZnRs+w29IjrIgDl6xqtMvejlKS+ZuVpIYI97U=";
    no-soundscapes = "sha256-3+Hak/a9Cccd8Vkum7M7BEwHa4oz+rNw+OaSja2+RNk=";
    no-tutorial = "sha256-QsMVR1JgBxvrz6L4zb+/rMVV1wjySUc8vbj99UPM6sM=";
    null-canceling-movement = "sha256-B3pHn80lMRN4q5hF/JSAdzDLTnyh7MNbYzMURrYmXxU=";
    transparent-viewmodels = "sha256-nsUBSsGHXM+xwecixZvhisbifLqkqSyF7kIkJFmq6ow=";
    override-1 = "sha256-xLx75WJs3SSPtoH8Qbb+TapHdEEhNsGwqUPUoHcbQYM=";
    override-2 = "sha256-VN5mdl97LGkCAm8mY3DJMsh9AdV+PZqsl9LqCtARqSg=";
    override-3 = "sha256-lqeoqowZcDAawUEfalNwYrnxJriLVkzSNLVgz6Jb25I=";
  };

  fetchVpk = name: file:
    pkgs.fetchurl {
      url = "${releaseUrl}/${file}";
      hash = hashes.${name};
    };

  # Stock weapon scripts that the website rewrites to apply weapon crosshairs.
  weaponScripts = pkgs.fetchFromGitHub {
    owner = "ReplayCoding";
    repo = "gametracking-tf2";
    rev = "ef691d8b10b15c56480f37770452db296d2c0558";
    sparseCheckout = [ "Content/tf/tf2_misc_dir/scripts" ];
    hash = "sha256-adpqd4YwbN9kYDwGRu7k1W4IDBQXm7hR9kY3JpvcN1o=";
  };

  # Crosshair textures served by the website.
  crosshairTextures = pkgs.fetchFromGitHub {
    owner = "mastercomfig";
    repo = "comfig-app";
    rev = "7dbbced1aabde70343f4a0dd1b11377ec356404b";
    sparseCheckout = [ "public/assets/app/crosshairs" ];
    hash = "sha256-K9Y+4LUN2cljMLP/cXsGohnO4dwMk417JfRayg1HMAo=";
  };

  userAddons = [
    "flat-mouse"
    "lowmem"
    "no-footsteps"
    "no-pyroland"
    "no-soundscapes"
    "no-tutorial"
    "null-canceling-movement"
    "transparent-viewmodels"
  ];

  # The website bakes "static" module values into an extra `override-N` addon:
  # bit 0 = sound=low, bit 1 = decals=off.
  staticBits =
    (if (cfg.modules.sound or null) == "low" then 1 else 0)
    + (if (cfg.modules.decals or null) == "off" then 2 else 0);

  addonNames = cfg.addons ++ lib.optional (staticBits > 0) "override-${toString staticBits}";

  classFiles = {
    scout = "scout.cfg";
    soldier = "soldier.cfg";
    pyro = "pyro.cfg";
    demoman = "demoman.cfg";
    heavy = "heavyweapons.cfg";
    engineer = "engineer.cfg";
    medic = "medic.cfg";
    sniper = "sniper.cfg";
    spy = "spy.cfg";
  };

  custom = "${cfg.tfDir}/custom";
  appCfg = "${custom}/comfig-custom/cfg/app";

  modulesText = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (n: v: "${n}=${v}") cfg.modules) + "\n";

  # Action names from the website's keybind editor.
  actionMappings = {
    "Move Forward" = "+forward";
    "Move Back" = "+back";
    "Move Left" = "+moveleft";
    "Move Right" = "+moveright";
    "Jump" = "+jump";
    "Duck" = "+duck";
    "Show scoreboard" = "+score";
    "Drop" = "dropitem";
    "Call MEDIC!" = "+helpme";
    "Push to Talk" = "+voicerecord";
    "Primary attack" = "+attack";
    "Secondary attack" = "+attack2";
    "Special attack" = "+attack3";
    "Reload weapon" = "+reload";
    "Previous weapon" = "invprev";
    "Next weapon" = "invnext";
    "Last weapon used" = "lastinv";
    "Weapon slot 1" = "slot1";
    "Weapon slot 2" = "slot2";
    "Weapon slot 3" = "slot3";
    "Weapon slot 4" = "slot4";
    "Weapon slot 5" = "slot5";
    "Weapon slot 6" = "slot6";
    "Weapon slot 7" = "slot7";
    "Weapon slot 8" = "slot8";
    "Weapon slot 9" = "slot9";
    "Weapon slot 10" = "slot10";
    "Toggle console" = "toggleconsole";
    "Switch console active" = "switchconsole";
    "Engineer: Build Sentry" = "cmd build 2 0";
    "Engineer: Destroy Sentry" = "cmd destroy 2 0";
    "Engineer: Build Dispenser" = "cmd build 0 0";
    "Engineer: Destroy Dispenser" = "cmd destroy 0 0";
    "Engineer: Build Teleporter Entrance" = "cmd build 1 0";
    "Engineer: Destroy Teleporter Entrance" = "cmd destroy 1 0";
    "Engineer: Build Teleporter Exit" = "cmd build 1 1";
    "Engineer: Destroy Teleporter Exit" = "cmd destroy 1 1";
    "Spy: Last Disguise" = "lastdisguise";
    "Spy: Toggle Disguise Team" = "disguiseteam";
    "Spy: Place Sapper" = "cmd build 3 0";
    "Chat message" = "say";
    "Team message" = "say_team";
    "Party message" = "say_party";
    "Voice Menu 1" = "voice_menu_1";
    "Voice Menu 2" = "voice_menu_2";
    "Voice Menu 3" = "voice_menu_3";
    "Change class" = "changeclass";
    "Change team" = "changeteam";
    "Kill (self)" = "cmd kill";
    "Explode (self)" = "cmd explode";
    "Open loadout" = "open_charinfo_direct";
    "Open Backpack" = "open_charinfo_backpack";
    "Open Contracts Drawer" = "show_quest_log";
    "Open Matchmaking" = "show_matchmaking";
    "Loadout Quickswitch" = "+quickswitch";
    "Loadout A" = "load_itempreset 0";
    "Loadout B" = "load_itempreset 1";
    "Loadout C" = "load_itempreset 2";
    "Loadout D" = "load_itempreset 3";
    "Action Slot" = "+use_action_slot_item";
    "Taunts" = "+taunt";
    "Weapon Taunt" = "cmd taunt";
    "Stop Taunt" = "cmd stop_taunt";
    "MvM Canteen or Taunt" = "+context_action";
    "Open Map information" = "showmapinfo";
    "Show Round information" = "+showroundinfo";
    "Call vote" = "callvote";
    "Inspect" = "+inspect";
    "Toggle viewmodel visibility" = "toggle r_drawviewmodel";
    "Toggle minimized viewmodels" = "toggle tf_use_min_viewmodels";
    "Toggle Ready" = "player_ready_toggle";
    "Spray" = "impulse 201";
    "Take screenshot" = "screenshot";
    "Save replay" = "save_replay";
    "View/Accept alert" = "cl_trigger_first_notification";
    "Remove/Decline alert" = "cl_decline_first_notification";
    "Quit Game (prompt)" = "quit prompt";
    "Quit Game (no prompt)" = "quit";
  };

  # Addons that replace the commands behind some actions.
  addonActionMappings = {
    null-canceling-movement = {
      "Move Forward" = "+mf";
      "Move Back" = "+mb";
      "Move Left" = "+ml";
      "Move Right" = "+mr";
    };
  };

  actions = lib.foldl' (acc: a: acc // (addonActionMappings.${a} or { })) actionMappings cfg.addons;

  # Action names resolve to their command; anything else is a raw command (quotes can't be nested in a bind).
  resolveBind = b:
    lib.concatMapStringsSep ";" (a: actions.${a} or (lib.replaceStrings [ "\"" ] [ "" ] a)) (lib.toList b);

  # Keep +commands usable while spectating, and stop taunts before taunting.
  keyDownReplacements = [
    { command = "+attack2"; extra = "spec_prev"; before = false; }
    { command = "+attack"; extra = "spec_next;cmd boo"; before = false; }
    { command = "+jump"; extra = "spec_mode"; before = false; }
    { command = "+strafe"; extra = "spec_autodirector 1"; before = false; }
    { command = "+taunt"; extra = "cmd stop_taunt"; before = true; }
  ];

  addKeyDownReplacements = binding: lib.concatStringsSep ";" (lib.foldl'
    (cmds: r:
      let i = lib.lists.findFirstIndex (c: c == r.command) null cmds; in
      if i == null then cmds
      else lib.take i cmds
        ++ (if r.before then [ r.extra r.command ] else [ r.command r.extra ])
        ++ lib.drop (i + 1) cmds)
    (lib.splitString ";" binding)
    keyDownReplacements);

  bindLines = binds: lib.concatStrings (lib.mapAttrsToList
    (key: binding:
      if binding == "unbind" then "unbind ${key}\n"
      # Multiple commands with +commands need a +/- alias pair so key up releases them.
      else if lib.hasInfix ";" binding && lib.hasInfix "+" binding then ''
        alias +@${key}"${addKeyDownReplacements binding}"
        alias -@${key}"${lib.replaceStrings [ "+" ] [ "-" ] binding}"
        bind ${key} +@${key}
      ''
      else if lib.hasInfix " " binding || lib.hasInfix ";" binding then ''
        bind ${key} "${addKeyDownReplacements binding}"
      ''
      else "bind ${key} ${binding}\n")
    binds);

  defaultBinds = lib.mapAttrs (_: resolveBind) cfg.binds;
  bindLayers = lib.filterAttrs (_: l: l != { })
    (lib.mapAttrs (_: lib.mapAttrs (_: resolveBind)) cfg.bindLayers);
  customLayers = lib.attrNames (removeAttrs bindLayers (lib.attrNames classFiles));
  classLayers = lib.intersectAttrs classFiles bindLayers;
  hasCustomLayers = customLayers != [ ];

  # Keys bound by any layer go back to their default bind (or get unbound) on
  # every class change, so layers don't leak between classes.
  layerResets = lib.genAttrs
    (lib.unique (lib.concatMap lib.attrNames (lib.attrValues bindLayers)))
    (key: defaultBinds.${key} or "unbind");

  releaseLayers = classReset: lib.concatMapStrings
    (l: ''alias -layer_${l}"exec app/reset_game_overrides.cfg${classReset}"'' + "\n")
    customLayers;

  # Like the website, custom layers move the binds into reset_*.cfg files so
  # releasing a layer can reapply them without rerunning everything else.
  bindFiles =
    if !hasCustomLayers then
      { "game_overrides.cfg" = bindLines layerResets; }
      // lib.mapAttrs' (c: binds: lib.nameValuePair classFiles.${c} (bindLines binds)) classLayers
    else
      {
        "autoexec.cfg" = lib.concatMapStrings
          (l: ''alias +layer_${l}"exec app/layer_${l}.cfg"'' + "\n")
          customLayers
        + releaseLayers "";
        "reset_game_overrides.cfg" = bindLines layerResets;
        "game_overrides.cfg" = releaseLayers "" + "exec app/reset_game_overrides.cfg\n";
      }
      // lib.mapAttrs' (l: binds: lib.nameValuePair "layer_${l}.cfg" (bindLines binds))
        (removeAttrs bindLayers (lib.attrNames classFiles))
      // lib.concatMapAttrs
        (c: binds: {
          "reset_${classFiles.${c}}" = bindLines binds;
          ${classFiles.${c}} = releaseLayers ";exec app/reset_${classFiles.${c}}"
            + "exec app/reset_${classFiles.${c}}\n";
        })
        classLayers;

  xh = cfg.crosshairs;
  crosshairColors = lib.filterAttrs (_: v: v != null) xh.color;
  crosshairScales = lib.filterAttrs (_: v: v != null) xh.scale;

  # A lone default goes in autoexec; otherwise the default is reapplied every
  # game so per-class values don't leak into other classes.
  perClass = values: fallback: line:
    lib.optionalAttrs (values != { }) ({
      ${if lib.attrNames values == [ "default" ] then "autoexec.cfg" else "game_overrides.cfg"} =
        line (values.default or fallback);
    }
    // lib.mapAttrs' (c: v: lib.nameValuePair classFiles.${c} (line v)) (removeAttrs values [ "default" ]));

  crosshairFiles = [
    (lib.optionalAttrs (crosshairColors != { }) { "autoexec.cfg" = "cl_crosshaircolor 5\n"; })
    (perClass crosshairColors { r = 200; g = 200; b = 200; a = 200; } (c:
      "cl_crosshair_red ${toString c.r};cl_crosshair_green ${toString c.g};"
      + "cl_crosshair_blue ${toString c.b};cl_crosshairalpha ${toString c.a}\n"))
    (perClass crosshairScales 32 (s: "cl_crosshair_scale ${toString s}\n"))
    (lib.optionalAttrs (xh.weapons != { }) { "autoexec.cfg" = ''cl_crosshair_file ""'' + "\ncrosshair 1\n"; })
  ];

  hasWeaponCrosshairs = xh.weapons != { } || xh.zoom != { };

  weaponCrosshairs = pkgs.runCommand "mastercomfig-crosshairs"
    {
      nativeBuildInputs = [ (pkgs.python3.withPackages (p: [ p.vdf ])) ];
      config = builtins.toJSON { crosshairs = xh.weapons; zoom = xh.zoom; };
      passAsFile = [ "config" ];
    } ''
    python3 ${./comfig-crosshairs.py} \
      ${weaponScripts}/Content/tf/tf2_misc_dir/scripts \
      ${crosshairTextures}/public/assets/app/crosshairs \
      "$configPath" "$out"
  '';

  userFiles =
    lib.mapAttrs' (c: text: lib.nameValuePair classFiles.${c} text) cfg.classes
    // {
      "game_overrides.cfg" = cfg.gameOverrides;
      "autoexec.cfg" = cfg.autoexec;
    };

  # Generated binds and crosshair settings first, then the user's own commands.
  appFiles = lib.filterAttrs (_: text: text != "")
    (lib.zipAttrsWith (_: lib.concatStrings) (
      [ { "autoexec.cfg" = ''echo "Managed by tf2-nix: https://github.com/RowanTL/tf2-nix"'' + "\n"; }
        { "autoexec.cfg" = bindLines defaultBinds; }
        bindFiles ]
      ++ crosshairFiles
      ++ [ (lib.mapAttrs (_: text: lib.optionalString (text != "") (text + "\n")) userFiles) ]
    ));

  bindType = lib.types.either lib.types.str (lib.types.listOf lib.types.str);

  colorType = lib.types.submodule {
    options = {
      r = lib.mkOption { type = lib.types.ints.u8; description = "Red."; };
      g = lib.mkOption { type = lib.types.ints.u8; description = "Green."; };
      b = lib.mkOption { type = lib.types.ints.u8; description = "Blue."; };
      a = lib.mkOption { type = lib.types.ints.u8; default = 255; description = "Alpha."; };
    };
  };

  perClassOption = type: what: lib.mkOption {
    type = lib.types.submodule {
      options = lib.genAttrs ([ "default" ] ++ lib.attrNames classFiles)
        (c: lib.mkOption { type = lib.types.nullOr type; default = null; description = "${what} for ${c}."; });
    };
    default = { };
  };
in
{
  options.programs.mastercomfig = {
    enable = lib.mkEnableOption "mastercomfig TF2 performance config";

    tfDir = lib.mkOption {
      type = lib.types.str;
      default = ".local/share/Steam/steamapps/common/Team Fortress 2/tf";
      description = "Path to the game's `tf` directory, relative to the home directory.";
    };

    preset = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [
        "ultra"
        "high"
        "medium"
        "low"
        "destitute"
      ]);
      default = "medium";
      description = "Base preset. `null` selects the website's \"custom\" preset (no preset line is written).";
    };

    addons = lib.mkOption {
      type = lib.types.listOf (lib.types.enum userAddons);
      default = [ ];
      description = "Addons to install.";
    };

    modules = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = { lod = "high"; sound = "low"; decals = "off"; };
      description = ''
        Module overrides written to `cfg/overrides/modules.cfg`.
        See <https://docs.comfig.app/latest/customization/modules/>.
      '';
    };

    binds = lib.mkOption {
      type = lib.types.attrsOf bindType;
      default = { };
      example = {
        w = "Move Forward";
        a = "Move Left";
        r = "Move Back";
        s = "Move Right";
        d = "unbind";
        mouse4 = [ "Jump" "Duck" ];
        f = "say_team ubered";
      };
      description = ''
        Key binds, written to `app/autoexec.cfg`. Keys are Source engine key names
        (`w`, `mouse4`, `kp_enter`, `semicolon`, ...). Values are a comfig.app
        action name (`"Move Forward"`, `"Weapon slot 1"`, ...), a raw console command,
        a list of these to run together, or `"unbind"`.

        Action names follow the selected addons, e.g. the movement actions use
        null-canceling movement when that addon is enabled.
      '';
    };

    bindLayers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf bindType);
      default = { };
      example = {
        medic = { mouse3 = "voicemenu 1 6"; };
        alt = { e = "Weapon slot 3"; };
        # Hold shift to use the "alt" layer.
        # (put `shift = "+layer_alt";` in `binds`)
      };
      description = ''
        Binds that only apply in a layer, using the same values as `binds`.
        Class layers (`scout`, ..., `spy`) apply while playing that class. Any other
        name is a custom layer, active while a key bound to `+layer_<name>` is held.
        Keys bound in a layer revert to their `binds` value (or are unbound) on every
        class change.
      '';
    };

    crosshairs = {
      color = perClassOption colorType "Crosshair color" // {
        example = { default = { r = 0; g = 255; b = 0; }; sniper = { r = 255; g = 0; b = 0; a = 200; }; };
        description = "Crosshair color (0-255 per channel), as a default and/or per class.";
      };

      scale = perClassOption lib.types.ints.positive "Crosshair scale" // {
        example = { default = 32; soldier = 24; };
        description = "Crosshair scale (`cl_crosshair_scale`), as a default and/or per class.";
      };

      weapons = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = {
          default = "crosshair5OL";
          default_slot_Melee = "none";
          default_sniper_Primary = "sprites/crosshairs._64_-1";
          tf_weapon_rocketlauncher = "tob_rocketcross";
        };
        description = ''
          Weapon crosshairs, applied by overriding weapon scripts like comfig.app does.

          Targets, from lowest to highest precedence: `default`; `default_slot_<Slot>`;
          `default_<class>` and `default_<class>_<Slot>`; `default_all`,
          `default_all_actionitem` and `default_all_utility` (all-class items); and
          weapon classnames such as `tf_weapon_rocketlauncher`. Slots are `Primary`,
          `Secondary`, `Melee`, `PDA`, `Building`, `Action Item` and `Utility`.

          Values are the name of a comfig.app crosshair texture
          (<https://github.com/mastercomfig/comfig-app/tree/main/public/assets/app/crosshairs>),
          `none`, or a stock sprite `sprites/crosshairs.<key>` where key is one of
          `_64_64` (large circle), `_32_32` (circle), `_64_0` (sniper),
          `_64_-1` (sniper center fix), `_0_64` (medic cross), `_0_0` (brackets) or
          `_0_48` (square bracket).
        '';
      };

      zoom = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = { tf_weapon_sniperrifle = "sprites/crosshairs._64_-1"; };
        description = "Zoomed crosshairs for sniper rifles, using the same values as `weapons`.";
      };
    };

    classes = lib.mkOption {
      type = lib.types.submodule {
        options = lib.mapAttrs
          (c: _: lib.mkOption { type = lib.types.lines; default = ""; description = "Commands for ${c}."; })
          classFiles;
      };
      default = { };
      example = { soldier = "viewmodel_fov 90"; medic = "bind mouse3 voicemenu 0 0"; };
      description = "Per-class commands, run when that class is selected (`app/<class>.cfg`).";
    };

    gameOverrides = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Commands run at the start of every game (`app/game_overrides.cfg`).";
    };

    autoexec = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra commands run at the end of startup (`app/autoexec.cfg`).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = map
      (l: {
        assertion = builtins.match "[A-Za-z0-9_]+" l != null;
        message = "programs.mastercomfig.bindLayers: layer name '${l}' may only contain letters, digits and underscores.";
      })
      customLayers;

    home.file = lib.mkMerge [
      { "${custom}/mastercomfig-base.vpk".source = fetchVpk "base" "mastercomfig-base.vpk"; }

      (lib.listToAttrs (map
        (a: lib.nameValuePair "${custom}/mastercomfig-addon-${a}.vpk" {
          source = fetchVpk a "mastercomfig-addon-${a}.vpk";
        })
        addonNames))

      (lib.mkIf (cfg.preset != null) {
        "${appCfg}/setup_hook.cfg".text = "preset=${cfg.preset}\n";
      })

      (lib.mkIf (cfg.addons != [ ]) {
        "${appCfg}/addons.cfg".text =
          lib.concatMapStrings (a: "exec addons/${a}.cfg\n") cfg.addons;
      })

      (lib.mapAttrs' (file: text: lib.nameValuePair "${appCfg}/${file}" { inherit text; }) appFiles)

      (lib.mkIf hasWeaponCrosshairs {
        "${custom}/comfig-custom/scripts".source = "${weaponCrosshairs}/scripts";
        "${custom}/comfig-custom/materials".source = "${weaponCrosshairs}/materials";
      })

      (lib.mkIf (cfg.modules != { }) {
        "${cfg.tfDir}/cfg/overrides/modules.cfg".text = modulesText;
      })
    ];
  };
}

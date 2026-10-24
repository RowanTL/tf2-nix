# Home Manager module that preloads custom VPKs (reskins and other materials or
# models) the way casual-pre-loader does, so they survive sv_pure:
#   * each VPK is repacked at build time (`$ignorez` blanked, missing weapon
#     VMTs added from the game's own), see ./scripts/build-vpk.py
#   * particle mods are merged into the vanilla particle files at build time by
#     casual-pre-loader's own code (./scripts/build-particles.py), and patched
#     into `tf2_misc_dir.vpk` in place on activation (./scripts/patch-particles.py)
#   * activation comments out `type multiplayer_only` in `gameinfo.txt`
#   * mastercomfig's autoexec loads an offline map with `sv_pure -1`, then
#     disconnects, so the assets stay cached
#
# Layout produced (relative to `programs.mastercomfig.tfDir`):
#   custom/<name>.vpk                         (read-only symlink into the store)
#   custom/tf2-preload-particles.vpk          (materials of the selected particles)
#   custom/tf2-preload/cfg/tf2-preload.cfg
#   gameinfo.txt                              (edited in place on activation)
#   tf2_misc_dir.vpk                          (particles patched in place on activation)
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.tf2-preload;
  tfDir = config.programs.mastercomfig.tfDir;

  # The game's VMTs, for weapon reskins that only ship a VTF. Same commit as
  # mastercomfig's weapon scripts.
  vanillaMaterials = pkgs.fetchFromGitHub {
    owner = "ReplayCoding";
    repo = "gametracking-tf2";
    rev = "ef691d8b10b15c56480f37770452db296d2c0558";
    sparseCheckout = [
      "Content/tf/tf2_misc_dir/materials/models/weapons"
      "Content/tf/tf2_misc_dir/materials/patterns"
    ];
    hash = "sha256-jRvZ8EcNoxfF/tlqKdgj4GkJaODLQSQgxpSxMrsVQjQ=";
  };

  # Every `*.vpk` in `vpkDir` except the `_000`-style chunks of split VPKs,
  # which are read alongside their `_dir.vpk`. `<name>_dir.vpk` becomes `<name>`.
  dirVpks = lib.optionalAttrs (cfg.vpkDir != null) (lib.mapAttrs'
    (file: _: lib.nameValuePair (lib.removeSuffix "_dir" (lib.removeSuffix ".vpk" file))
      "${cfg.vpkDir}/${file}")
    (lib.filterAttrs
      (file: type: type != "directory"
        && lib.hasSuffix ".vpk" file
        && builtins.match ".*_[0-9]{3}\\.vpk" file == null)
      (builtins.readDir cfg.vpkDir)));

  resolveVpks = vpks: lib.mapAttrs
    (name: v: if v.source != null then v.source else pkgs.fetchurl {
      name = "${lib.strings.sanitizeDerivationName name}.vpk";
      inherit (v) url hash;
    })
    (lib.filterAttrs (_: v: v.source != null || (v.url != null && v.hash != null)) vpks);

  allVpks = dirVpks // resolveVpks cfg.vpks;

  buildVpk = name: src: pkgs.runCommand "${lib.strings.sanitizeDerivationName name}.vpk"
    { nativeBuildInputs = [ cfg.python ]; } ''
    python3 ${./scripts}/build-vpk.py ${lib.escapeShellArg "${src}"} \
      ${vanillaMaterials}/Content/tf/tf2_misc_dir "$out"
  '';

  # The selected particle files, padded to their vanilla sizes, and the
  # materials they use. See ./scripts/build-particles.py.
  particles = pkgs.runCommand "tf2-preload-particles"
    {
      nativeBuildInputs = [ cfg.python ];
      settings = builtins.toJSON {
        mods = lib.mapAttrs (_: toString) (resolveVpks cfg.particleMods);
        selections = cfg.particles;
      };
      passAsFile = [ "settings" ];
      # casual-pre-loader collects particle systems in sets, so their order in
      # the output depends on Python's string hashing.
      PYTHONHASHSEED = "0";
    } ''
    python3 ${./scripts}/build-particles.py ${cfg.casualPreLoader} "$settingsPath" "$out"
  '';

  builtParticles = if cfg.particles == { } then pkgs.emptyDirectory else "${particles}/particles";

  gameinfo = "$HOME/${tfDir}/gameinfo.txt";

  vpkType = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "./shovel.vpk";
        description = "Local VPK. For a split VPK, the `_dir.vpk` with its chunks next to it.";
      };
      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "URL to download the VPK from. Needs `hash`.";
      };
      hash = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Hash of the file at `url`, e.g. from `nix store prefetch-file <url>`.";
      };
    };
  };
in
{
  options.programs.tf2-preload = {
    enable = lib.mkEnableOption "preloading custom VPKs past sv_pure, like casual-pre-loader";

    vpkDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./tf2-mods";
      description = ''
        Folder of VPKs to preload. Each `<name>.vpk` (or split `<name>_dir.vpk`)
        is installed as `custom/<name>.vpk`.
      '';
    };

    vpks = lib.mkOption {
      type = lib.types.attrsOf vpkType;
      default = { };
      example = lib.literalExpression ''
        {
          shovel.source = ./shovel.vpk;
          rocket-launcher = {
            url = "https://example.com/rocket-launcher.vpk";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };
        }
      '';
      description = ''
        VPKs to preload, installed as `custom/<name>.vpk`. Each needs either
        `source`, or `url` and `hash`.
      '';
    };

    autoexec = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run the preload from mastercomfig's autoexec. Set to `false` to run it
        yourself, e.g. with the launch option `+exec tf2-preload`.
      '';
    };

    map = lib.mkOption {
      type = lib.types.str;
      default = "itemtest";
      description = "Offline map loaded to cache the assets.";
    };

    particleMods = lib.mkOption {
      type = lib.types.attrsOf vpkType;
      default = { };
      example = lib.literalExpression ''
        {
          toon-explosions.source = "''${toonExplosions}/toon_explosions_v1.1.vpk";
        }
      '';
      description = ''
        Particle mod VPKs, for `particles`. Their particle systems are split up by
        the vanilla particle file they replace, like casual-pre-loader's particle
        import. Each needs either `source`, or `url` and `hash`.
      '';
    };

    particles = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = { explosion = "toon-explosions"; };
      description = ''
        Vanilla particle files to replace, each mapped to the `particleMods` entry
        to take it from. A key is a particle file without `.pcf` (e.g. `explosion`,
        which has the rocket and stickybomb explosions) or one of casual-pre-loader's
        groups (`explosions`, `fire`, `bullets`, `blood`, `weapons`, `maps`,
        `game_modes`, `unusuals_hats`, `unusual_weapons`, `player`, `buildings`,
        `misc`). The build fails with the mod's particle files if it has none for
        a key.

        The files are patched into the game's `tf2_misc_dir.vpk` on activation,
        and restored from casual-pre-loader's vanilla copies once deselected.
        After a TF2 update changes them, activation leaves them alone until
        `casualPreLoader` is updated. Disabling the module leaves them patched:
        empty this first, or verify the game files in Steam.
      '';
    };

    casualPreLoader = lib.mkOption {
      type = lib.types.path;
      default = pkgs.fetchFromGitHub {
        owner = "cueki";
        repo = "casual-pre-loader";
        rev = "429adc6e0a6b0b64661c408acf3cf74a1a7b9f52";
        sparseCheckout = [ "core" "data" "backup/particles" ];
        hash = "sha256-hyHZORfubk2UTwplXpARxBShGjWgE5jDisv0nOxWle4=";
      };
      defaultText = lib.literalMD "casual-pre-loader's source, pinned";
      description = ''
        casual-pre-loader's source. Its particle code, particle map and vanilla
        particle files are used to build and restore `particles`, so it has to
        match the installed game.
      '';
    };

    python = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python3.withPackages (p: [ p.srctools (p.callPackage ./valve-parsers.nix { }) ]);
      defaultText = lib.literalExpression
        "pkgs.python3.withPackages (p: [ p.srctools (p.callPackage ./valve-parsers.nix { }) ])";
      description = ''
        Python with srctools and valve_parsers, used to repack the VPKs and build
        and patch the particles. The flake's module sets this from its own pinned
        nixpkgs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.mastercomfig.enable;
        message = "programs.tf2-preload requires programs.mastercomfig.enable.";
      }
    ] ++ lib.mapAttrsToList
      (name: v: {
        assertion = (v.source != null) != (v.url != null) && (v.url != null) == (v.hash != null);
        message = "programs.tf2-preload.vpks.${name} needs either `source`, or `url` and `hash`.";
      })
      cfg.vpks
    ++ map
      (name: {
        assertion = !(cfg.vpks ? ${name});
        message = "programs.tf2-preload.vpks.${name} has the same name as a VPK in vpkDir.";
      })
      (lib.attrNames dirVpks)
    ++ lib.mapAttrsToList
      (name: v: {
        assertion = (v.source != null) != (v.url != null) && (v.url != null) == (v.hash != null);
        message = "programs.tf2-preload.particleMods.${name} needs either `source`, or `url` and `hash`.";
      })
      cfg.particleMods
    ++ lib.mapAttrsToList
      (key: mod: {
        assertion = cfg.particleMods ? ${mod};
        message = "programs.tf2-preload.particles.${key} is ${mod}, which isn't in particleMods.";
      })
      cfg.particles;

    home.file = lib.mapAttrs'
      (name: src: lib.nameValuePair "${tfDir}/custom/${name}.vpk" { source = buildVpk name src; })
      allVpks
    // {
      # casual-pre-loader's preload, minus its menu music and console extras.
      "${tfDir}/custom/tf2-preload/cfg/tf2-preload.cfg".text =
        "sv_pure -1; map ${cfg.map}; wait 10; disconnect; wait 1; clear\n";
    }
    // lib.optionalAttrs (cfg.particles != { }) {
      "${tfDir}/custom/tf2-preload-particles.vpk".source = "${particles}/materials.vpk";
    };

    programs.mastercomfig.autoexec = lib.mkIf cfg.autoexec (lib.mkAfter "exec tf2-preload");

    # Steam rewrites gameinfo.txt on updates and file verification, so this
    # reapplies casual-pre-loader's edit on every switch.
    home.activation.tf2-preload = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f "${gameinfo}" ]; then
        if grep -qE '^[[:space:]]*"?type"?[[:space:]]+"?multiplayer_only' "${gameinfo}"; then
          verboseEcho "tf2-preload: commenting out 'type multiplayer_only' in ${gameinfo}"
          run sed -i -E 's|^([[:space:]]*)("?type"?[[:space:]]+"?multiplayer_only)|\1//\2|' "${gameinfo}"
        fi
      else
        warnEcho "tf2-preload: ${gameinfo} not found, skipping the gameinfo.txt edit"
      fi

      # Runs with no particles too, to restore files that were deselected.
      run ${cfg.python}/bin/python3 ${./scripts}/patch-particles.py \
        "$HOME/${tfDir}/tf2_misc_dir.vpk" ${builtParticles} \
        ${cfg.casualPreLoader}/backup/particles \
        "${config.xdg.stateHome}/tf2-preload/particles.json"
    '';
  };
}

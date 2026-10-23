# Home Manager module that preloads custom VPKs (reskins and other materials or
# models) the way casual-pre-loader does, so they survive sv_pure:
#   * each VPK is repacked at build time (`$ignorez` blanked, missing weapon
#     VMTs added from the game's own), see ./build-vpk.py
#   * activation comments out `type multiplayer_only` in `gameinfo.txt`
#   * mastercomfig's autoexec loads an offline map with `sv_pure -1`, then
#     disconnects, so the assets stay cached
#
# Layout produced (relative to `programs.mastercomfig.tfDir`):
#   custom/<name>.vpk                         (read-only symlink into the store)
#   custom/tf2-preload/cfg/tf2-preload.cfg
#   gameinfo.txt                              (edited in place on activation)
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

  listedVpks = lib.mapAttrs
    (name: v: if v.source != null then v.source else pkgs.fetchurl {
      name = "${lib.strings.sanitizeDerivationName name}.vpk";
      inherit (v) url hash;
    })
    (lib.filterAttrs (_: v: v.source != null || (v.url != null && v.hash != null)) cfg.vpks);

  allVpks = dirVpks // listedVpks;

  buildVpk = name: src: pkgs.runCommand "${lib.strings.sanitizeDerivationName name}.vpk"
    { nativeBuildInputs = [ cfg.python ]; } ''
    python3 ${./build-vpk.py} ${lib.escapeShellArg "${src}"} \
      ${vanillaMaterials}/Content/tf/tf2_misc_dir "$out"
  '';

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

    python = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python3.withPackages (p: [ p.srctools ]);
      defaultText = lib.literalExpression "pkgs.python3.withPackages (p: [ p.srctools ])";
      description = ''
        Python with srctools, used to repack the VPKs. The flake's module sets this
        from its own pinned nixpkgs.
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
      (lib.attrNames dirVpks);

    home.file = lib.mapAttrs'
      (name: src: lib.nameValuePair "${tfDir}/custom/${name}.vpk" { source = buildVpk name src; })
      allVpks
    // {
      # casual-pre-loader's preload, minus its menu music and console extras.
      "${tfDir}/custom/tf2-preload/cfg/tf2-preload.cfg".text =
        "sv_pure -1; map ${cfg.map}; wait 10; disconnect; wait 1; clear\n";
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
    '';
  };
}

# Generates weapon scripts and crosshair materials the same way the comfig.app
# downloader does (see getCustomDownloadUrls in comfig-app's src/utils/app.ts).
#
# Usage: comfig-crosshairs.py <weapon scripts dir> <crosshair vtf dir> <config.json> <out dir>
#
# config.json: { "crosshairs": { <target>: <crosshair> }, "zoom": { <weapon>: <crosshair> } }
# A crosshair is "<pack>" or "<pack>.<key>", e.g. "crosshair5OL" or "sprites/crosshairs._64_64".
import json
import shutil
import sys
from pathlib import Path

import vdf

BLOCKED_ITEMS = {
    "tf_weapon_invis",
    "tf_weapon_objectselection",
    "tf_weapon_parachute",
    "tf_weapon_parachute_secondary",
    "tf_weapon_parachute_primary",
    "tf_weapon_jar_milk",
    "tf_weapon_jar_gas",
    "tf_weapon_cleaver",
    "tf_weapon_pda_spy",
    "tf_weapon_sapper",
    "tf_weapon_pda_engineer_build",
    "tf_weapon_pda_engineer_destroy",
}

ITEM_USED_BY = {
    "scout": [
        "tf_weapon_bat",
        "tf_weapon_bat_fish",
        "tf_weapon_bat_giftwrap",
        "tf_weapon_bat_wood",
        "tf_weapon_jar",
        "tf_weapon_handgun_scout_primary",
        "tf_weapon_handgun_scout_secondary",
        "tf_weapon_lunchbox_drink",
        "tf_weapon_pep_brawler_blaster",
        "tf_weapon_pistol_scout",
        "tf_weapon_scattergun",
        "tf_weapon_soda_popper",
    ],
    "soldier": [
        "tf_weapon_buff_item",
        "tf_weapon_katana",
        "tf_weapon_particle_cannon",
        "tf_weapon_raygun",
        "tf_weapon_rocketlauncher",
        "tf_weapon_rocketlauncher_airstrike",
        "tf_weapon_rocketlauncher_directhit",
        "tf_weapon_shotgun_soldier",
        "tf_weapon_shovel",
    ],
    "pyro": [
        "tf_weapon_breakable_sign",
        "tf_weapon_fireaxe",
        "tf_weapon_flamethrower",
        "tf_weapon_flaregun",
        "tf_weapon_flaregun_revenge",
        "tf_weapon_jar",
        "tf_weapon_rocketlauncher_fireball",
        "tf_weapon_rocketpack",
        "tf_weapon_shotgun_pyro",
        "tf_weapon_slap",
    ],
    "demoman": [
        "tf_weapon_bottle",
        "tf_weapon_cannon",
        "tf_weapon_grenadelauncher",
        "tf_weapon_katana",
        "tf_weapon_pipebomblauncher",
        "tf_weapon_stickbomb",
        "tf_weapon_sword",
    ],
    "heavy": [
        "tf_weapon_fists",
        "tf_weapon_lunchbox",
        "tf_weapon_minigun",
        "tf_weapon_shotgun_hwg",
    ],
    "engineer": [
        "tf_weapon_builder",
        "tf_weapon_drg_pomson",
        "tf_weapon_laser_pointer",
        "tf_weapon_mechanical_arm",
        "tf_weapon_pistol",
        "tf_weapon_robot_arm",
        "tf_weapon_sentry_revenge",
        "tf_weapon_shotgun_building_rescue",
        "tf_weapon_shotgun_primary",
        "tf_weapon_wrench",
    ],
    "medic": [
        "tf_weapon_bonesaw",
        "tf_weapon_crossbow",
        "tf_weapon_medigun",
        "tf_weapon_syringegun_medic",
    ],
    "sniper": [
        "tf_weapon_charged_smg",
        "tf_weapon_club",
        "tf_weapon_compound_bow",
        "tf_weapon_jar",
        "tf_weapon_smg",
        "tf_weapon_sniperrifle",
        "tf_weapon_sniperrifle_classic",
        "tf_weapon_sniperrifle_decap",
    ],
    "spy": ["tf_weapon_knife", "tf_weapon_revolver", "tf_weapon_builder"],
}

ALL_CLASS_ITEMS = [
    "tf_weapon_grapplinghook",
    "tf_weapon_spellbook",
    "tf_weapon_passtime_gun",
]

CUSTOM_ITEM_SLOT = {
    "tf_weapon_buff_item": "Secondary",
    "tf_weapon_compound_bow": "Primary",
    "tf_weapon_grapplinghook": "Action Item",
    "tf_weapon_parachute_primary": "Primary",
    "tf_weapon_parachute_secondary": "Secondary",
    "tf_weapon_passtime_gun": "Utility",
    "tf_weapon_rocketpack": "Secondary",
    "tf_weapon_spellbook": "Action Item",
    "tf_weapon_builder": "Building",
}

NORMALIZED_SLOTS = {
    "primary": "Primary",
    "secondary": "Secondary",
    "melee": "Melee",
    "item1": "Secondary",
    "item2": "Melee",
    "pda": "PDA",
    "building": "Building",
}

ZOOMABLE = {
    "tf_weapon_sniperrifle",
    "tf_weapon_sniperrifle_classic",
    "tf_weapon_sniperrifle_decap",
}

# Crosshairs that aren't a 64x64 texture at (0, 0). Everything else is a
# texture from comfig-app's public/assets/app/crosshairs.
SPRITE_SHEET = "sprites/crosshairs"
SPRITES = {
    "_64_64": ("64", "64", "64"),
    "_32_32": ("32", "32", "32"),
    "_64_0": ("64", "0", "32"),
    "_64_-1": ("64", "-1", "32"),
    "_0_64": ("0", "64", "32"),
    "_0_0": ("0", "0", "32"),
    "_0_48": ("0", "48", "24"),
}
SIZES = {
    "cpma_1": "32",
    "cpma_2": "32",
    "cpma_3": "32",
    "cpma_4": "32",
    "cpma_6": "32",
    "cpma_7": "32",
    "cpma_8": "32",
    "cpma_9": "32",
    "cpma_10": "32",
    "ql_6": "32",
}

TARGET_BASE = "vgui/replay/thumbnails/"


def slot_name(item):
    if item["classname"] in CUSTOM_ITEM_SLOT:
        return CUSTOM_ITEM_SLOT[item["classname"]]
    slot = item.get("WeaponType", "")
    return NORMALIZED_SLOTS.get(slot, slot)


def main(scripts_dir, textures_dir, config_path, out):
    config = json.loads(config_path.read_text())

    items = {}
    for path in sorted(scripts_dir.glob("tf_weapon_*.txt")):
        script = vdf.loads(path.read_text(encoding="utf-8-sig", errors="replace"))
        # A few shotgun scripts use this instead of WeaponData.
        data = script.get("WeaponData") or script["fWeaponData"]
        classname = path.stem
        if classname not in BLOCKED_ITEMS:
            data["classname"] = classname
            items[classname] = data

    textures = set()
    changed = set()

    def resolve(crosshair):
        pack, _, key = crosshair.partition(".")
        if pack == SPRITE_SHEET:
            if key not in SPRITES:
                sys.exit(f"unknown {SPRITE_SHEET} crosshair '{key}', expected one of {sorted(SPRITES)}")
            x, y, size = SPRITES[key]
            return pack, x, y, size
        if not (textures_dir / f"{pack}.vtf").is_file():
            sys.exit(f"unknown crosshair '{pack}', see {textures_dir} for available crosshairs")
        textures.add(pack)
        return TARGET_BASE + pack, "0", "0", SIZES.get(pack, "64")

    def apply(classname, kind, crosshair):
        file, x, y, size = resolve(crosshair)
        texture_data = items[classname].setdefault("TextureData", {})
        texture_data[kind] = {"file": file, "x": x, "y": y, "width": size, "height": size}
        changed.add(classname)

    crosshairs = config["crosshairs"]
    used = set()

    def set_defaults(target, classnames):
        if target in crosshairs:
            used.add(target)
            for classname in classnames:
                if classname in items:
                    apply(classname, "crosshair", crosshairs[target])

    def by_slot(classnames):
        slots = {}
        for classname in classnames:
            if classname in items:
                slots.setdefault(slot_name(items[classname]), []).append(classname)
        return slots

    # Same precedence as the website: later groups override earlier ones.
    set_defaults("default", list(items))
    for slot, slot_items in by_slot(items).items():
        set_defaults(f"default_slot_{slot}", slot_items)
    for player_class, class_items in ITEM_USED_BY.items():
        set_defaults(f"default_{player_class}", class_items)
        for slot, slot_items in by_slot(class_items).items():
            set_defaults(f"default_{player_class}_{slot}", slot_items)
    for target in ["default_all", "default_all_actionitem", "default_all_utility"]:
        set_defaults(target, ALL_CLASS_ITEMS)

    for target, crosshair in crosshairs.items():
        if target in used:
            continue
        if target not in items:
            sys.exit(f"unknown crosshair target '{target}', expected a default_* group or one of {sorted(items)}")
        apply(target, "crosshair", crosshair)

    for classname, crosshair in config["zoom"].items():
        if classname not in ZOOMABLE:
            sys.exit(f"'{classname}' has no zoom crosshair, expected one of {sorted(ZOOMABLE)}")
        apply(classname, "zoom", crosshair)

    scripts_out = out / "scripts"
    scripts_out.mkdir(parents=True)
    for classname in sorted(changed):
        item = dict(items[classname])
        del item["classname"]
        (scripts_out / f"{classname}.txt").write_text(vdf.dumps({"WeaponData": item}, pretty=True))

    materials_out = out / "materials" / TARGET_BASE
    materials_out.mkdir(parents=True)
    for texture in sorted(textures):
        shutil.copyfile(textures_dir / f"{texture}.vtf", materials_out / f"{texture}.vtf")
        material = {
            "UnlitGeneric": {
                "$translucent": "1",
                "$basetexture": TARGET_BASE + texture,
                "$vertexcolor": "1",
                "$no_fullbright": "1",
                "$ignorez": "1",
            }
        }
        (materials_out / f"{texture}.vmt").write_text(vdf.dumps(material, pretty=True))


if __name__ == "__main__":
    main(*map(Path, sys.argv[1:5]))

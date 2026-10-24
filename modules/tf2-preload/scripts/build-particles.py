"""Build patched particle files with casual-pre-loader's own particle code.

Usage: build-particles.py <casual-pre-loader source> <config.json> <out dir>

config.json: { "mods": { <name>: <vpk> }, "selections": { <particle or group>: <name> } }
A selection key is a vanilla particle file without `.pcf` (e.g. "explosion")
or one of casual-pre-loader's groups (e.g. "explosions").

casual-pre-loader is GPL-3.0, so its code isn't copied here: it's imported from
the source tree, with a stand-in `core.config` holding only the paths the
particle code reads. This script runs the steps of its install that are mixed
in with the GUI and game handling (`Installer.install`):

1. extract each mod and split its particle systems by vanilla particle file
   (`AdvancedParticleMerger.preprocess_vpk`)
2. pick the selected particle files and the materials they use
   (`expand_group_selections`, `apply_particle_selections`)
3. strip the duplicate effects from item_fx/halloween/bigboom/dirty_explode,
   skip files that redefine disguise.pcf's systems, compress, and pad each file
   to the vanilla size, also as `<name>_dx80.pcf` for the DX8 files

Output:
  <out>/particles/<name>.pcf   exactly the vanilla size, patched into tf2_misc_dir.vpk
  <out>/materials.vpk          the materials the selected particles use
"""

import json
import logging
import shutil
import sys
import tempfile
import types
from pathlib import Path

from srctools.vpk import VPK

from vpkwrite import write_vpk

DUPLICATE_EFFECTS = ["item_fx.pcf", "halloween.pcf", "bigboom.pcf", "dirty_explode.pcf"]


def use_casual_pre_loader(src: Path, work: Path) -> types.SimpleNamespace:
    temp = work / "temp"
    config = types.SimpleNamespace(
        data_dir=src / "data",
        particle_system_map_file=src / "data" / "particle_system_map.json",
        backup_dir=src / "backup",
        particles_dir=work / "particles",
        temp_dir=temp,
        temp_to_be_processed_dir=temp / "to_be_processed",
        temp_to_be_referenced_dir=temp / "to_be_referenced",
        temp_to_be_patched_dir=temp / "to_be_patched",
        temp_to_be_vpk_dir=temp / "to_be_vpk",
    )
    module = types.ModuleType("core.config")
    module.config = config
    sys.modules["core.config"] = module
    sys.path.insert(0, str(src))

    # Like prepare_working_copy: the vanilla particles are read from a writable copy.
    shutil.copytree(src / "backup" / "particles", config.temp_to_be_referenced_dir)
    return config


def main(src: str, config_json: str, out: str) -> None:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    settings = json.loads(Path(config_json).read_text())
    work = Path(tempfile.mkdtemp())
    config = use_casual_pre_loader(Path(src), work)

    from valve_parsers import PCFFile

    from core.constants import DX8_LIST
    from core.handlers.pcf_handler import check_parents, update_materials
    from core.operations.advanced_particle_merger import AdvancedParticleMerger
    from core.operations.file_processors import initialize_pcf
    from core.operations.pcf_compress import remove_duplicate_elements
    from core.operations.pcf_rebuild import extract_elements, load_particle_system_map
    from core.services.particles import expand_group_selections
    from core.util.pcf_path_walk import apply_particle_selections, get_mod_particles

    errors = []

    # 1. Extract each mod where casual-pre-loader's importer would, then split it.
    for name, vpk in settings["mods"].items():
        mod_dir = config.particles_dir / name
        for info in VPK(vpk):
            dest = mod_dir / info.filename
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(info.read())
        if not any((mod_dir / "particles").glob("*.pcf")):
            errors.append(f"particle mod {name} has no particles/*.pcf")
            continue
        AdvancedParticleMerger().preprocess_vpk(mod_dir)

    # 2. Select particle files, like the GUI's simple mode.
    mod_particles, _ = get_mod_particles()
    selections = {}
    for key, mod in settings["selections"].items():
        expanded = expand_group_selections({key: mod}, mod_particles, simple_mode=True)
        available = mod_particles.get(mod, [])
        if not expanded or any(p not in available for p in expanded):
            errors.append(
                f"particle mod {mod} has nothing for {key!r}; it has: {', '.join(sorted(available))}"
            )
        selections.update(expanded)
    if errors:
        sys.exit("\n".join(errors))
    apply_particle_selections(selections)

    # 3. The particle part of Installer.install.
    referenced = config.temp_to_be_referenced_dir
    patched = config.temp_to_be_patched_dir
    patched.mkdir(parents=True, exist_ok=True)
    particle_map = load_particle_system_map(config.particle_system_map_file)

    for name in DUPLICATE_EFFECTS:
        target = patched / name
        if not target.exists() and (referenced / name).exists():
            extract_elements(PCFFile(referenced / name).decode(),
                             particle_map[f"particles/{name}"]).encode(target)

    if (patched / "blood_trail.pcf").exists():
        shutil.move(patched / "blood_trail.pcf", patched / "npc_fx.pcf")

    base_pcf, base_parents = initialize_pcf(referenced)
    out_particles = Path(out) / "particles"
    out_particles.mkdir(parents=True)

    for pcf_file in sorted(patched.glob("*.pcf")):
        name = pcf_file.name
        mod_pcf = PCFFile(pcf_file).decode()

        if name != base_pcf.input_file.name and check_parents(mod_pcf, base_parents):
            logging.warning(f"{name}: redefines disguise.pcf's systems, skipped like casual-pre-loader does")
            continue
        if name == base_pcf.input_file.name:
            mod_pcf = update_materials(base_pcf, mod_pcf)

        encoded = work / "encoded.pcf"
        remove_duplicate_elements(mod_pcf).encode(encoded)
        data = encoded.read_bytes()

        targets = [name] + ([f"{pcf_file.stem}_dx80.pcf"] if pcf_file.stem in DX8_LIST else [])
        for target in targets:
            size = (referenced / target).stat().st_size
            if len(data) > size:
                message = f"{target}: {len(data) - size} bytes larger than the vanilla file even after compressing"
                if target == name:
                    errors.append(message)
                else:
                    logging.warning(f"{message}, skipped (only used by DirectX 8)")
                continue
            (out_particles / target).write_bytes(data + b" " * (size - len(data)))
            print(f"{target}: {len(data)} of {size} bytes")

    if errors:
        sys.exit("\n".join(errors))

    # Materials go in a custom VPK, like casual-pre-loader's _casual_preloader.vpk.
    vpk_dir = config.temp_to_be_vpk_dir
    materials = {
        p.relative_to(vpk_dir).as_posix(): p.read_bytes()
        for p in sorted(vpk_dir.rglob("*")) if p.is_file()
    } if vpk_dir.exists() else {}
    write_vpk(str(Path(out) / "materials.vpk"), materials)
    print(f"{len(materials)} material files")


if __name__ == "__main__":
    main(*sys.argv[1:])

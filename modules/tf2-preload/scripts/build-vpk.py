"""Repack a mod VPK the way casual-pre-loader prepares mods before preloading.

Usage: build-vpk.py <input.vpk> <vanilla tf2_misc_dir> <output.vpk>

* Blanks `$ignorez 1` (renders through walls) with spaces of the same length,
  like casual-pre-loader's `get_from_custom_dir`.
* Adds a VMT for every weapon/pattern VTF that has none, copied from the game's
  own VMT when there is one, like `generate_missing_vmt_files`.
* Writes a single-file V2 VPK, so split `_dir`/`_000` VPKs become one file.
"""

import re
import sys
from pathlib import Path, PurePosixPath

from srctools.vpk import VPK

from vpkwrite import write_vpk

# casual-pre-loader matches a fixed set of spellings; KeyValues are
# case-insensitive and quoting is optional, so match all of them.
IGNOREZ = re.compile(rb'"?\$ignorez"?[ \t]+"?1"?', re.IGNORECASE)

VMT_DIRS = ("materials/models/weapons/", "materials/patterns/")


def generic_vmt(texture: str) -> bytes:
    return f'"LightmappedGeneric"\n{{\n\t"$basetexture" "{texture}"\n}}\n'.encode()


def main(src: str, vanilla_dir: str, out: str) -> None:
    files: dict[str, bytes] = {}
    for info in VPK(src):
        files[info.filename] = info.read()

    blanked = 0
    for path, data in files.items():
        new, n = IGNOREZ.subn(lambda m: b" " * len(m.group()), data)
        if n:
            print(f"{path}: blanked {n} $ignorez")
            files[path] = new
            blanked += n

    # Lowercased path -> file, since Source paths are case-insensitive.
    vanilla_root = Path(vanilla_dir)
    vanilla = {
        p.relative_to(vanilla_root).as_posix().lower(): p
        for p in vanilla_root.rglob("*.vmt")
    }

    in_vmt_dirs = [p for p in files if p.lower().startswith(VMT_DIRS)]
    vmt_stems = {PurePosixPath(p).stem.lower() for p in in_vmt_dirs if p.lower().endswith(".vmt")}

    for path in in_vmt_dirs:
        p = PurePosixPath(path)
        if p.suffix.lower() != ".vtf" or p.stem.lower() in vmt_stems:
            continue
        vmt = p.with_suffix(".vmt").as_posix()
        game_vmt = vanilla.get(vmt.lower())
        if game_vmt is not None:
            files[vmt] = game_vmt.read_bytes()
            print(f"{vmt}: copied from the game")
        else:
            files[vmt] = generic_vmt(p.with_suffix("").as_posix()[len("materials/"):])
            print(f"{vmt}: not in the game, wrote a generic VMT")

    write_vpk(out, files)

    print(f"{len(files)} files, {blanked} $ignorez blanked")


if __name__ == "__main__":
    main(*sys.argv[1:])

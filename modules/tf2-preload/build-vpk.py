"""Repack a mod VPK the way casual-pre-loader prepares mods before preloading.

Usage: build-vpk.py <input.vpk> <vanilla tf2_misc_dir> <output.vpk>

* Blanks `$ignorez 1` (renders through walls) with spaces of the same length,
  like casual-pre-loader's `get_from_custom_dir`.
* Adds a VMT for every weapon/pattern VTF that has none, copied from the game's
  own VMT when there is one, like `generate_missing_vmt_files`.
* Writes a single-file V2 VPK, so split `_dir`/`_000` VPKs become one file.
"""

import hashlib
import re
import struct
import sys
import zlib
from pathlib import Path, PurePosixPath

from srctools.vpk import VPK

# casual-pre-loader matches a fixed set of spellings; KeyValues are
# case-insensitive and quoting is optional, so match all of them.
IGNOREZ = re.compile(rb'"?\$ignorez"?[ \t]+"?1"?', re.IGNORECASE)

VMT_DIRS = ("materials/models/weapons/", "materials/patterns/")


def generic_vmt(texture: str) -> bytes:
    return f'"LightmappedGeneric"\n{{\n\t"$basetexture" "{texture}"\n}}\n'.encode()


def write_vpk(out: str, files: dict[str, bytes]) -> None:
    """Write a single-file V2 VPK, with the data after the directory tree.

    srctools keeps a single-file VPK's data inside the tree as preload data,
    which is capped at 64 KiB per file, so it can't write larger files. V1 has
    no data section after the tree (TF2 reads the wrong bytes), so this is V2.
    """
    # ext -> dir -> name -> data. Valve uses " " for an empty dir or extension.
    tree: dict[str, dict[str, dict[str, bytes]]] = {}
    for path, data in files.items():
        p = PurePosixPath(path.lower())
        ext = p.suffix[1:] or " "
        folder = p.parent.as_posix()
        tree.setdefault(ext, {}).setdefault(" " if folder == "." else folder, {})[p.stem] = data

    entries = bytearray()
    blobs = bytearray()
    for ext, folders in sorted(tree.items()):
        entries += ext.encode() + b"\0"
        for folder, names in sorted(folders.items()):
            entries += folder.encode() + b"\0"
            for name, data in sorted(names.items()):
                entries += name.encode() + b"\0"
                # crc, preload bytes, archive (0x7fff = this file), offset, length, terminator
                entries += struct.pack("<IHHIIH", zlib.crc32(data), 0, 0x7FFF, len(blobs), len(data), 0xFFFF)
                blobs += data
            entries += b"\0"
        entries += b"\0"
    entries += b"\0"

    # signature, version, tree size, data size, archive MD5 size (no archives),
    # other MD5 size (the three MD5s below), signature size (unsigned)
    body = struct.pack("<7I", 0x55AA1234, 2, len(entries), len(blobs), 0, 48, 0) + entries + blobs
    # MD5s of the tree, of the empty archive MD5 section, and of everything before this one
    md5s = hashlib.md5(entries).digest() + hashlib.md5(b"").digest()
    md5s += hashlib.md5(body + md5s).digest()

    with open(out, "wb") as f:
        f.write(body)
        f.write(md5s)


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

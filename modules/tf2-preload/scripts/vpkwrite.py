"""Single-file VPK writer shared by the build scripts."""

import hashlib
import struct
import zlib
from pathlib import PurePosixPath


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

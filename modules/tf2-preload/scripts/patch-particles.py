"""Patch built particle files into the game's tf2_misc_dir.vpk, in place.

Usage: patch-particles.py <tf2_misc_dir.vpk> <built particles dir> <vanilla particles dir> <state.json>

Particles only load past sv_pure from the game's own VPK, so like
casual-pre-loader each file is overwritten where it is, at the same size.

A file is only written if it's still the vanilla file the build used, or what
this script last wrote there (recorded in state.json). Anything else means
Steam replaced it, usually in a TF2 update, and building against the new
vanilla particles needs a newer casual-pre-loader. Files that are no longer
selected are restored from the vanilla copies.
"""

import hashlib
import json
import sys
from pathlib import Path

from valve_parsers import VPKFile


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main(vpk_path: str, built_dir: str, vanilla_dir: str, state_path: str) -> None:
    if not Path(vpk_path).exists():
        print(f"tf2-preload: {vpk_path} not found, skipping particles", file=sys.stderr)
        return

    state_file = Path(state_path)
    state: dict[str, str] = json.loads(state_file.read_text()) if state_file.exists() else {}
    built = {p.name: p for p in Path(built_dir).glob("*.pcf")}
    vpk = VPKFile(vpk_path)
    new_state: dict[str, str] = {}
    stale = []

    for name in sorted(set(built) | set(state)):
        path = f"particles/{name}"
        info = vpk.get_file_info(path)
        vanilla_file = Path(vanilla_dir) / name
        if info is None or info["preload_bytes"] or not vanilla_file.exists():
            print(f"tf2-preload: can't patch {path}, skipping", file=sys.stderr)
            continue

        vanilla = vanilla_file.read_bytes()
        want = built[name].read_bytes() if name in built else vanilla
        current = vpk.get_file_data(path)

        if current == want:
            if want != vanilla:
                new_state[name] = sha256(want)
            continue
        if current != vanilla and sha256(current) != state.get(name):
            stale.append(name)
            continue
        if len(want) != info["size"]:
            stale.append(name)
            continue

        vpk.patch_file(path, want)
        print(f"tf2-preload: {'patched' if want != vanilla else 'restored'} {path}")
        if want != vanilla:
            new_state[name] = sha256(want)

    vpk.close()
    state_file.parent.mkdir(parents=True, exist_ok=True)
    state_file.write_text(json.dumps(new_state, indent=2, sort_keys=True) + "\n")

    if stale:
        print(
            f"tf2-preload: left {len(stale)} particle file(s) alone because they differ from the vanilla "
            f"files tf2-preload was built against, probably from a TF2 update: {', '.join(stale)}. "
            "Update programs.tf2-preload.casualPreLoader to a release with the new vanilla particles.",
            file=sys.stderr,
        )


if __name__ == "__main__":
    main(*sys.argv[1:])

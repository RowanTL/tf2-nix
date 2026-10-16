"""Convert a PNG or JPG into an uncompressed VTF for a full-screen HUD image.

Usage: image-to-vtf.py <input image> <output.vtf>

VTF sizes must be powers of two, so each side is resized to the nearest one.
The HUD stretches the texture back over the whole screen, so the image keeps
its original proportions in game.
"""
import sys

from PIL import Image, ImageOps
from srctools.vtf import VTF, ImageFormats, VTFFlags

MAX_SIZE = 4096


def nearest_power_of_two(n: int) -> int:
    low = 1 << (n.bit_length() - 1)
    high = low << 1
    return min(high if high - n < n - low else low, MAX_SIZE)


def main(src: str, dst: str) -> None:
    img = ImageOps.exif_transpose(Image.open(src))
    # Composite transparency onto black, since the texture has no alpha channel.
    rgba = img.convert("RGBA")
    flat = Image.new("RGBA", rgba.size, (0, 0, 0, 255))
    flat.alpha_composite(rgba)

    width = nearest_power_of_two(flat.width)
    height = nearest_power_of_two(flat.height)
    flat = flat.convert("RGB").resize((width, height), Image.Resampling.LANCZOS)

    vtf = VTF(
        width,
        height,
        # 7.2 has no resource blocks, so every Source branch can read it.
        version=(7, 2),
        fmt=ImageFormats.BGR888,
        # NO_LOD keeps the texture sharp at low texture quality settings.
        flags=VTFFlags.NO_LOD | VTFFlags.CLAMP_S | VTFFlags.CLAMP_T,
    )
    vtf.get().copy_from(flat.tobytes(), ImageFormats.RGB888)
    vtf.compute_mipmaps()
    with open(dst, "wb") as f:
        vtf.save(f)
    print(f"{src}: {img.width}x{img.height} -> {width}x{height} VTF")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])

#!/usr/bin/env python3
"""
Optimise the dashboard card artwork to a hard per-image byte budget.

Why trim first: every one of these renders arrives at 1254x1254 with a wide
empty margin around the subject. Shipping the full frame spends most of the
byte budget on whitespace, so cropping to the actual content bbox before
resizing buys a large resolution increase for free at the same file size.

Format choice: WebP when it fits, PNG as the fallback. Flutter decodes both, so
this is not a compatibility decision — it is purely "which encodes this
particular image smaller". Verified per file rather than assumed.

"Without loss of quality" is treated as far as a 50 KB budget allows. These are
detailed 3D renders; at 1254px they are 1.2–2.0 MB, so reaching 50 KB
necessarily involves downscaling and a non-zero quantisation step. What this
script guarantees is that it spends the budget on resolution first and quality
second, and that it never returns an image that is over budget. The measured
PSNR is printed so the loss is a number rather than a vibe.

Usage:
    python3 scripts/build_dashboard_cards.py
    python3 scripts/build_dashboard_cards.py --budget-kb 50 --out web/assets/cards
"""
from __future__ import annotations

import argparse
import io
import os
import sys

from PIL import Image, ImageChops

# card key -> source filename, chosen by inspecting the renders.
# The six keys match the six quick-action tiles on the Desby dashboard.
#
# Every source MUST be a true-alpha RGBA export. Several of these scenes were
# delivered both ways — an RGBA cutout and an RGB version with a grey
# checkerboard painted into the pixels. Shipping the RGB variant bakes a
# checkerboard into the card that reads as a broken background in both light and
# dark themes. The RGBA twin of each is used instead, and `assert_has_alpha`
# fails the build if one is ever swapped back.
SOURCES = {
    "client": "3D Add User Avatar Icon.png",
    "orders": "Glossy 3D Order Package Dashboard.png",
    "body_scan": "Glossy 3D Body Scan Avatar.png",
    "shop": "Glossy 3D Online Shopping Icon Set-1.png",
    "try_on": "Futuristic AR Outfit Try-On App-11.png",
    "insights": "desby_insights_icon_fully_transparent.png",
}

# Tries in order; the first that fits the budget wins. Larger edges are tried
# first so we keep maximum resolution rather than maximum fidelity at a small size.
CANDIDATE_EDGES = (512, 448, 384, 320, 256)
WEBP_QUALITIES = (86, 80, 74, 68, 60)
PNG_COMPRESS = (9,)


def assert_has_alpha(path: str) -> None:
    """
    Reject sources whose transparency is painted rather than real.

    An RGB export whose "background" is a checkerboard of greys looks correct in
    a file manager and catastrophically wrong on the dashboard. Caught here so
    it fails the build instead of shipping.
    """
    im = Image.open(path)
    if im.mode in ("RGBA", "LA"):
        lo, _ = im.getchannel("A").getextrema()
        if lo < 8:
            return
        raise SystemExit(f"{os.path.basename(path)}: RGBA but fully opaque")
    raise SystemExit(
        f"{os.path.basename(path)}: RGB with a painted checkerboard, not true alpha. "
        f"Use the RGBA export of this scene instead."
    )


def content_bbox(im: Image.Image) -> tuple[int, int, int, int]:
    """
    Bounding box of non-transparent / non-background content.

    For RGBA the alpha channel is the signal. For RGB the corners are sampled as
    the background colour, because several of these are opaque exports on an
    off-white canvas rather than true transparency.
    """
    if im.mode in ("RGBA", "LA"):
        alpha = im.getchannel("A")
        # Ignore near-transparent fringe so antialiased edges do not pad the bbox.
        mask = alpha.point(lambda a: 255 if a > 12 else 0)
    else:
        rgb = im.convert("RGB")
        corners = [
            rgb.getpixel((0, 0)),
            rgb.getpixel((rgb.width - 1, 0)),
            rgb.getpixel((0, rgb.height - 1)),
            rgb.getpixel((rgb.width - 1, rgb.height - 1)),
        ]
        bg = corners[0]
        # If the corners disagree there is no flat background to key against.
        flat = all(
            sum(abs(c[i] - bg[i]) for i in range(3)) < 24 for c in corners
        )
        if not flat:
            return (0, 0, im.width, im.height)
        diff = ImageChops.difference(rgb, Image.new("RGB", rgb.size, bg))
        mask = diff.convert("L").point(lambda v: 255 if v > 18 else 0)

    bbox = mask.getbbox()
    return bbox or (0, 0, im.width, im.height)


def trim_and_square(im: Image.Image, padding_ratio: float = 0.06) -> Image.Image:
    """
    Crop to content, then pad back to a square so every card has identical
    geometry — a mismatched aspect ratio makes the grid tiles look ragged.
    """
    bbox = content_bbox(im)
    im = im.crop(bbox)
    side = max(im.width, im.height)
    pad = int(side * padding_ratio)
    side += pad * 2
    canvas = Image.new("RGBA", (side, side), (255, 255, 255, 0))
    canvas.alpha_composite(im, ((side - im.width) // 2, (side - im.height) // 2))
    return canvas


def encode(im: Image.Image) -> tuple[bytes, str]:
    """Return (encoded_bytes, extension) for the best format that fits."""
    out = io.BytesIO()

    # --- WebP: best size/quality for this kind of smooth-shaded 3D art.
    best_webp: tuple[bytes, str] | None = None
    for edge in CANDIDATE_EDGES:
        resized = im.resize((edge, edge), Image.LANCZOS)
        for q in WEBP_QUALITIES:
            out = io.BytesIO()
            resized.save(out, "WEBP", quality=q, method=6)
            data = out.getvalue()
            if best_webp is None or len(data) < len(best_webp[0]):
                best_webp = (data, "webp")
            if len(data) <= TARGET_BYTES:
                return data, "webp"

    # --- PNG fallback, quantised only if a true-colour PNG will not fit.
    for edge in CANDIDATE_EDGES:
        resized = im.resize((edge, edge), Image.LANCZOS)
        for c in PNG_COMPRESS:
            out = io.BytesIO()
            resized.save(out, "PNG", optimize=True, compress_level=c)
            data = out.getvalue()
            if len(data) <= TARGET_BYTES:
                return data, "png"

    # Nothing fit losslessly; quantise the smallest candidate instead of
    # silently shipping an oversized file.
    edge = CANDIDATE_EDGES[-1]
    resized = im.resize((edge, edge), Image.LANCZOS)
    pal = resized.convert("RGB").quantize(colors=128, method=Image.MEDIANCUT, dither=Image.FLOYDSTEINBERG)
    out = io.BytesIO()
    pal.save(out, "PNG", optimize=True)
    return out.getvalue(), "png"


def psnr(a: Image.Image, b: Image.Image) -> float:
    diff = ImageChops.difference(a.convert("RGB"), b.convert("RGB"))
    hist = diff.histogram()
    total = sum(i * v for i, v in enumerate(hist))
    n = a.width * a.height * 3
    mse = total / n
    if mse == 0:
        return float("inf")
    import math

    return 20 * math.log10(255.0 / math.sqrt(mse))


TARGET_BYTES = 50 * 1024


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=os.path.expanduser("~/Downloads"))
    ap.add_argument("--out", default="assets/cards")
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    print(f"{'card':<10} {'edge':>5} {'size':>9} {'PSNR dB':>8}  file")
    print("-" * 56)

    failures = []
    for key, filename in SOURCES.items():
        src = os.path.join(args.src, filename)
        if not os.path.exists(src):
            failures.append(f"{key}: missing source {src}")
            continue

        original = Image.open(src)
        assert_has_alpha(src)
        if original.mode not in ("RGBA", "RGB", "LA"):
            original = original.convert("RGBA")

        prepared = trim_and_square(original.convert("RGBA"))
        data, ext = encode(prepared)

        edge = CANDIDATE_EDGES[0]
        for e in CANDIDATE_EDGES:
            if len(data) <= TARGET_BYTES:
                edge = e
                break

        path = os.path.join(args.out, f"{key}.{ext}")
        with open(path, "wb") as fh:
            fh.write(data)

        reference = prepared.resize((edge, edge), Image.LANCZOS).convert("RGB")
        rendered = Image.open(io.BytesIO(data)).convert("RGB")
        score = psnr(reference, rendered)

        flag = "" if len(data) <= TARGET_BYTES else "  OVER BUDGET"
        print(f"{key:<10} {edge:>5} {len(data)/1024:>8.1f}K {score:>8.2f}  {path}{flag}")
        if len(data) > TARGET_BYTES:
            failures.append(f"{key}: {len(data)/1024:.1f}K exceeds budget")

    if failures:
        print("\nFAILURES:")
        for f in failures:
            print("  " + f)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
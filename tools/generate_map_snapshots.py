#!/usr/bin/env python3
"""Build the bundled map snapshot images for Test Mindset v1.5.

For every map feature (143 Pakistan + 39 World), every ocean (5) and
every country in docs/world/countries.md (30), this stitches
OpenTopoMap tiles into ONE snapshot centred on the place and draws an
orange marker at its exact position. The app shows the snapshot at
the top of each feature's detail sheet and inside the world reading
topics (oceans + countries), so the details are never text-only.

Tiles are cached on disk under ~/workspace/tile-cache/ (reruns are
cheap) and fetched politely: a proper User-Agent identifying the
app, at most ~4 requests/second. Tile data: (c) OpenStreetMap
contributors, (c) OpenTopoMap (CC-BY-SA), SRTM — the same source as
the live maps since v1.4.

Outputs (JPEG):
  assets/learning/maps/pakistan/<feature-id>.jpg
  assets/learning/maps/world/<feature-id>.jpg
  assets/learning/maps/world/ocean-<slug>.jpg
  assets/learning/maps/world/country-<slug>.jpg

Usage:
  tools/.venv/bin/python tools/generate_map_snapshots.py
      [--force] [--width N] [--height N] [--quality N]

Needs Pillow (tools/.venv). Feature ids / coordinates / categories
come from tools/generate_learning_data.py's own parsers, so the
snapshots always match the generated app data exactly.
"""

import argparse
import io
import math
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_learning_data as G  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

ROOT = G.ROOT
CACHE_DIR = Path.home() / "workspace" / "tile-cache"
OUT_PK = ROOT / "assets" / "learning" / "maps" / "pakistan"
OUT_WD = ROOT / "assets" / "learning" / "maps" / "world"

USER_AGENT = (
    "TestMindset/1.5 (educational app; offline map snapshots; "
    "contact: wali5737r@gmail.com)"
)
SUBDOMAINS = ("a", "b", "c")
MIN_INTERVAL = 0.26  # seconds between HTTP fetches (~4 req/s max)
BG_COLOR = (238, 235, 228)  # paper colour where no tile exists

# Snapshot zoom per Pakistan category: tight enough to read the
# place, wide enough to see what surrounds it.
PAK_ZOOM = {
    "Darya": 7,
    "Bandh/Barrage": 8,
    "Daray": 8,
    "Pahar": 7,
    "Doab": 8,
    "Heritage": 9,
    "Sarhad": 6,
    "Sahel": 7,
    "Registran/Maidan": 7,
    "Jheelain": 8,
}

# Snapshot zoom per World category.
WORLD_ZOOM = {
    "Samandar": 3,
    "Khaleej": 3,
    "Bay": 3,
    "Aabnaye": 6,
    "Canal/Aabnaye": 6,
    "Darya": 4,
    "Pahar": 5,
    "Registran": 4,
    "Jheelain": 5,
    "Jazire": 5,
}

_last_fetch = [0.0]
_sub_idx = [0]
stats = {"fetched": 0, "cached": 0, "failed_tiles": 0}


def fetch_tile(zoom, x, y):
    """One tile as an RGB PIL image, from the disk cache if present.

    x wraps around the antimeridian; y must already be in range.
    Returns None when the tile cannot be fetched at all."""
    n = 2**zoom
    x %= n
    cache_path = CACHE_DIR / str(zoom) / str(x) / f"{y}.png"
    if cache_path.exists():
        try:
            with Image.open(cache_path) as im:
                stats["cached"] += 1
                return im.convert("RGB")
        except Exception:
            cache_path.unlink(missing_ok=True)
    url = (
        f"https://{SUBDOMAINS[_sub_idx[0] % len(SUBDOMAINS)]}"
        f".tile.opentopomap.org/{zoom}/{x}/{y}.png"
    )
    _sub_idx[0] += 1
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    for attempt in range(3):
        wait = MIN_INTERVAL - (time.time() - _last_fetch[0])
        if wait > 0:
            time.sleep(wait)
        try:
            with urllib.request.urlopen(req, timeout=25) as resp:
                data = resp.read()
            _last_fetch[0] = time.time()
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            cache_path.write_bytes(data)
            stats["fetched"] += 1
            with Image.open(io.BytesIO(data)) as im:
                return im.convert("RGB")
        except Exception:
            _last_fetch[0] = time.time()
            if attempt < 2:
                time.sleep(1.0 + attempt)
    stats["failed_tiles"] += 1
    return None


def draw_marker(img, cx, cy):
    """Orange teardrop pin whose tip sits exactly on (cx, cy)."""
    d = ImageDraw.Draw(img, "RGBA")
    # soft shadow under the tip
    d.ellipse([cx - 10, cy - 3, cx + 10, cy + 4], fill=(0, 0, 0, 70))
    # teardrop: white ring, orange body, white centre dot
    d.polygon(
        [(cx - 10, cy - 17), (cx + 10, cy - 17), (cx, cy)],
        fill=(255, 255, 255, 255),
    )
    d.ellipse([cx - 16, cy - 42, cx + 16, cy - 10], fill=(255, 255, 255, 255))
    d.polygon(
        [(cx - 8, cy - 17), (cx + 8, cy - 17), (cx, cy - 1)],
        fill=(242, 108, 0, 255),
    )
    d.ellipse([cx - 13, cy - 39, cx + 13, cy - 13], fill=(242, 108, 0, 255))
    d.ellipse([cx - 5, cy - 31, cx + 5, cy - 21], fill=(255, 255, 255, 255))


def make_snapshot(lat, lon, zoom, out_path, width, height, quality):
    """Stitch tiles around (lat, lon) into one marked JPEG.

    Returns the number of tiles that actually landed in the image;
    0 means the snapshot is only background colour (a failure)."""
    lat = max(-85.0511, min(85.0511, lat))
    n = 2**zoom
    world_px = 256 * n
    cx = (lon + 180.0) / 360.0 * world_px
    phi = math.radians(lat)
    cy = (
        (1 - math.log(math.tan(phi) + 1 / math.cos(phi)) / math.pi)
        / 2
        * world_px
    )
    left = cx - width / 2
    top = cy - height / 2
    img = Image.new("RGB", (width, height), BG_COLOR)
    tiles_ok = 0
    x0 = math.floor(left / 256)
    x1 = math.floor((left + width - 1) / 256)
    y0 = math.floor(top / 256)
    y1 = math.floor((top + height - 1) / 256)
    for tx in range(x0, x1 + 1):
        for ty in range(y0, y1 + 1):
            if ty < 0 or ty >= n:
                continue  # beyond the poles: keep background colour
            tile = fetch_tile(zoom, tx, ty)
            if tile is None:
                continue
            img.paste(
                tile, (round(tx * 256 - left), round(ty * 256 - top))
            )
            tiles_ok += 1
    if tiles_ok == 0:
        return 0
    draw_marker(img, width // 2, height // 2)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path, "JPEG", quality=quality)
    return tiles_ok


def collect_jobs():
    """(label, lat, lon, zoom, out_path) for every snapshot."""
    jobs = []
    geo_dir = ROOT / "docs" / "geography"
    for fname, category in G.FEATURE_FILES:
        for f in G.parse_features(geo_dir / fname, category):
            zoom = PAK_ZOOM.get(f["category"], 8)
            jobs.append(
                (f"pakistan/{f['id']}", f["lat"], f["lon"], zoom,
                 OUT_PK / f"{f['id']}.jpg")
            )
    world_dir = ROOT / "docs" / "world"
    feats = G.parse_features(
        world_dir / "world-features.md",
        "Duniya",
        section_categories=G.WORLD_SECTION_CATEGORIES,
    )
    feats += G.parse_features(
        world_dir / "gulfs-straits.md",
        "Khaleej/Aabnaye",
        category_fn=G.gulfs_category,
    )
    for f in feats:
        zoom = WORLD_ZOOM.get(f["category"], 5)
        jobs.append(
            (f"world/{f['id']}", f["lat"], f["lon"], zoom,
             OUT_WD / f"{f['id']}.jpg")
        )
    for slug, name, lat, lon, zoom in G.OCEAN_SNAPSHOTS:
        jobs.append(
            (f"world/ocean-{slug} ({name})", lat, lon, zoom,
             OUT_WD / f"ocean-{slug}.jpg")
        )
    # Verify the country table against the doc's real headings.
    text = (world_dir / "countries.md").read_text(encoding="utf-8")
    blocks = G.split_blocks(text.split("\n"))
    headings = {
        G.block_text(b)
        for b in blocks
        if len(b) == 1 and G.is_heading(G.block_text(b))
    }
    for name, (lat, lon, zoom) in G.COUNTRY_SNAPSHOTS.items():
        if name not in headings:
            print(f"FATAL: country '{name}' is not a heading in countries.md")
            sys.exit(1)
        jobs.append(
            (f"world/country-{G.country_slug(name)} ({name})",
             lat, lon, zoom,
             OUT_WD / f"country-{G.country_slug(name)}.jpg")
        )
    return jobs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true",
                    help="rebuild snapshots that already exist")
    ap.add_argument("--width", type=int, default=720)
    ap.add_argument("--height", type=int, default=520)
    ap.add_argument("--quality", type=int, default=78)
    args = ap.parse_args()

    jobs = collect_jobs()
    print(f"{len(jobs)} snapshots to build "
          f"({args.width}x{args.height}, JPEG q{args.quality})")
    failures = []
    built = skipped = 0
    total_bytes = 0
    for i, (label, lat, lon, zoom, out_path) in enumerate(jobs, 1):
        if out_path.exists() and not args.force:
            skipped += 1
            total_bytes += out_path.stat().st_size
            continue
        tiles = make_snapshot(
            lat, lon, zoom, out_path, args.width, args.height, args.quality
        )
        if tiles == 0:
            failures.append(label)
            print(f"  [{i}/{len(jobs)}] FAILED (no tiles): {label}")
        else:
            built += 1
            total_bytes += out_path.stat().st_size
            if i % 25 == 0 or built <= 3:
                print(f"  [{i}/{len(jobs)}] {label}: {tiles} tiles")
    print(
        f"\nDone: {built} built, {skipped} already present, "
        f"{len(failures)} failed."
    )
    print(
        f"Tiles: {stats['fetched']} fetched, {stats['cached']} from cache, "
        f"{stats['failed_tiles']} failed."
    )
    print(f"Snapshot assets total: {total_bytes / 1e6:.2f} MB")
    if failures:
        print("FAILED SNAPSHOTS:")
        for f in failures:
            print(" -", f)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

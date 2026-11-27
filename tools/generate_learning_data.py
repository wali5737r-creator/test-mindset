#!/usr/bin/env python3
"""Generate Dart learning data for Test Mindset's Learning Mode.

Converts the markdown masters in docs/ into const Dart data files under
lib/learning/data/:

  docs/lessons/grammar-NN.md   -> english_lessons_a/b/c.dart (49 lessons)
  docs/geography/<feature>.md  -> geography_data.dart (MapFeature list)
  docs/geography/terms.md      -> geography_data.dart (GeoTopic list)
  docs/geography/provinces.md  -> geography_data.dart (GeoTopic list)
  docs/pakstudy/*.md           -> geography_data.dart (GeoTopic list,
                                  Pakistan portion, after geography)
  docs/world/*.md              -> world_data.dart (WorldFeature list for
                                  the world map + GeoTopic list)
  docs/space/*.md              -> space_data.dart (GeoTopic list +
                                  PlanetSection list from solar-system)
  docs/computer/*.md           -> computer_data.dart (GeoTopic list)
  docs/maths/*.md              -> maths_lessons.dart (Lesson list)
  docs/urdu/*.md               -> urdu_data.dart (GeoTopic list)
  docs/islamiat/*.md           -> islamiat_data.dart (GeoTopic list)
  docs/history/*.md            -> history_data.dart (GeoTopic list)
  docs/orgs/*.md               -> orgs_data.dart (GeoTopic list)
  docs/eds/*.md                -> eds_data.dart (GeoTopic list)

Usage:
  python3 tools/generate_learning_data.py
      [lessons|geography|world|topics|maths|all]

The masters are the source of truth. If something does not parse, fix
this parser, never the generated data and never the masters.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LESSONS_DIR = ROOT / "docs" / "lessons"
GEO_DIR = ROOT / "docs" / "geography"
OUT_DIR = ROOT / "lib" / "learning" / "data"

# ---------------------------------------------------------------------------
# English parts (owner's mapping, 2026-11-27). Every lesson 1..49 in exactly
# one part; lesson numbers keep course order inside each part.
# v2.0 additions: 47 Punctuation -> Part 5, 48 Conditionals -> Part 4,
# 49 Question Tags -> Part 5.
# ---------------------------------------------------------------------------
PARTS = [
    ("Foundation — Getting Started", [1, 2, 3, 4, 6, 7]),
    ("Nouns & Pronouns in Depth", [13, 14, 26]),
    ("Adjectives, Adverbs & Degrees", [8, 17, 27]),
    ("Verbs & Tenses", [9, 18, 19, 20, 31, 48]),
    ("Sentences — Questions, Negatives & Commands", [10, 11, 12, 28, 47, 49]),
    ("Small Words — Prepositions & Usage", [5, 16, 21, 34]),
    ("Helping Verbs & Modals", [15, 32, 33]),
    ("Voice & Narration", [24, 29, 30]),
    ("Infinitive, Gerund & Participle", [22, 23]),
    ("Parts of Speech — Complete Review", [25]),
    ("Vocabulary — Idioms, Proverbs, Phrasal Verbs", [35, 36, 37]),
    ("Vocabulary — One Word, Synonyms, Confusing Words", [38, 39, 40]),
    ("Common Mistakes — Spot the Error", [41, 42, 43, 44, 45, 46]),
]
LESSON_PART = {}
for _i, (_name, _nums) in enumerate(PARTS):
    for _n in _nums:
        LESSON_PART[_n] = (_i, _name)

# Geography feature docs -> map category (chip label).
FEATURE_FILES = [
    ("rivers.md", "Rivers"),
    ("dams-barrages.md", "Dams & Barrages"),
    ("doabs.md", "Doabs"),
    ("passes.md", "Passes"),
    ("mountains.md", "Mountains"),
    ("deserts-plains.md", "Deserts & Plains"),
    ("borders.md", "Borders"),
    ("heritage.md", "Heritage Sites"),
    ("coast-ports.md", "Coast & Ports"),
    ("lakes.md", "Lakes"),
]
TOPIC_FILES = ["terms.md", "provinces.md"]

# Pak Studies docs join the Pakistan portion as reading topics.
PAKSTUDY_FILES = [
    "movement.md",
    "leaders.md",
    "constitutions-govt.md",
    "symbols-firsts.md",
]

# World map: section heading -> chip category in world-features.md.
WORLD_SECTION_CATEGORIES = {
    "Duniya ke mashhoor darya": "Rivers",
    "Duniya ke mashhoor registran": "Deserts",
    "Duniya ki mashhoor chotiyan aur silsile": "Mountains",
    "Mashhoor canals aur aabnayen, yani straits": "Canals & Straits",
    "Mashhoor jheelain aur neechi jagah": "Lakes",
    "Mashhoor jazire": "Islands",
}


def gulfs_category(name):
    """Chip category for a gulfs-straits.md feature, from its name."""
    if "Strait" in name or "Channel" in name:
        return "Straits"
    if "Gulf" in name:
        return "Gulfs"
    if "Bay" in name:
        return "Bays"
    if "Sea" in name:
        return "Seas & Oceans"
    return "Straits"  # Bab el-Mandeb, Dardanelles/Bosphorus


# ---------------------------------------------------------------------------
# v1.5 map snapshots. The images themselves are built by
# tools/generate_map_snapshots.py (OpenTopoMap tiles stitched offline);
# this generator only REFERENCES them and fails loudly if any file is
# missing, so a data build can never ship a dangling image path.
# ---------------------------------------------------------------------------

def feature_asset(portion, feature_id):
    return f"assets/learning/maps/{portion}/{feature_id}.jpg"


# The five oceans: (slug, display name, centre lat, centre lon, zoom).
# Centres chosen so the surrounding continents/countries are visible.
OCEAN_SNAPSHOTS = [
    ("pacific", "Pacific Ocean", -5.0, -150.0, 2),
    ("atlantic", "Atlantic Ocean", 15.0, -30.0, 3),
    ("indian", "Indian Ocean", -15.0, 75.0, 3),
    ("southern", "Southern Ocean", -65.0, -90.0, 2),
    ("arctic", "Arctic Ocean", 80.0, 0.0, 2),
]


def ocean_asset(slug):
    return f"assets/learning/maps/world/ocean-{slug}.jpg"


# countries.md heading -> (centre lat, centre lon, snapshot zoom).
# Zoom 4 by default, 3 for the giant countries, 5 for small ones.
COUNTRY_SNAPSHOTS = {
    "China": (35.0, 105.0, 4),
    "India": (22.5, 79.0, 4),
    "Japan": (37.5, 138.0, 5),
    "Saudi Arabia": (24.0, 45.0, 4),
    "Iran": (32.4, 53.7, 4),
    "United Arab Emirates": (24.2, 54.4, 5),
    "Bangladesh": (23.7, 90.4, 5),
    "Sri Lanka": (7.9, 80.8, 5),
    "Nepal": (28.2, 84.1, 5),
    "Afghanistan": (33.9, 67.7, 4),
    "Indonesia": (-2.2, 118.0, 4),
    "Malaysia": (4.2, 102.0, 4),
    "Thailand": (15.9, 101.0, 5),
    "South Korea": (36.5, 128.0, 5),
    "Turkey": (39.0, 35.2, 4),
    "Russia": (62.0, 105.0, 3),
    "Egypt": (26.8, 30.8, 4),
    "United Kingdom": (54.0, -2.5, 5),
    "France": (46.6, 2.5, 5),
    "Germany": (51.1, 10.4, 5),
    "Italy": (42.8, 12.8, 5),
    "Spain": (40.2, -3.6, 5),
    "Greece": (39.0, 22.0, 5),
    "USA": (39.8, -98.6, 3),
    "Canada": (57.0, -101.0, 3),
    "Brazil": (-10.8, -52.9, 3),
    "Argentina": (-38.4, -63.6, 4),
    "Nigeria": (9.6, 8.0, 5),
    "Australia": (-25.3, 133.8, 3),
    "New Zealand": (-41.8, 172.8, 5),
}


def country_slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def country_asset(name):
    return f"assets/learning/maps/world/country-{country_slug(name)}.jpg"


# Snapshot asset paths referenced by the generated data but missing on
# disk. Any entry here fails the whole generation (see main()).
map_image_missing = []


def require_map_image(asset):
    if not (ROOT / asset).exists():
        map_image_missing.append(asset)
        problems.append(
            f"map snapshot missing: {asset} "
            f"(run tools/generate_map_snapshots.py first)"
        )


# Solar system sections: (id, heading needle). Sun matches by prefix.
PLANETS = [
    ("sun", "Suraj"),
    ("mercury", ": Mercury"),
    ("venus", ": Venus"),
    ("earth", ": Earth"),
    ("mars", ": Mars"),
    ("jupiter", ": Jupiter"),
    ("saturn", ": Saturn"),
    ("uranus", ": Uranus"),
    ("neptune", ": Neptune"),
]

MATHS_ORDER = [
    "percentage",
    "profit-loss",
    "interest",
    "average",
    "ratio-partnership",
    "time-work",
    "speed-distance",
    "number-basics",
    "geometry",
]

# Generic reading-topic portions:
# (portion, docs subdir, file stems in order, tasveer mode, out file, var)
TOPIC_PORTIONS = [
    ("space", "space", ["solar-system", "atmosphere", "space-objects"],
     "card", "space_data.dart", "spaceTopics"),
    ("computer", "computer",
     ["fundamentals", "ms-word", "ms-excel", "ms-powerpoint", "shortcuts",
      "practical-word", "practical-excel", "practical-windows"],
     "card", "computer_data.dart", "computerTopics"),
    ("urdu", "urdu",
     ["ghazal-istilahaat", "asnaaf", "qawaid", "alfaaz-muhawaray",
      "adab-facts"],
     "keep", "urdu_data.dart", "urduTopics"),
    ("islamiat", "islamiat",
     ["quran", "hadees", "seerat", "ghazwaat", "khulafa-sahaba",
      "arkan-iman"],
     "card", "islamiat_data.dart", "islamiatTopics"),
    ("history", "history",
     ["sultanate", "mughal", "wars-712-1947", "wars-1947-2026"],
     "card", "history_data.dart", "historyTopics"),
    ("orgs", "orgs", ["organizations", "treaties"], "strip",
     "orgs_data.dart", "orgsTopics"),
    ("eds", "eds",
     ["human-body", "health-food", "plants-nature", "physics-chemistry"],
     "card", "eds_data.dart", "edsTopics"),
]

NUM_RE = re.compile(r"^(\d+)\.\s+(.*)$")
OPT_RE = re.compile(r"^([A-D])\.\s+(.*)$")
GHALAT_RE = re.compile(r"^(?:\d+\.\s*)?Ghalat:\s*(.*)$")
SAHI_RE = re.compile(r"^Sahi:\s*(.*)$")
WAJAH_RE = re.compile(r"^Wajah:\s*(.*)$")
KEY_RE = re.compile(r"^(\d+)\.\s+Jawab\s+([A-D])\b\s*(.*)$")
PIN_RE = re.compile(r"^Pin:\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)$")
TITLE_RE = re.compile(r"^Lesson\s+(\d+):\s*(.*)$")

problems = []


def split_blocks(lines):
    """Split raw lines into blocks separated by blank lines."""
    blocks, cur = [], []
    for ln in lines:
        if ln.strip() == "":
            if cur:
                blocks.append(cur)
                cur = []
        else:
            cur.append(ln.rstrip())
    if cur:
        blocks.append(cur)
    return blocks


def block_text(block):
    return " ".join(l.strip() for l in block)


def is_heading(text):
    """A single short line that does not end like a sentence."""
    if len(text) > 95 or NUM_RE.match(text):
        return False
    return not text.endswith((".", "!", "?", ":", '"', "…", ")"))


def is_feature_heading(text):
    """Heading test for map features in parse_features.

    Like is_heading, but a short title carrying a parenthetical
    second name still counts as a heading — e.g. 'Persian Gulf
    (Khaleej-e-Faris)', which is_heading rejects for ending in ')'.
    Without this, such a feature took the previous section's heading
    as its name (gulfs-straits-01 shipped as 'Ye topic kyun zaroori
    hai', the intro heading, in v1.3–v1.5).
    """
    if is_heading(text):
        return True
    if len(text) > 95 or NUM_RE.match(text):
        return False
    return text.endswith(")") and "(" in text


def parse_traps(block):
    """One block may hold one or more Ghalat/Sahi/Wajah triples."""
    traps = []
    cur = None
    field = None
    for raw in block:
        ln = raw.strip()
        m = GHALAT_RE.match(ln)
        if m:
            cur = {"type": "trap", "wrong": m.group(1).strip(),
                   "right": "", "note": ""}
            traps.append(cur)
            field = "wrong"
            continue
        if cur is None:
            continue
        m = SAHI_RE.match(ln)
        if m:
            cur["right"] = m.group(1).strip()
            field = "right"
            continue
        m = WAJAH_RE.match(ln)
        if m:
            cur["note"] = m.group(1).strip()
            field = "note"
            continue
        if field:
            cur[field] = (cur[field] + " " + ln).strip()
    return traps


def split_numbered(block):
    """Split a block into numbered segments. Returns (lead_lines, segments)
    where each segment is (first_line_text, [note_lines]). A line matching
    'N. ...' starts a new segment; other lines extend the current one."""
    lead, segments = [], []
    cur = None
    for raw in block:
        ln = raw.strip()
        m = NUM_RE.match(ln)
        if m:
            cur = (m.group(2).strip(), [])
            segments.append(cur)
        elif cur is not None:
            cur[1].append(ln)
        else:
            lead.append(ln)
    return lead, segments


TASVEER_PREFIX = "Tasveer ka khayal"


def _tasveer_items(blocks, mode):
    """Split raw blocks into ('block', block) / ('visual', text) items.

    A 'Tasveer ka khayal' line (its own block, a bare heading block
    followed by a description block, or a line mid-block) and everything
    after an 'Aakhir me tasveer...' heading becomes a visual item in
    mode 'card', and is dropped entirely in mode 'strip'."""
    items = []
    pending_label = False  # bare 'Tasveer ka khayal' heading seen
    rest_visual = False  # 'Aakhir me tasveer...' heading seen
    for b in blocks:
        first = b[0].strip() if b else ""
        if len(b) == 1 and first == TASVEER_PREFIX:
            pending_label = True
            continue
        if len(b) == 1 and first.startswith("Aakhir me tasveer"):
            rest_visual = True
            continue
        idx = None
        for i, ln in enumerate(b):
            if ln.strip().startswith(TASVEER_PREFIX):
                idx = i
                break
        if idx is not None:
            if idx > 0:
                items.append(("block", b[:idx]))
            if mode == "card":
                visual_text = block_text(b[idx:])
                visual_text = (
                    visual_text[len(TASVEER_PREFIX):].lstrip(": ").strip()
                )
                if visual_text:
                    items.append(("visual", visual_text))
            pending_label = False
            continue
        if pending_label or rest_visual:
            if mode == "card":
                items.append(("visual", block_text(b)))
            pending_label = False
            continue
        items.append(("block", b))
    return items


def body_blocks(blocks, tasveer="keep"):
    """Classify raw blocks into heading / paragraph / example / rule / trap
    (plus visual items when tasveer is 'card'), preserving order and
    full text."""
    if tasveer == "keep":
        items = [("block", b) for b in blocks]
    else:
        items = _tasveer_items(blocks, tasveer)
    out = []
    in_rule = False
    for kind, b in items:
        if kind == "visual":
            out.append({"type": "visual", "text": b})
            continue
        if any(GHALAT_RE.match(l.strip()) for l in b):
            out.extend(parse_traps(b))
            continue
        text = block_text(b)
        if len(b) == 1 and is_heading(text):
            low = text.lower()
            in_rule = "qanoon" in low and "angrezi" in low
            out.append({"type": "heading", "text": text})
            continue
        lead, segments = split_numbered(b)
        if segments:
            if lead:
                joined = " ".join(lead)
                out.append({"type": "rule" if in_rule else "paragraph",
                            "text": joined})
            for first, notes in segments:
                out.append({
                    "type": "example",
                    "text": first,
                    "note": " ".join(notes).strip(),
                })
            continue
        if in_rule:
            out.append({"type": "rule", "text": text})
        else:
            out.append({"type": "paragraph", "text": text})
    return out


# ---------------------------------------------------------------------------
# v2.0 diagram wiring. The owner banned text "Visual Guide" blocks:
# every 'Tasveer ka khayal' visual block must become a real IMAGE block
# (LessonBlock.image) whose picture was built for exactly that section.
# The mapping follows the batch manifests in
# ~/workspace/test-mindset-diagrams/v2/*/manifest.md, keyed by source
# doc stem + the section heading the visual sits under. Any visual
# block with no mapped diagram is recorded in visual_unmapped and
# fails the whole generation (see main()).
#
# Assets live in assets/learning/diagrams/<batch>/ (PNG masters were
# converted to JPG q73, max width 1050; tile-stitch JPGs copied as-is).
# The 9 wars snapshots whose sections the history batch did not cover
# (sindh-712, punjab-lahore, kashmir-1947, dhaka-1971, siachen-1984,
# kargil-1999, europe-ww1, ww2-europe, ww2-pacific) were stitched with
# the batch's own make_maps.py pipeline during the v2.0 build.
# ---------------------------------------------------------------------------

DIAG = "assets/learning/diagrams"
C_ = f"{DIAG}/computer"
E_ = f"{DIAG}/eds"
H_ = f"{DIAG}/history"
V_ = f"{DIAG}/visual-notes"
G_ = f"{DIAG}/geo-maps"

visual_unmapped = []
diagram_missing = []
wire_counts = {"visual_replaced": 0, "inserted": 0, "lead": 0}
visuals_by_stem = {}


def require_diagram_image(asset):
    if not (ROOT / asset).exists():
        diagram_missing.append(asset)
        problems.append(f"diagram image missing: {asset}")


def _img(asset, caption):
    require_diagram_image(asset)
    return {"type": "image", "text": asset, "note": caption}


# (stem, heading) -> [(asset, caption), ...] replacing that section's
# visual block. A block may expand to two images (simple machines).
VISUAL_MAP = {
    # --- Computer (manifest: v2/computer, all 60 lines) ---
    "ms-word": {
        "Word kya hai aur kis kaam ata hai": [
            (f"{C_}/word-extensions.jpg", "Word Files — .doc and .docx")],
        "Word ki window ke hisse": [
            (f"{C_}/word-window.jpg", "MS Word Window — every part labelled")],
        "Har tab me kya milta hai": [
            (f"{C_}/word-ribbon-tabs.jpg", "The Ribbon — what each tab holds")],
        "Home tab ki tafseel": [
            (f"{C_}/word-home-formatting.jpg",
             "Home Tab — Font and Paragraph groups")],
        "Font size wali khaas tafseel": [
            (f"{C_}/word-font-size.jpg",
             "Font Size — the list, and typing up to 1638")],
        "Page setup ki baatein": [
            (f"{C_}/page-setup.jpg",
             "Page Setup — Portrait, Landscape and margins")],
        "Insert tab aur table ki baatein": [
            (f"{C_}/word-table.jpg", "Tables — rows, columns and cells")],
        "Find, Replace, Spelling aur Thesaurus": [
            (f"{C_}/word-spelling.jpg",
             "Spelling Check — the red zigzag and F7")],
        "Mail Merge kya hai": [
            (f"{C_}/mail-merge.jpg", "Mail Merge — how it works")],
        "Header, Footer aur Page Number": [
            (f"{C_}/header-footer.jpg", "Header, Footer and Page Number")],
        "Zoom aur Views": [
            (f"{C_}/word-views-zoom.jpg",
             "Views and Zoom — five ways to see a page")],
        "Print aur Save": [
            (f"{C_}/word-save-print.jpg", "Save and Print — Ctrl+S, F12, Ctrl+P")],
    },
    "ms-excel": {
        "Pehle Excel ko samajh lo": [
            (f"{C_}/excel-register.jpg", "From Paper Register to Excel")],
        "File ki pehchan, extension aur default naam": [
            (f"{C_}/word-extensions.jpg", "Excel Files — .xls and .xlsx")],
        "Workbook aur Worksheet ka farq": [
            (f"{C_}/excel-workbook.jpg", "Workbook and Worksheets")],
        "Rows, Columns aur Cell": [
            (f"{C_}/excel-grid.jpg", "Rows, Columns and Cells")],
        "Name Box aur Formula Bar": [
            (f"{C_}/excel-window.jpg",
             "Excel Window — Name Box and Formula Bar")],
        "Data ki teen types": [
            (f"{C_}/excel-data-types.jpg",
             "Three Data Types — Text, Number, Formula")],
        "Mashhoor functions": [
            (f"{C_}/excel-formulas.jpg",
             "Famous Functions — SUM, AVERAGE, MAX, MIN, IF")],
        "Cell Reference, relative aur absolute ka farq": [
            (f"{C_}/excel-formulas.jpg",
             "Cell References — A1 versus $A$1, and F4")],
        "Roz ke kaam aur un ke tabs": [
            (f"{C_}/excel-chart-sort.jpg",
             "Everyday Jobs — charts, sort and filter")],
        "Zoom aur screen ka aakhri hissa": [
            (f"{C_}/excel-finish.jpg", "The Status Bar and Zoom Slider")],
    },
    "ms-powerpoint": {
        "Pehle PowerPoint ko samajh lo": [
            (f"{C_}/ppt-intro.jpg", "PowerPoint — the stage idea")],
        "File ki pehchan, extension aur default naam": [
            (f"{C_}/word-extensions.jpg",
             "PowerPoint Files — .ppt, .pptx and .ppsx")],
        "Slide, Layout aur Placeholder": [
            (f"{C_}/ppt-slides-layout.jpg",
             "Slides, Layouts and Placeholders")],
        "Default view, Normal aur baqi views": [
            (f"{C_}/powerpoint-window.jpg",
             "PowerPoint Window — the Normal view")],
        "Tabs ka khulasa": [
            (f"{C_}/ppt-ribbon.jpg", "PowerPoint Tabs at a Glance")],
        "Transitions aur Animations ka farq": [
            (f"{C_}/ppt-transitions-animations.jpg",
             "Transitions versus Animations")],
        "Slideshow chalana": [
            (f"{C_}/ppt-keys.jpg", "Running the Show — F5, Shift+F5, Esc")],
        "Slide ka size, 4:3 aur 16:9": [
            (f"{C_}/ppt-slide-sizes.jpg", "Slide Sizes — 4:3 and 16:9")],
        "Notes aur Handouts": [
            (f"{C_}/ppt-handouts.jpg", "Notes and Handouts")],
        "Master Slide": [
            (f"{C_}/ppt-master.jpg", "Slide Master — one master, many slides")],
        "Rehearse Timings": [
            (f"{C_}/ppt-rehearse.jpg", "Rehearse Timings")],
    },
    "practical-word": {
        "Kaam 1: Application ya letter likhna": [
            (f"{C_}/word-application.jpg", "A Finished Application, Part by Part")],
        "Kaam 2: Formatting — likhai ko sajana": [
            (f"{C_}/word-home-formatting.jpg", "Formatting with the Home Tab")],
        "Kaam 3: CV ya Resume banana": [
            (f"{C_}/word-cv.jpg", "A Finished CV")],
        "Kaam 4: Table banana aur us me result likhna": [
            (f"{C_}/word-table.jpg", "The Result Table")],
        "Kaam 5: List, page number aur header": [
            (f"{C_}/header-footer.jpg", "Header and Page Number in Place")],
        "Kaam 6: Save karna, PDF banana aur print karna": [
            (f"{C_}/word-save-print.jpg", "Print, PDF and Save")],
        "Kaam 7: Spelling check chala kar document saaf karna": [
            (f"{C_}/word-spelling.jpg", "Cleaning a Document with Spell Check")],
    },
    "practical-excel": {
        "Qadam 1: Headings likhna": [
            (f"{C_}/excel-grid.jpg", "Step 1 — Headings on the Grid")],
        "Qadam 2: Data enter karna aur sheet ko saaf karna": [
            (f"{C_}/excel-finish.jpg", "Step 2 — A Clean Sheet, Bold Header Row")],
        "Qadam 3: Total ka formula — SUM": [
            (f"{C_}/excel-formulas.jpg", "Step 3 — The SUM Formula")],
        "Qadam 4: Percentage ka formula": [
            (f"{C_}/excel-percent-fill.jpg",
             "Step 4 — Percentage with the % Button")],
        "Qadam 5: Status ke liye IF ka formula": [
            (f"{C_}/excel-formulas.jpg",
             "Step 5 — The IF Formula for PASS and FAIL")],
        "Qadam 6: Fill handle — formula sab par lagana": [
            (f"{C_}/excel-percent-fill.jpg", "Step 6 — The Fill Handle")],
        "Qadam 7: Class ki report — AVERAGE, MAX aur MIN": [
            (f"{C_}/excel-formulas.jpg", "Step 7 — AVERAGE, MAX and MIN")],
        "Qadam 8: Sort karna aur filter lagana": [
            (f"{C_}/excel-chart-sort.jpg", "Step 8 — Sort and Filter")],
        "Qadam 9: Print ke liye tayyar karna": [
            (f"{C_}/excel-finish.jpg", "Step 9 — Ready to Print")],
    },
    "practical-windows": {
        "Kaam 1: File aur folder banana, naam badalna": [
            (f"{C_}/windows-menus.jpg",
             "New Folder and Rename — the Right-Click Menu")],
        "Kaam 2: Copy paste aur cut paste ka farq": [
            (f"{C_}/windows-copy-cut.jpg", "Copy versus Cut")],
        "Kaam 3: Delete karna aur Recycle Bin se wapas lana": [
            (f"{C_}/windows-menus.jpg",
             "Delete, and Restore from the Recycle Bin")],
        "Kaam 4: Screenshot lena": [
            (f"{C_}/windows-tools.jpg", "Taking a Screenshot")],
        "Kaam 5: File ko zip karna aur kholna": [
            (f"{C_}/windows-menus.jpg", "Zip a File — Send to Compressed Folder")],
        "Kaam 6: USB lagana aur safely nikalna": [
            (f"{C_}/windows-tools.jpg", "USB — Plug In and Eject Safely")],
        "Kaam 7: Program install aur uninstall karna": [
            (f"{C_}/windows-tools.jpg", "Install and Uninstall — Settings, Apps")],
        "Kaam 8: Task Manager se hang program band karna": [
            (f"{C_}/windows-tools.jpg", "Task Manager — End a Stuck Program")],
        "Qadam 2: Nayi slides lagana": [
            (f"{C_}/ppt-slides-layout.jpg", "Adding New Slides")],
        "Qadam 4: Transition lagana — slide badalne ka andaaz": [
            (f"{C_}/ppt-transitions-animations.jpg", "Adding a Transition")],
        "Achhi presentation ke usool": [
            (f"{C_}/windows-slides-good-bad.jpg", "Good Slide versus Bad Slide")],
    },
    # --- Everyday Science (manifests: v2/eds-body, v2/eds-nature) ---
    "human-body": {
        "Dil — jism ka pump": [
            (f"{E_}/heart.jpg", "The Heart — four chambers")],
        "Khoon — jism ki delivery service": [
            (f"{E_}/blood.jpg", "Blood — cells and blood groups")],
        "Aankh — jism ka camera": [
            (f"{E_}/eye.jpg", "The Eye — how we see")],
        "Kaan — sunna aur tawazun": [
            (f"{E_}/ear.jpg", "The Ear — three parts")],
        "Haddiyan — jism ka dhancha": [
            (f"{E_}/skeleton.jpg", "The Skeleton — 206 bones")],
        "Dimaagh — jism ka control room": [
            (f"{E_}/brain.jpg", "The Brain — the control room")],
        "Paachan ka nizam — khana se taqat tak": [
            (f"{E_}/digestive.jpg", "The Digestive System")],
        "Chamra — jism ki deewar": [
            (f"{E_}/skin.jpg", "Skin — three layers")],
        "Sans ka nizam — hawa ka ana jana": [
            (f"{E_}/breathing.jpg", "Breathing — lungs and diaphragm")],
    },
    "health-food": {
        "Vitamin A — aankhon wala vitamin": [
            (f"{E_}/vitamin-a.jpg", "Vitamin A — eyes and night blindness")],
        "Vitamin B group — taqat aur aasab wala khandaaan": [
            (f"{E_}/vitamin-b.jpg", "Vitamin B1 — polished rice and beriberi")],
        "Vitamin C — zakham bharne wala, malte wala vitamin": [
            (f"{E_}/vitamin-c.jpg", "Vitamin C — citrus fruits and scurvy")],
        "Vitamin D — sooraj ki roshni wala vitamin": [
            (f"{E_}/vitamin-d.jpg", "Vitamin D — sunlight and rickets")],
        "Vitamin E aur Vitamin K — do chhote lekin lazmi naam": [
            (f"{E_}/vitamin-k.jpg", "Vitamin K — blood clotting")],
        "Minerals — haddi, khoon aur gale ke teen naam": [
            (f"{E_}/minerals.jpg", "Minerals — calcium, iron, iodine")],
        "Ab bimariyan — pehle bacteria aur virus ka farq": [
            (f"{E_}/bacteria-virus.jpg", "Bacteria versus Virus")],
        "Mashhoor bimariyan aur un ki wajah": [
            (f"{E_}/mosquito.jpg", "Dengue versus Malaria — two mosquitoes")],
        "Vaccine kya hai aur kaam kesay karti hai": [
            (f"{E_}/vaccine.jpg", "How a Vaccine Trains the Body")],
        "Aakhir me safai — sab se sasti dawai": [
            (f"{E_}/hygiene.jpg", "Cleanliness — breaking the germ chain")],
    },
    "plants-nature": {
        "Phool ke hisse, ankh se dekho": [
            (f"{E_}/flower.jpg", "Parts of a Flower")],
        "Photosynthesis, pauda khana kesay banata hai": [
            (f"{E_}/photosynthesis.jpg", "Photosynthesis — how a plant cooks")],
        "Beej se pauda, germination ke marhalay": [
            (f"{E_}/germination.jpg", "Germination — seed to plant")],
        "Pani ka cycle, wahi pani bar bar": [
            (f"{E_}/water-cycle.jpg", "The Water Cycle")],
        "Mausam aur hawa, baadal, barish aur garaj chamak": [
            (f"{E_}/rainbow.jpg", "Rainbow — seven colours in order")],
        "Greenhouse effect aur global warming": [
            (f"{E_}/greenhouse.jpg", "The Greenhouse Effect")],
        "Chaand, sooraj aur grehan, dikhne wali baat": [
            (f"{E_}/grehan.jpg", "Eclipses — solar and lunar")],
    },
    "physics-chemistry": {
        "Roshni, sab se tez musafir": [
            (f"{E_}/lens-mirror.jpg", "Lenses — convex and concave")],
        "Awaaz, lehrain jo sunai deti hain": [
            (f"{E_}/echo.jpg", "Echo — sound coming back")],
        "Bijli, taar ke andar dodti taaqat": [
            (f"{E_}/electricity.jpg", "Electricity — units, fuse and MCB")],
        "Simple machines, kaam asaan karne wale purane dost": [
            (f"{E_}/lever.jpg", "Simple Machines — the three levers"),
            (f"{E_}/pulley.jpg", "Simple Machines — pulley and slope")],
        "Magnet, wo loha jo khud kheenchta hai": [
            (f"{E_}/magnet.jpg", "Magnet — poles and compass")],
        "Density, barf tairti kyun hai aur loha doobta kyun hai": [
            (f"{E_}/density.jpg", "Density — why ice floats and iron sinks")],
        "Tezab aur base, litmus wala khel": [
            (f"{E_}/ph-scale.jpg", "Acids and Bases — the pH scale")],
        "Hawa aur pani, do zaroori cheezain gin kar": [
            (f"{E_}/air-composition.jpg", "Air — 78% nitrogen, 21% oxygen")],
        "Dhaten, para, tungsten aur zang": [
            (f"{E_}/metals.jpg", "Metals — mercury, tungsten and rust")],
        "Aijadaat aur scientists, cheez aur us ka banane wala": [
            (f"{E_}/scientists.jpg", "Inventions and Their Inventors")],
    },
    # --- Islamiat (manifest: v2/history-islamiat) ---
    "ghazwaat": {
        "Ghazwa-e-Badr, jang jo sab kuch badal gayi": [
            (f"{H_}/ghazwa-badr.jpg", "Map — Badr, south-west of Madinah")],
        "Ghazwa-e-Uhud, jeet-ti hui jang ka rukh kesay badla": [
            (f"{H_}/ghazwa-madinah.jpg", "Map — Madinah, with Uhud in its north")],
        "Ghazwa-e-Khandaq, jab khandaq ne das hazar ko rok diya": [
            (f"{H_}/ghazwa-madinah.jpg", "Map — Madinah, the trench city")],
        "Saal-war tartib, aakhir me aik nazar": [
            (f"{H_}/ghazwa-madinah.jpg", "Map — Madinah at the centre")],
    },
    "seerat": {
        "Paper ke fix nuktaat": [
            (f"{H_}/seerat-timeline.jpg", "Seerat Timeline — 571 to 632")],
    },
    # --- History (manifest: v2/history-islamiat) ---
    "wars-712-1947": {
        "Muhammad bin Qasim aur Sindh ki fatah, 712": [
            (f"{H_}/sindh-712.jpg", "Map — Sindh, land of the 712 campaign")],
        "Tarain ki dusri jang, 1192": [
            (f"{H_}/battle-tarain.jpg", "Map — Tarain, near Karnal")],
        "Panipat ki pehli jang, 1526": [
            (f"{H_}/battle-panipat.jpg", "Map — Panipat")],
        "Panipat ki dusri jang, 1556": [
            (f"{H_}/battle-panipat.jpg", "Map — Panipat")],
        "Plassey ki jang, 1757": [
            (f"{H_}/battle-plassey.jpg", "Map — Plassey on the Bhagirathi")],
        "Panipat ki teesri jang, 1761": [
            (f"{H_}/battle-panipat.jpg", "Map — Panipat")],
        "Buxar ki jang, 1764": [
            (f"{H_}/battle-buxar.jpg", "Map — Buxar on the Ganga")],
        "Mysore ki jangain aur Tipu Sultan, 1767 se 1799": [
            (f"{H_}/battle-seringapatam.jpg",
             "Map — Seringapatam, near Mysuru")],
        "Anglo-Sikh jangain aur Punjab ka qabza, 1845 se 1849": [
            (f"{H_}/punjab-lahore.jpg", "Map — Punjab of the five rivers")],
        "1857 ki Jang-e-Azadi": [
            (f"{H_}/battle-delhi1857.jpg", "Map — Delhi, heart of 1857")],
    },
    "wars-1947-2026": {
        "Pehli jang, 1947 se 1948. Kashmir se shuru hone wali kahani": [
            (f"{H_}/kashmir-1947.jpg", "Map — Kashmir and Srinagar")],
        "1965 ki jang. 6 September ka din": [
            (f"{H_}/punjab-lahore.jpg", "Map — Lahore and the 1965 front")],
        "1971 ki jang. Mashriqi Pakistan ka alag hona": [
            (f"{H_}/dhaka-1971.jpg", "Map — Dhaka")],
        "Siachen, 1984. Duniya ka sab se uncha maidan-e-jang": [
            (f"{H_}/siachen-1984.jpg",
             "Map — Siachen, the highest battlefield")],
        "Kargil ki jang, 1999. LoC ke paar mahdood takrao": [
            (f"{H_}/kargil-1999.jpg", "Map — Kargil")],
        "Pehli Aalmai Jang, 1914 se 1918": [
            (f"{H_}/europe-ww1.jpg", "Map — Europe in the First World War")],
        "Dusri Aalmai Jang, 1939 se 1945": [
            (f"{H_}/ww2-europe.jpg", "Map — Europe in the Second World War"),
            (f"{H_}/ww2-pacific.jpg",
             "Map — Japan and the Pacific, where the war ended")],
    },
    # --- Space: both recap visuals describe the planets page ---
    "solar-system": {
        "Sab se wali recap — paper ke pakke sawal": [
            (f"{V_}/planets.jpg", "The Solar System — Sun and eight planets")],
    },
}

# Per-occurrence override for repeated visuals under one heading:
# the second solar-system recap visual is the 'sab se' chart, which
# the same planets page carries as its per-planet paper points.
VISUAL_MAP_OCC = {
    ("solar-system", "Sab se wali recap — paper ke pakke sawal", 1): [
        (f"{V_}/planets.jpg",
         "Sab Se Chart — biggest, hottest, farthest, most moons")],
}

# Image inserted right after a section heading (or at the section's
# end) where the doc has no visual block of its own.
# (stem -> [(kind, heading prefix, asset, caption)])
SECTION_INSERTS = {
    "health-food": [
        ("after", "Vitamin kya hai", f"{E_}/vitamins.jpg",
         "Vitamins at a Glance — A, B, C, D, E and K"),
    ],
    "quran": [
        ("after", "Ab numbers ka poora hisaab", f"{H_}/quran-facts.jpg",
         "The Quran in Numbers — 114 Surahs, 30 Paras, 6,236 Ayahs"),
    ],
    "ghazwaat": [
        ("after", "Fatah Makkah", f"{H_}/ghazwa-makkah.jpg",
         "Map — Makkah"),
        ("after", "Taif ka muhasra", f"{H_}/ghazwa-taif.jpg",
         "Map — Taif, south-east of Makkah"),
        ("after", "Ghazwa-e-Tabuk", f"{H_}/ghazwa-tabuk.jpg",
         "Map — Tabuk, the last expedition"),
    ],
    "seerat": [
        ("after", "Paidaish aur khandan", f"{H_}/ghazwa-makkah.jpg",
         "Map — Makkah, the birthplace"),
        ("after", "Taif ka safar", f"{H_}/ghazwa-taif.jpg",
         "Map — Taif"),
    ],
    "sultanate": [
        ("after", "Pehle poori tasveer dekh lo",
         f"{H_}/sultanate-timeline.jpg",
         "Delhi Sultanate — Five Dynasties, 1206 to 1526"),
    ],
    "mughal": [
        ("after", "Pehle poori tasveer dekh lo",
         f"{H_}/mughal-timeline.jpg",
         "The Mughals — Babur to Bahadur Shah Zafar"),
    ],
    "wars-1947-2026": [
        ("after", "Aakhir me saal-war tartib", f"{H_}/wars-timeline.jpg",
         "Wars Timeline — 1947 to Kargil 1999"),
    ],
    "geometry": [
        ("end", "Area, andar ki jagah", f"{E_}/perimeter-area.jpg",
         "Perimeter versus Area — fence or floor"),
        ("end", "Triangle ke teen konay aur 180 wala raaz",
         f"{E_}/triangle-circle.jpg",
         "Triangle and Circle — the cut-corner trick and pi"),
    ],
}

# Image as the FIRST block of a reading topic.
TOPIC_LEAD = {
    "provinces": (f"{V_}/pakistan-overview.jpg",
                  "Pakistan at a Glance — provinces and key facts"),
    "world-terms": (f"{V_}/oceans-seas.jpg",
                    "Oceans and Seas — the water words of the map"),
    "treaties": (f"{V_}/treaties.jpg", "Pakistan's Treaties at a Glance"),
    "solar-system": (f"{V_}/planets.jpg", "The Solar System at a Glance"),
}

# Image as the FIRST block of an English lesson (grammar charts).
LESSON_LEAD = {
    "grammar-25": (f"{V_}/parts-of-speech.jpg",
                   "Parts of Speech — the whole family"),
    "grammar-31": (f"{V_}/tenses-timeline.jpg",
                   "All 12 Tenses on One Timeline"),
    "grammar-47": (f"{V_}/punctuation.jpg",
                   "Punctuation — every mark and its job"),
    "grammar-28": (f"{V_}/sentence-types.jpg", "Sentence Types at a Glance"),
    "grammar-30": (f"{V_}/active-passive.jpg",
                   "Active to Passive — the swap"),
    "grammar-29": (f"{V_}/direct-indirect.jpg",
                   "Direct to Indirect — the three changes"),
}

# Image heading the FIRST feature parsed from a geography/world
# feature doc (those docs render as map-feature collections, so the
# overview page heads the doc's lead entry).
FEATURE_LEAD = {
    "rivers": (f"{V_}/pakistan-rivers.jpg", "The Indus River System"),
    "dams-barrages": (f"{G_}/geo-dams.jpg",
                      "Dams and Barrages — north to south"),
    "doabs": (f"{V_}/pakistan-doabs.jpg", "The Five Doabs of Punjab"),
    "passes": (f"{G_}/geo-passes.jpg", "The Northern Passes"),
    "mountains": (f"{V_}/pakistan-mountains.jpg",
                  "Ranges and Peaks of the North"),
    "borders": (f"{G_}/borders.jpg",
                "Pakistan's Borders and Their Lengths"),
    "heritage": (f"{G_}/geo-heritage.jpg", "Heritage Sites on the Map"),
    "coast-ports": (f"{G_}/geo-coast.jpg", "Coast and Ports — west to east"),
    "lakes": (f"{G_}/geo-lakes.jpg", "Lakes of Pakistan — north to south"),
    "world-features": (f"{V_}/continents.jpg", "The Seven Continents"),
}


def insert_section_images(blocks, rules, owner):
    """Apply SECTION_INSERTS-style rules to a block list. 'after'
    inserts right behind the section's heading block; 'end' inserts
    just before the next heading (the section's last position)."""
    for kind, prefix, asset, caption in rules:
        hidx = None
        for i, b in enumerate(blocks):
            if b["type"] == "heading" and b["text"].startswith(prefix):
                hidx = i
                break
        if hidx is None:
            problems.append(
                f"{owner}: insert heading '{prefix}' not found "
                f"for {asset}"
            )
            continue
        if kind == "after":
            pos = hidx + 1
        else:
            pos = len(blocks)
            for j in range(hidx + 1, len(blocks)):
                if blocks[j]["type"] == "heading":
                    pos = j
                    break
        blocks.insert(pos, _img(asset, caption))
        wire_counts["inserted"] += 1
    return blocks


def wire_topic(topic, tasveer):
    """v2.0 wiring for one parsed topic: replace visual blocks with
    mapped images (card mode), apply section inserts, and put the
    topic-leading visual page first."""
    stem = topic["id"]
    blocks = topic["blocks"]
    if tasveer == "card":
        out = []
        heading = ""
        seen = {}
        for b in blocks:
            if b["type"] == "heading":
                heading = b["text"]
                out.append(b)
                continue
            if b["type"] != "visual":
                out.append(b)
                continue
            occ = seen.get(heading, 0)
            seen[heading] = occ + 1
            imgs = VISUAL_MAP_OCC.get((stem, heading, occ))
            if imgs is None:
                imgs = VISUAL_MAP.get(stem, {}).get(heading)
            if not imgs:
                visual_unmapped.append(
                    f"{stem} under <{heading}>: {b['text'][:80]}"
                )
                problems.append(
                    f"{stem}: visual block under <{heading}> has no "
                    f"mapped diagram"
                )
                out.append(b)
                continue
            for asset, caption in imgs:
                out.append(_img(asset, caption))
            wire_counts["visual_replaced"] += 1
            visuals_by_stem[stem] = visuals_by_stem.get(stem, 0) + 1
        blocks = out
    if stem in SECTION_INSERTS:
        blocks = insert_section_images(
            blocks, SECTION_INSERTS[stem], f"topic/{stem}"
        )
    if stem in TOPIC_LEAD:
        asset, caption = TOPIC_LEAD[stem]
        blocks.insert(0, _img(asset, caption))
        wire_counts["lead"] += 1
    topic["blocks"] = blocks
    return topic


# ---------------------------------------------------------------------------
# Lessons
# ---------------------------------------------------------------------------

def find_line(lines, exact):
    for i, ln in enumerate(lines):
        if ln.strip() == exact:
            return i
    return -1


def parse_mcqs(blocks):
    qs = []
    for b in blocks:
        lines = [l.strip() for l in b]
        if not lines or not NUM_RE.match(lines[0]):
            continue
        qtext = NUM_RE.match(lines[0]).group(2).strip()
        opts, cur = [], None
        for ln in lines[1:]:
            m = OPT_RE.match(ln)
            if m:
                if cur is not None:
                    opts.append(cur)
                cur = m.group(2).strip()
            elif cur is None:
                qtext = (qtext + " " + ln).strip()
            else:
                cur = (cur + " " + ln).strip()
        if cur is not None:
            opts.append(cur)
        qs.append({"question": qtext, "options": opts})
    return qs


def parse_key(lines):
    """Answer key, parsed line by line: '1. Jawab B hai, ... wajah ...'"""
    key = {}
    cur_num = None
    for raw in lines:
        ln = raw.strip()
        m = KEY_RE.match(ln)
        if m:
            cur_num = int(m.group(1))
            letter = m.group(2)
            rest = m.group(3).strip()
            # Negation guard: a line like '8. Jawab A nahi, jawab B hai'
            # REJECTS its first letter; the real answer follows the LAST
            # 'jawab' in the line. Without this, the rejected letter wins.
            jawabs = list(re.finditer(r"[Jj]awab\s+([A-D])\b", ln))
            if len(jawabs) > 1 and "nahi" in ln[
                jawabs[0].end() : jawabs[-1].start()
            ]:
                letter = jawabs[-1].group(1)
                rest = ln[jawabs[-1].end() :].strip()
            expl = re.sub(r"^hai\b[.,]?\s*", "", rest).strip()
            if expl:
                expl = expl[0].upper() + expl[1:]
            key[cur_num] = (ord(letter) - 65, expl)
        elif ln and cur_num is not None and cur_num in key:
            idx, expl = key[cur_num]
            key[cur_num] = (idx, (expl + " " + ln).strip())
    return key


def parse_lesson(path):
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    lid = path.stem  # grammar-NN
    m = TITLE_RE.match(lines[0].strip())
    if not m:
        problems.append(f"{lid}: title line not recognised: {lines[0]!r}")
        return None
    number = int(m.group(1))
    title = m.group(2).strip()
    subtitle = lines[1].strip() if len(lines) > 1 else ""

    i_practice = find_line(lines, "Practice sawal")
    i_key = find_line(lines, "Jawab aur un ki wajah")
    i_pic = find_line(lines, "Aakhir me tasveer ke do khayal")
    if i_practice < 0 or i_key < 0 or i_pic < 0:
        problems.append(
            f"{lid}: section markers missing "
            f"(practice={i_practice}, key={i_key}, tasveer={i_pic})"
        )
        return None

    blocks = body_blocks(split_blocks(lines[2:i_practice]))
    mcqs = parse_mcqs(split_blocks(lines[i_practice + 1 : i_key]))
    key = parse_key(lines[i_key + 1 : i_pic])

    if len(mcqs) != 10:
        problems.append(f"{lid}: MCQ count is {len(mcqs)}, expected 10")
    for i, q in enumerate(mcqs, start=1):
        if len(q["options"]) != 4:
            problems.append(
                f"{lid}: Q{i} has {len(q['options'])} options, expected 4"
            )
        if i not in key:
            problems.append(f"{lid}: answer key missing Q{i}")
            q["correctIndex"] = 0
            q["explanation"] = ""
        else:
            q["correctIndex"], q["explanation"] = key[i]
    for n in key:
        if n < 1 or n > len(mcqs):
            problems.append(f"{lid}: answer key has stray Q{n}")

    if number not in LESSON_PART:
        problems.append(f"{lid}: lesson {number} has no part in the mapping")
        part_index, part_name = 0, ""
    else:
        part_index, part_name = LESSON_PART[number]

    if lid in LESSON_LEAD:
        asset, caption = LESSON_LEAD[lid]
        blocks.insert(0, _img(asset, caption))
        wire_counts["lead"] += 1

    return {
        "id": lid,
        "number": number,
        "title": title,
        "subtitle": subtitle,
        "partIndex": part_index,
        "partName": part_name,
        "blocks": blocks,
        "mcqs": mcqs,
    }


# ---------------------------------------------------------------------------
# Geography
# ---------------------------------------------------------------------------

def parse_features(path, category, section_categories=None, category_fn=None):
    text = path.read_text(encoding="utf-8")
    blocks = split_blocks(text.split("\n"))
    features, buffer = [], []
    stem = path.stem
    current_section_category = None
    for raw_block in blocks:
        if (
            section_categories
            and len(raw_block) == 1
            and block_text(raw_block) in section_categories
        ):
            current_section_category = section_categories[
                block_text(raw_block)
            ]
        # A Pin line may share its block with the entry's last paragraph
        # (no blank line before it). Split it out at line level.
        pin_match = None
        before, after = [], []
        for ln in raw_block:
            if pin_match is None and PIN_RE.match(ln.strip()):
                pin_match = PIN_RE.match(ln.strip())
            elif pin_match is None:
                before.append(ln)
            else:
                after.append(ln)
        if before:
            buffer.append(before)
        if pin_match is not None:
            m = pin_match
            lat, lon = float(m.group(1)), float(m.group(2))
            hidx = None
            for i, bb in enumerate(buffer):
                if len(bb) == 1 and is_feature_heading(block_text(bb)):
                    hidx = i
            if hidx is None:
                problems.append(
                    f"{stem}: pin at {lat},{lon} has no heading before it"
                )
                buffer = [after] if after else []
                continue
            name = block_text(buffer[hidx])
            raw_body = buffer[hidx + 1 :]
            for bb in raw_body:
                if len(bb) == 1 and is_heading(block_text(bb)):
                    problems.append(
                        f"{stem}: feature '{name}' body contains a "
                        f"heading-like line: {block_text(bb)!r}"
                    )
            feat_category = category
            if section_categories:
                if current_section_category is None:
                    problems.append(
                        f"{stem}: feature '{name}' has no section category"
                    )
                    feat_category = category
                else:
                    feat_category = current_section_category
            if category_fn:
                feat_category = category_fn(name)
            features.append(
                {
                    "id": f"{stem}-{len(features) + 1:02d}",
                    "name": name,
                    "category": feat_category,
                    "lat": lat,
                    "lon": lon,
                    "blocks": body_blocks(raw_body),
                }
            )
            buffer = [after] if after else []
    # Closing recap: content after the final feature's Pin (a summary
    # heading plus paragraphs/lists, e.g. the dams north-to-south order
    # line or the borders length trick) belongs to the LAST feature's
    # body, so students actually see it instead of it being dropped.
    if features and any(block_text(b).strip() for b in buffer):
        features[-1]["blocks"].extend(body_blocks(buffer))
    return features


def parse_topic(path, portion="pakistan", tasveer="keep"):
    text = path.read_text(encoding="utf-8")
    blocks = split_blocks(text.split("\n"))
    if not blocks:
        problems.append(f"{path.stem}: empty topic file")
        return None
    first = blocks[0]
    title = first[0].strip()
    subtitle = first[1].strip() if len(first) > 1 else ""
    # Strip Pin lines wherever they appear (own block or inline).
    rest = []
    for b in blocks[1:]:
        kept = [ln for ln in b if not PIN_RE.match(ln.strip())]
        if kept:
            rest.append(kept)
    topic = {
        "id": path.stem,
        "title": title,
        "subtitle": subtitle,
        "portion": portion,
        "blocks": body_blocks(rest, tasveer=tasveer),
    }
    return wire_topic(topic, tasveer)


def leak_check(blocks, owner):
    """No 'Pin:' text may survive into any rendered body."""
    for b in blocks:
        for field in ("text", "note", "wrong", "right"):
            if "Pin:" in b.get(field, ""):
                problems.append(f"{owner}: 'Pin:' leaked into a body block")
                return


# ---------------------------------------------------------------------------
# Dart emission
# ---------------------------------------------------------------------------

def ds(s):
    """Dart string literal for arbitrary text (JSON escaping + $ guard)."""
    return json.dumps(s, ensure_ascii=False).replace("$", "\\$")


def emit_block(b):
    t = b["type"]
    if t == "heading":
        return f"LessonBlock.heading({ds(b['text'])})"
    if t == "example":
        if b.get("note"):
            return (
                f"LessonBlock.example({ds(b['text'])}, "
                f"note: {ds(b['note'])})"
            )
        return f"LessonBlock.example({ds(b['text'])})"
    if t == "rule":
        return f"LessonBlock.rule({ds(b['text'])})"
    if t == "visual":
        return f"LessonBlock.visual({ds(b['text'])})"
    if t == "image":
        if b.get("note"):
            return (
                f"LessonBlock.image({ds(b['text'])}, "
                f"caption: {ds(b['note'])})"
            )
        return f"LessonBlock.image({ds(b['text'])})"
    if t == "trap":
        return (
            f"LessonBlock.trap({ds(b['wrong'])}, {ds(b['right'])}, "
            f"{ds(b['note'])})"
        )
    return f"LessonBlock.paragraph({ds(b['text'])})"


def emit_blocks(blocks, indent):
    pad = " " * indent
    inner = ",\n".join(pad + "  " + emit_block(b) for b in blocks)
    return f"<LessonBlock>[\n{inner},\n{pad}]"


def emit_lesson(les):
    mcqs = ",\n        ".join(
        "LessonMcq(\n"
        f"          question: {ds(q['question'])},\n"
        f"          options: <String>[{', '.join(ds(o) for o in q['options'])}],\n"
        f"          correctIndex: {q['correctIndex']},\n"
        f"          explanation: {ds(q['explanation'])},\n"
        "        )"
        for q in les["mcqs"]
    )
    portion_line = ""
    if les.get("portion") not in (None, "english"):
        portion_line = f"    portion: {ds(les['portion'])},\n"
    return (
        "  Lesson(\n"
        f"    id: {ds(les['id'])},\n"
        f"    number: {les['number']},\n"
        f"    title: {ds(les['title'])},\n"
        f"    subtitle: {ds(les['subtitle'])},\n"
        f"    partIndex: {les['partIndex']},\n"
        f"    partName: {ds(les['partName'])},\n"
        f"{portion_line}"
        f"    blocks: {emit_blocks(les['blocks'], 4)},\n"
        f"    mcqs: <LessonMcq>[\n        {mcqs},\n      ],\n"
        "  )"
    )


def emit_topic(t):
    portion_line = ""
    if t.get("portion") not in (None, "pakistan"):
        portion_line = f"    portion: {ds(t['portion'])},\n"
    return (
        "  GeoTopic(\n"
        f"    id: {ds(t['id'])},\n"
        f"    title: {ds(t['title'])},\n"
        f"    subtitle: {ds(t['subtitle'])},\n"
        f"{portion_line}"
        f"    blocks: {emit_blocks(t['blocks'], 4)},\n"
        "  )"
    )


def emit_world_feature(f):
    return (
        "  WorldFeature(\n"
        f"    id: {ds(f['id'])},\n"
        f"    name: {ds(f['name'])},\n"
        f"    category: {ds(f['category'])},\n"
        f"    lat: {f['lat']},\n"
        f"    lon: {f['lon']},\n"
        f"    imageAsset: {ds(feature_asset('world', f['id']))},\n"
        f"    blocks: {emit_blocks(f['blocks'], 4)},\n"
        "  )"
    )


def insert_country_images(topic):
    """v1.5: an image block with the country's map snapshot goes at
    the start of each country's section in the countries topic,
    right after its heading. Every COUNTRY_SNAPSHOTS heading must be
    found, otherwise the miss is reported as a problem."""
    out = []
    found = set()
    for b in topic["blocks"]:
        out.append(b)
        if b["type"] == "heading" and b["text"] in COUNTRY_SNAPSHOTS:
            found.add(b["text"])
            out.append(
                {
                    "type": "image",
                    "text": country_asset(b["text"]),
                    "note": (
                        f"Naqsha — {b['text']} aur us ke aas paas "
                        f"ke mulk"
                    ),
                }
            )
    for name in sorted(set(COUNTRY_SNAPSHOTS) - found):
        problems.append(
            f"countries: heading '{name}' not found for its map image"
        )
    topic["blocks"] = out
    return len(found)


def insert_ocean_images(topic):
    """v1.5: the five ocean snapshots go together, in ocean order,
    inside the world-terms topic's 'Ocean aur Sea ka farq' section,
    right after its heading — the oceans are explained there (the
    world-features prose sections never reach a topic: that file
    parses into map features only)."""
    out = []
    done = False
    for b in topic["blocks"]:
        out.append(b)
        if (
            not done
            and b["type"] == "heading"
            and b["text"] == "Ocean aur Sea ka farq"
        ):
            for slug, name, _lat, _lon, _zoom in OCEAN_SNAPSHOTS:
                out.append(
                    {
                        "type": "image",
                        "text": ocean_asset(slug),
                        "note": (
                            f"Naqsha — {name} aur us ke aas paas "
                            f"ke continents"
                        ),
                    }
                )
            done = True
    if not done:
        problems.append(
            "world-terms: 'Ocean aur Sea ka farq' section not found "
            "for the ocean images"
        )
    topic["blocks"] = out
    return done


def emit_planet(p):
    return (
        "  PlanetSection(\n"
        f"    id: {ds(p['id'])},\n"
        f"    name: {ds(p['name'])},\n"
        f"    urduName: {ds(p['urduName'])},\n"
        f"    blocks: {emit_blocks(p['blocks'], 4)},\n"
        "  )"
    )


HEADER = (
    "// GENERATED by tools/generate_learning_data.py — do not edit by hand.\n"
    "// Source masters: docs/lessons/ and docs/geography/.\n"
    "import '../models/learning_models.dart';\n"
)


def write_file(name, content):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / name).write_text(content, encoding="utf-8")
    print(f"wrote lib/learning/data/{name} ({len(content)} bytes)")


def gen_lessons():
    lessons = []
    for n in range(1, 50):
        path = LESSONS_DIR / f"grammar-{n:02d}.md"
        if not path.exists():
            problems.append(f"grammar-{n:02d}.md: file missing")
            continue
        les = parse_lesson(path)
        if les:
            leak_check(les["blocks"], les["id"])
            lessons.append(les)
            flag = "" if len(les["mcqs"]) == 10 else "  <-- CHECK"
            print(
                f"{les['id']}: MCQs={len(les['mcqs'])}, "
                f"blocks={len(les['blocks'])}, part={les['partName']}{flag}"
            )
    if len(lessons) != 49:
        problems.append(
            f"lessons: {len(lessons)} English lessons parsed, expected 49"
        )
    groups = [
        ("english_lessons_a.dart", "englishLessonsA", lessons[0:24]),
        ("english_lessons_b.dart", "englishLessonsB", lessons[24:40]),
        ("english_lessons_c.dart", "englishLessonsC", lessons[40:49]),
    ]
    for fname, var, group in groups:
        body = ",\n".join(emit_lesson(l) for l in group)
        write_file(
            fname,
            HEADER
            + f"\nconst List<Lesson> {var} = <Lesson>[\n{body},\n];\n",
        )
    counts = [len(l["mcqs"]) for l in lessons]
    print(
        f"LESSONS: {len(lessons)} parsed, MCQ min={min(counts)}, "
        f"max={max(counts)}"
    )
    return lessons


def gen_geography():
    all_features = []
    for fname, category in FEATURE_FILES:
        path = GEO_DIR / fname
        if not path.exists():
            problems.append(f"geography/{fname}: file missing")
            continue
        feats = parse_features(path, category)
        if path.stem in FEATURE_LEAD and feats:
            asset, caption = FEATURE_LEAD[path.stem]
            feats[0]["blocks"].insert(0, _img(asset, caption))
            wire_counts["lead"] += 1
        all_features.extend(feats)
        print(f"{fname}: {len(feats)} features ({category})")
    topics = []
    for fname in TOPIC_FILES:
        path = GEO_DIR / fname
        if not path.exists():
            problems.append(f"geography/{fname}: file missing")
            continue
        topic = parse_topic(path)
        if topic:
            topics.append(topic)
            print(f"{fname}: topic '{topic['title']}' ({len(topic['blocks'])} blocks)")
    # Pak Studies reading topics join the SAME Pakistan portion, after
    # the geography topics (owner's order: one Pakistan portion).
    for fname in PAKSTUDY_FILES:
        path = ROOT / "docs" / "pakstudy" / fname
        if not path.exists():
            problems.append(f"pakstudy/{fname}: file missing")
            continue
        topic = parse_topic(path, portion="pakistan")
        if topic:
            topics.append(topic)
            print(
                f"pakstudy/{fname}: topic '{topic['title']}' "
                f"({len(topic['blocks'])} blocks)"
            )
    for f in all_features:
        leak_check(f["blocks"], f"geography/{f['id']}")
    for t in topics:
        leak_check(t["blocks"], f"topic/{t['id']}")

    for f in all_features:
        require_map_image(feature_asset("pakistan", f["id"]))
    feat_src = ",\n".join(
        "  MapFeature(\n"
        f"    id: {ds(f['id'])},\n"
        f"    name: {ds(f['name'])},\n"
        f"    category: {ds(f['category'])},\n"
        f"    lat: {f['lat']},\n"
        f"    lon: {f['lon']},\n"
        f"    imageAsset: {ds(feature_asset('pakistan', f['id']))},\n"
        f"    blocks: {emit_blocks(f['blocks'], 4)},\n"
        "  )"
        for f in all_features
    )
    topic_src = ",\n".join(emit_topic(t) for t in topics)
    write_file(
        "geography_data.dart",
        HEADER
        + f"\nconst List<MapFeature> mapFeatures = <MapFeature>[\n{feat_src},\n];\n"
        + f"\nconst List<GeoTopic> geoTopics = <GeoTopic>[\n{topic_src},\n];\n",
    )
    print(f"GEOGRAPHY: {len(all_features)} map features, {len(topics)} topics")
    return all_features


def gen_world():
    world_dir = ROOT / "docs" / "world"
    features = []
    path = world_dir / "world-features.md"
    if not path.exists():
        problems.append("world/world-features.md: file missing")
    else:
        feats = parse_features(
            path, "Duniya", section_categories=WORLD_SECTION_CATEGORIES
        )
        if "world-features" in FEATURE_LEAD and feats:
            asset, caption = FEATURE_LEAD["world-features"]
            feats[0]["blocks"].insert(0, _img(asset, caption))
            wire_counts["lead"] += 1
        features.extend(feats)
        print(f"world-features.md: {len(feats)} features (sections)")
    path = world_dir / "gulfs-straits.md"
    if not path.exists():
        problems.append("world/gulfs-straits.md: file missing")
    else:
        feats = parse_features(path, "Gulfs & Straits",
                               category_fn=gulfs_category)
        features.extend(feats)
        print(f"gulfs-straits.md: {len(feats)} features (name categories)")
    topics = []
    for stem in ("countries", "world-terms"):
        path = world_dir / f"{stem}.md"
        if not path.exists():
            problems.append(f"world/{stem}.md: file missing")
            continue
        topic = parse_topic(path, portion="world")
        if topic:
            if stem == "countries":
                n = insert_country_images(topic)
                print(f"world/countries.md: {n} country map images inserted")
            if stem == "world-terms":
                insert_ocean_images(topic)
                print("world/world-terms.md: 5 ocean map images inserted")
            topics.append(topic)
            print(
                f"world/{stem}.md: topic '{topic['title']}' "
                f"({len(topic['blocks'])} blocks)"
            )
    for f in features:
        leak_check(f["blocks"], f"world/{f['id']}")
    for t in topics:
        leak_check(t["blocks"], f"world/{t['id']}")
    if len(features) != 39:
        problems.append(
            f"world: {len(features)} map features parsed, expected 39"
        )
    for f in features:
        require_map_image(feature_asset("world", f["id"]))
    for slug, _name, _lat, _lon, _zoom in OCEAN_SNAPSHOTS:
        require_map_image(ocean_asset(slug))
    for name in COUNTRY_SNAPSHOTS:
        require_map_image(country_asset(name))
    feat_src = ",\n".join(emit_world_feature(f) for f in features)
    topic_src = ",\n".join(emit_topic(t) for t in topics)
    write_file(
        "world_data.dart",
        HEADER
        + f"\nconst List<WorldFeature> worldFeatures = <WorldFeature>[\n{feat_src},\n];\n"
        + f"\nconst List<GeoTopic> worldTopics = <GeoTopic>[\n{topic_src},\n];\n",
    )
    print(f"WORLD: {len(features)} map features, {len(topics)} topics")
    return features


def parse_planets(path):
    """Split solar-system.md into Sun + planet sections by heading."""
    text = path.read_text(encoding="utf-8")
    blocks = split_blocks(text.split("\n"))
    sections = []  # (heading, [raw blocks])
    cur = None
    for b in blocks:
        if len(b) == 1 and is_heading(block_text(b)):
            cur = (block_text(b), [])
            sections.append(cur)
        elif cur is not None:
            cur[1].append(b)
    planets = []
    for pid, needle in PLANETS:
        for heading, sec_blocks in sections:
            if pid == "sun":
                matched = heading.startswith(needle)
            else:
                matched = needle in heading
            if not matched:
                continue
            if pid == "sun":
                name, urdu = "Sun", "Suraj"
            else:
                tail = heading.split(":", 1)[1].strip()
                if "—" in tail:
                    name, urdu = (s.strip() for s in tail.split("—", 1))
                else:
                    name, urdu = tail, ""
            planets.append(
                {
                    "id": pid,
                    "name": name,
                    "urduName": urdu,
                    "blocks": body_blocks(sec_blocks),
                }
            )
            break
        else:
            problems.append(f"solar-system: section for '{pid}' not found")
    return planets


def gen_topics():
    """Generic reading-topic portions (space handled here too, plus
    its planet sections appended into space_data.dart)."""
    planets = []
    for portion, subdir, stems, tasveer, out_file, var in TOPIC_PORTIONS:
        topics = []
        for stem in stems:
            path = ROOT / "docs" / subdir / f"{stem}.md"
            if not path.exists():
                problems.append(f"{subdir}/{stem}.md: file missing")
                continue
            topic = parse_topic(path, portion=portion, tasveer=tasveer)
            if topic:
                topics.append(topic)
                visuals = sum(
                    1 for b in topic["blocks"] if b["type"] == "visual"
                )
                print(
                    f"{subdir}/{stem}.md: topic '{topic['title']}' "
                    f"({len(topic['blocks'])} blocks, {visuals} visual)"
                )
        for t in topics:
            leak_check(t["blocks"], f"{portion}/{t['id']}")
        topic_src = ",\n".join(emit_topic(t) for t in topics)
        content = (
            HEADER
            + f"\nconst List<GeoTopic> {var} = <GeoTopic>[\n{topic_src},\n];\n"
        )
        if portion == "space":
            planets = parse_planets(ROOT / "docs" / "space" / "solar-system.md")
            for p in planets:
                leak_check(p["blocks"], f"planet/{p['id']}")
                print(
                    f"planet {p['id']}: {len(p['blocks'])} blocks"
                )
            planet_src = ",\n".join(emit_planet(p) for p in planets)
            content += (
                f"\nconst List<PlanetSection> planetSections = "
                f"<PlanetSection>[\n{planet_src},\n];\n"
            )
        write_file(out_file, content)
        print(f"{portion.upper()}: {len(topics)} topics")
    return planets


def parse_maths_lesson(path, number):
    """Maths lessons follow the grammar template but carry a plain
    title line (no 'Lesson N:' prefix) and no part mapping."""
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    lid = path.stem
    title = lines[0].strip()
    subtitle = lines[1].strip() if len(lines) > 1 else ""

    i_practice = find_line(lines, "Practice sawal")
    i_key = find_line(lines, "Jawab aur un ki wajah")
    i_pic = find_line(lines, "Aakhir me tasveer ke do khayal")
    if i_practice < 0 or i_key < 0 or i_pic < 0:
        problems.append(
            f"{lid}: section markers missing "
            f"(practice={i_practice}, key={i_key}, tasveer={i_pic})"
        )
        return None

    blocks = body_blocks(split_blocks(lines[2:i_practice]))
    mcqs = parse_mcqs(split_blocks(lines[i_practice + 1 : i_key]))
    key = parse_key(lines[i_key + 1 : i_pic])

    if len(mcqs) != 10:
        problems.append(f"{lid}: MCQ count is {len(mcqs)}, expected 10")
    for i, q in enumerate(mcqs, start=1):
        if len(q["options"]) != 4:
            problems.append(
                f"{lid}: Q{i} has {len(q['options'])} options, expected 4"
            )
        if i not in key:
            problems.append(f"{lid}: answer key missing Q{i}")
            q["correctIndex"] = 0
            q["explanation"] = ""
        else:
            q["correctIndex"], q["explanation"] = key[i]
    for n in key:
        if n < 1 or n > len(mcqs):
            problems.append(f"{lid}: answer key has stray Q{n}")
    leak_check(blocks, f"maths/{lid}")

    if lid in SECTION_INSERTS:
        blocks = insert_section_images(
            blocks, SECTION_INSERTS[lid], f"maths/{lid}"
        )

    return {
        "id": lid,
        "number": number,
        "title": title,
        "subtitle": subtitle,
        "partIndex": 0,
        "partName": "Maths",
        "portion": "maths",
        "blocks": blocks,
        "mcqs": mcqs,
    }


def gen_maths():
    lessons = []
    for i, stem in enumerate(MATHS_ORDER, start=1):
        path = ROOT / "docs" / "maths" / f"{stem}.md"
        if not path.exists():
            problems.append(f"maths/{stem}.md: file missing")
            continue
        les = parse_maths_lesson(path, i)
        if les:
            lessons.append(les)
            flag = "" if len(les["mcqs"]) == 10 else "  <-- CHECK"
            print(
                f"maths/{les['id']}: MCQs={len(les['mcqs'])}, "
                f"blocks={len(les['blocks'])}{flag}"
            )
    body = ",\n".join(emit_lesson(l) for l in lessons)
    write_file(
        "maths_lessons.dart",
        HEADER
        + f"\nconst List<Lesson> mathsLessons = <Lesson>[\n{body},\n];\n",
    )
    counts = [len(l["mcqs"]) for l in lessons]
    if counts:
        print(
            f"MATHS: {len(lessons)} lessons, MCQ min={min(counts)}, "
            f"max={max(counts)}"
        )
    return lessons


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    if mode in ("lessons", "all"):
        gen_lessons()
    if mode in ("geography", "all"):
        gen_geography()
    if mode in ("world", "all"):
        gen_world()
    if mode in ("topics", "all"):
        gen_topics()
    if mode in ("maths", "all"):
        gen_maths()
    if problems:
        print("\nPROBLEMS:")
        for p in problems:
            print(" -", p)
    else:
        print("\nNo parse problems.")
    print(
        f"\nWIRING: {wire_counts['visual_replaced']} visual blocks "
        f"replaced by images, {wire_counts['inserted']} section "
        f"inserts, {wire_counts['lead']} leading images"
    )
    if visuals_by_stem:
        print("Visual blocks wired per doc:")
        for stem in sorted(visuals_by_stem):
            print(f" - {stem}: {visuals_by_stem[stem]}")
    if map_image_missing:
        print(
            f"\nFATAL: {len(map_image_missing)} map snapshot(s) missing — "
            "refusing to ship dangling image paths."
        )
        return 1
    if diagram_missing:
        print(
            f"\nFATAL: {len(diagram_missing)} diagram image(s) missing — "
            "refusing to ship dangling image paths."
        )
        return 1
    if visual_unmapped:
        print(
            f"\nFATAL: {len(visual_unmapped)} visual block(s) have no "
            "mapped diagram — the owner banned text Visual Guide boxes:"
        )
        for u in visual_unmapped:
            print(" -", u)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

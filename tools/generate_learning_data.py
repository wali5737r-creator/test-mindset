#!/usr/bin/env python3
"""Generate Dart learning data for Test Mindset's Learning Mode.

Converts the markdown masters in docs/ into const Dart data files under
lib/learning/data/:

  docs/lessons/grammar-NN.md   -> english_lessons_a/b/c.dart (46 lessons)
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
# English parts (owner's mapping, 2026-11-27). Every lesson 1..46 in exactly
# one part; lesson numbers keep course order inside each part.
# ---------------------------------------------------------------------------
PARTS = [
    ("Buniyad — Shuruaat", [1, 2, 3, 4, 6, 7]),
    ("Noun aur Pronoun — Gehraai", [13, 14, 26]),
    ("Adjective, Adverb aur Degree", [8, 17, 27]),
    ("Verb aur Tenses", [9, 18, 19, 20, 31]),
    ("Jumlay — Sawal, Nafi, Hukam", [10, 11, 12, 28]),
    ("Chhote Alfaaz — Prepositions aur Usage", [5, 16, 21, 34]),
    ("Helping Verbs aur Modals", [15, 32, 33]),
    ("Voice aur Narration", [24, 29, 30]),
    ("Infinitive, Gerund aur Participle", [22, 23]),
    ("Parts of Speech — Mukammal Jaiza", [25]),
    ("Vocabulary — Idioms, Proverbs, Phrasal Verbs", [35, 36, 37]),
    ("Vocabulary — One Word, Synonyms, Confusing Words", [38, 39, 40]),
    ("Common Mistakes — Ghaltiyan Pakro", [41, 42, 43, 44, 45, 46]),
]
LESSON_PART = {}
for _i, (_name, _nums) in enumerate(PARTS):
    for _n in _nums:
        LESSON_PART[_n] = (_i, _name)

# Geography feature docs -> map category (chip label).
FEATURE_FILES = [
    ("rivers.md", "Darya"),
    ("dams-barrages.md", "Bandh/Barrage"),
    ("doabs.md", "Doab"),
    ("passes.md", "Daray"),
    ("mountains.md", "Pahar"),
    ("deserts-plains.md", "Registran/Maidan"),
    ("borders.md", "Sarhad"),
    ("heritage.md", "Heritage"),
    ("coast-ports.md", "Sahel"),
    ("lakes.md", "Jheelain"),
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
    "Duniya ke mashhoor darya": "Darya",
    "Duniya ke mashhoor registran": "Registran",
    "Duniya ki mashhoor chotiyan aur silsile": "Pahar",
    "Mashhoor canals aur aabnayen, yani straits": "Canal/Aabnaye",
    "Mashhoor jheelain aur neechi jagah": "Jheelain",
    "Mashhoor jazire": "Jazire",
}


def gulfs_category(name):
    """Chip category for a gulfs-straits.md feature, from its name."""
    if "Strait" in name or "Channel" in name:
        return "Aabnaye"
    if "Gulf" in name:
        return "Khaleej"
    if "Bay" in name:
        return "Bay"
    if "Sea" in name:
        return "Samandar"
    return "Aabnaye"  # Bab el-Mandeb, Dardanelles/Bosphorus


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
                if len(bb) == 1 and is_heading(block_text(bb)):
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
    return {
        "id": path.stem,
        "title": title,
        "subtitle": subtitle,
        "portion": portion,
        "blocks": body_blocks(rest, tasveer=tasveer),
    }


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
        f"    blocks: {emit_blocks(f['blocks'], 4)},\n"
        "  )"
    )


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
    for n in range(1, 47):
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
    groups = [
        ("english_lessons_a.dart", "englishLessonsA", lessons[0:24]),
        ("english_lessons_b.dart", "englishLessonsB", lessons[24:40]),
        ("english_lessons_c.dart", "englishLessonsC", lessons[40:46]),
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

    feat_src = ",\n".join(
        "  MapFeature(\n"
        f"    id: {ds(f['id'])},\n"
        f"    name: {ds(f['name'])},\n"
        f"    category: {ds(f['category'])},\n"
        f"    lat: {f['lat']},\n"
        f"    lon: {f['lon']},\n"
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
        features.extend(feats)
        print(f"world-features.md: {len(feats)} features (sections)")
    path = world_dir / "gulfs-straits.md"
    if not path.exists():
        problems.append("world/gulfs-straits.md: file missing")
    else:
        feats = parse_features(path, "Khaleej/Aabnaye",
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
    return 0


if __name__ == "__main__":
    sys.exit(main())

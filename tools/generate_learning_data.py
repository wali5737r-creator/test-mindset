#!/usr/bin/env python3
"""Generate Dart learning data for Test Mindset's Learning Mode.

Converts the markdown masters in docs/ into const Dart data files under
lib/learning/data/:

  docs/lessons/grammar-NN.md   -> english_lessons_a/b/c.dart (46 lessons)
  docs/geography/<feature>.md  -> geography_data.dart (MapFeature list)
  docs/geography/terms.md      -> geography_data.dart (GeoTopic list)
  docs/geography/provinces.md  -> geography_data.dart (GeoTopic list)

Usage:
  python3 tools/generate_learning_data.py [lessons|geography|all]

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


def body_blocks(blocks):
    """Classify raw blocks into heading / paragraph / example / rule / trap,
    preserving order and full text."""
    out = []
    in_rule = False
    for b in blocks:
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

def parse_features(path, category):
    text = path.read_text(encoding="utf-8")
    blocks = split_blocks(text.split("\n"))
    features, buffer = [], []
    stem = path.stem
    for raw_block in blocks:
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
            features.append(
                {
                    "id": f"{stem}-{len(features) + 1:02d}",
                    "name": name,
                    "category": category,
                    "lat": lat,
                    "lon": lon,
                    "blocks": body_blocks(raw_body),
                }
            )
            buffer = [after] if after else []
    return features


def parse_topic(path):
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
        "blocks": body_blocks(rest),
    }


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
    return (
        "  Lesson(\n"
        f"    id: {ds(les['id'])},\n"
        f"    number: {les['number']},\n"
        f"    title: {ds(les['title'])},\n"
        f"    subtitle: {ds(les['subtitle'])},\n"
        f"    partIndex: {les['partIndex']},\n"
        f"    partName: {ds(les['partName'])},\n"
        f"    blocks: {emit_blocks(les['blocks'], 4)},\n"
        f"    mcqs: <LessonMcq>[\n        {mcqs},\n      ],\n"
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
    topic_src = ",\n".join(
        "  GeoTopic(\n"
        f"    id: {ds(t['id'])},\n"
        f"    title: {ds(t['title'])},\n"
        f"    subtitle: {ds(t['subtitle'])},\n"
        f"    blocks: {emit_blocks(t['blocks'], 4)},\n"
        "  )"
        for t in topics
    )
    write_file(
        "geography_data.dart",
        HEADER
        + f"\nconst List<MapFeature> mapFeatures = <MapFeature>[\n{feat_src},\n];\n"
        + f"\nconst List<GeoTopic> geoTopics = <GeoTopic>[\n{topic_src},\n];\n",
    )
    print(f"GEOGRAPHY: {len(all_features)} map features, {len(topics)} topics")
    return all_features


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    if mode in ("lessons", "all"):
        gen_lessons()
    if mode in ("geography", "all"):
        gen_geography()
    if problems:
        print("\nPROBLEMS:")
        for p in problems:
            print(" -", p)
    else:
        print("\nNo parse problems.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

# Test Mindset — Build Notes

Notes for whoever builds/maintains this app next (Glint or the owner).
The product contract is `docs/SRS.md`; user-facing setup is in `README.md`.

## Structure map

```
pubspec.yaml                     deps: get, firebase_core/auth/firestore,
                                 file_picker, csv, share_plus, intl
lib/
  main.dart                      Firebase init in try/catch; registers
                                 AuthService, TestService, AuthController
                                 (permanent) when Firebase is ready;
                                 otherwise starts on SetupPendingScreen.
  firebase_options.dart          PLACEHOLDER (isConfigured = false).
  config/app_config.dart         App name (ONE place), Firestore collection
                                 names, code length 6, max questions 200,
                                 webBaseUrl for share links.
  models/
    quiz_test.dart               TestModel + TestStatus enum.
    question.dart                Question (4 options, correctIndex;
                                 -1 = answer not loaded, see v1.1).
    question_answer.dart         QuestionAnswer: the answer half of a
                                 question (answers/{qid}, since v1.1).
    attempt.dart                 Attempt (+ percent getter: raw score
                                 floored at 0 for display only).
  services/
    auth_service.dart            Register/login/logout/reset + Google
                                 sign-in (v1.1.4) + teachers/{uid}
                                 profile doc + friendlyError() messages.
    test_service.dart            All Firestore work: tests CRUD, questions
                                 subcollection, find-by-code, attempts,
                                 attempts count, CSV export string builder.
    code_generator.dart          6-char code, alphabet without 0/O/1/I/L.
  controllers/
    auth_controller.dart         Login/register/reset/logout actions.
    dashboard_controller.dart    My-tests stream + attempts counts + delete.
    test_editor_controller.dart  Settings form state + validation + save.
    question_editor_controller.dart  Question list stream, delete, CSV
                                 import (picker + parser; parser is the
                                 importCsvString method, unit-testable).
    take_test_controller.dart    Student attempt: load once, timer,
                                 palette state, shuffle, scoring, save.
    results_controller.dart      Attempts stream, delete, clear, CSV share.
  routes/
    app_routes.dart              Route name constants only.
    app_pages.dart               GetPage list + per-route Bindings.
    auth_middleware.dart         Redirects signed-out users to /login.
  screens/
    splash_screen.dart           '/' auth gate (dashboard vs home).
    setup_pending_screen.dart    Shown until Firebase is configured.
    home_screen.dart             Landing: code entry + teacher login.
                                 (HomeController lives in this file.)
    login_screen.dart / register_screen.dart / forgot_password_screen.dart
    dashboard_screen.dart        My Tests cards + popup menu actions.
    test_editor_screen.dart      Settings form (status = ChoiceChips,
                                 deliberately not a dropdown - see below).
    question_list_screen.dart    Questions of a test + CSV import button.
    question_editor_screen.dart  Add/edit one MCQ (StatefulWidget, saves
                                 via TestService directly - see below).
    share_screen.dart            Big code, link, copy/share, Publish Now.
    student_intro_screen.dart    /t/:code landing + name/roll form.
                                 (StudentIntroController lives in this file.)
    take_test_screen.dart        One-by-one + scroll-all views, palette
                                 bottom sheet, submit/exit confirm dialogs.
    student_result_screen.dart   Score card + review (QuestionReviewCard).
    teacher_results_screen.dart  Attempts list, export, clear, delete.
    attempt_detail_screen.dart   Per-question review of one attempt.
  widgets/
    loading_button.dart          FilledButton with spinner state.
    google_sign_in_button.dart   White outlined "Continue with Google"
                                 button with spinner state (v1.1.4).
    option_tile.dart             Selectable A/B/C/D option row.
    palette_grid.dart            Numbered answered/unanswered grid.
    question_review_card.dart    Correct/wrong/skipped review card, shared
                                 by student result + teacher attempt detail.
android/                         Minimal Flutter 3.x template skeleton
                                 (applicationId com.muhammad.mindset,
                                 label Test Mindset, INTERNET permission,
                                 MainActivity in the right package,
                                 minSdk 23, release = debug signing).
```

## Design decisions

- **GetX everywhere.** Services and `AuthController` are registered
  permanently in `main.dart`; page controllers are `lazyPut` by the
  per-route Bindings in `app_pages.dart`. Arguments travel via
  `Get.arguments` maps (`{'test': TestModel}` etc.) — every controller
  documents its expected arguments at the top of its file.
- **Student link route is `/t/:code`** (hash URL: `/#/t/AB3K9Z`).
  `main.dart` deliberately does **not** set `initialRoute` when Firebase
  is ready, so the platform route from the browser URL is honoured and
  the deep link lands directly on the intro screen. The plain root
  route `/` is the splash/auth gate.
- **No composite Firestore indexes.** Lists (`myTestsStream`,
  `attemptsStream`, `questionsStream`) fetch with a single filter (or
  none) and sort in Dart. This keeps a brand-new Firebase project
  working with zero console index setup.
- **`questionCount` is denormalized** on the test doc and maintained by
  `TestService.addQuestion/deleteQuestion` with `FieldValue.increment`.
  CSV import goes through `addQuestion`, so the count stays correct.
- **Attempts store `questionIds` in addition to the SRS §6 fields.**
  Without them, the teacher's per-question review would silently break
  if questions were edited/reordered after students submitted. The
  review screens map answers → questions by id and show a "question was
  deleted" card when an id no longer exists.
- **Scoring** (SRS): `score = correct*marksPerQuestion −
  wrong*negativeMarks`, stored raw (may be negative). Display percent =
  `clamp(score, 0, total) / total * 100` — see `Attempt.percent`.
  Skipped = answer `-1`.
- **Timer** is a 1-second `Timer.periodic` in `TakeTestController`;
  at zero it calls the same `submit()` as the button (guarded against
  double-submit). Time used is wall-clock elapsed, sanity-checked
  against the countdown value.
- **Shuffle** shuffles question order only (per SRS "shuffle questions");
  option order inside a question is NOT shuffled in v1.
- **Status picker uses ChoiceChips**, not `DropdownButtonFormField` —
  that widget's `value` parameter was deprecated in newer Flutter in
  favour of `initialValue`; chips avoid the API churn entirely. For the
  same reason the question editor uses custom tappable circles instead
  of `Radio`, and review colours use `Color.withValues(alpha:)` instead
  of the deprecated `withOpacity`.
- **CSV export shares as text** via share_plus (subject + CSV body).
  Saving directly to a `.csv` file would need a file-write/share-files
  flow; text share keeps v1 dependency-light and works with
  Sheets/Excel paste. Candidate v1.1 nicety.
- **CSV import parser** (`QuestionEditorController.importCsvString`)
  is separated from the file picker so it can be unit-tested without
  platform channels. It normalizes line endings, strips a UTF-8 BOM,
  skips the header row and blank rows, accepts correct = A–D or 1–4,
  and enforces the 200-question cap.
- **Release builds are debug-signed** (same as the owner's other apps)
  so CI can produce an installable APK with no keystore secrets.
- **Launcher icon is a generated placeholder** (teal square design,
  all densities). Replace with a designed icon before any public
  release; the manifest label "Test Mindset" must be renamed together with
  `AppConfig.appName` if the app is renamed.

## Known v1 limitation (from SRS §6) — answers ship to the student client

> Status: addressed in v1.1 at the practical level (split collections;
> answers fetched only at submit). See the "v1.1" section below. The
> strict server-side version (step 3 of the fix path) remains future
> work because it needs the paid Blaze plan.

In v1, `TakeTestController` fetched the questions subcollection once at
start, and those documents included `correctIndex`. Scoring therefore
happened on the student's device. Consequences:

- A technical student can inspect the network/storage and see correct
  answers before submitting.
- A modified client could submit a fake high score (attempts are
  client-written by design — students have no login).

This was accepted for v1 to keep the free-tier build simple (no Cloud
Functions on the Spark plan's student path, no extra collections).

### Documented v1.1 fix path

1. Split each question into two docs:
   - `tests/{id}/questions/{qid}` — public: text, options, order
     (NO correctIndex, NO explanation).
   - `tests/{id}/answers/{qid}` — private: correctIndex, explanation;
     Firestore rules: readable only by the test owner.
2. At submit time the student client fetches the answers collection
   ONCE (rules allow read of `answers` only in a way that cannot be
   used before the attempt is written — practically: allow public read
   but only request it at submit; full enforcement needs step 3).
3. Strict version: move scoring into a Cloud Function (Blaze plan) or
   an owner-run callable that receives the answers, scores server-side
   and writes the attempt. This is the only fully tamper-proof option;
   it is out of v1 scope because of the free-only rule.
4. Update rules in README accordingly (answers: owner-only read).

## v1.1 (2026-11-27) — result card, class report, answers split

Version `1.1.0+2`. Three changes; no image-in-questions feature (the
owner explicitly declined it).

### 1. Shareable student result card

`student_result_screen.dart` is now a StatefulWidget. The score card
was redesigned as a plain **result card** (never called a certificate):
app name, "Student Result Card" label, test title, student name (+roll),
big %, score/total, correct/wrong/skipped/time chips, and a footer with
the test code and the submission date. The card sits inside a
`RepaintBoundary`; the **Share result** button renders it to a PNG
(`RenderRepaintBoundary.toImage(pixelRatio: 3)` → `toByteData` PNG) and
shares it with share_plus as `XFile.fromData(...)` — chosen because it
works on Android AND web with no extra dependency (no path_provider /
temp files). If capture or the image share fails, it falls back to
sharing the same result as a text summary.

### 2. Class report (teacher analytics)

`ResultsController` additionally loads the test's questions WITH
answers once (`reportQuestions`) and exposes `totalAttempts`,
`averagePercent` (mean of the attempts' display percents),
`topAttempt` (highest percent, raw score breaks ties) and
`questionStats` — per question, how many attempts answered it correctly
out of how many attempted it (skips don't count as attempts), computed
from the attempts' stored `questionIds`/`answers` pairs.
`teacher_results_screen.dart` shows a "Class Report" card with those
totals plus a per-question breakdown (text, "X of Y correct", progress
bar) above the attempts list. With zero attempts the screen keeps its
existing empty state, so the report never renders empty numbers.

### 3. Security fix — answers split out of the student payload

Implements steps 1+2 of the documented fix path above:

- **Writes** (`TestService.addQuestion` / `updateQuestion` /
  `deleteQuestion`, all batched): each question is now TWO docs —
  `tests/{id}/questions/{qid}` via `Question.toPublicMap()` (text,
  options, order — NO correctIndex, NO explanation) and
  `tests/{id}/answers/{qid}` via `Question.toAnswerMap()`
  (correctIndex, explanation). `updateQuestion` also deletes any answer
  fields still embedded in the question doc, so editing a legacy
  question migrates it to the split layout. `deleteTest` deletes the
  answers collection too.
- **Student flow** (`TakeTestController`): questions are fetched at
  start exactly as before, but for v1.1 tests they contain no answers
  (`Question.fromMap` now yields `correctIndex == -1` when the field is
  absent — never a fake 0). `submit()` FIRST fetches the answers
  collection once (`fetchAnswersOnce`); if that fetch fails it shows an
  error snackbar and does NOT submit (the student keeps their answers
  and can retry; the timer auto-submit also retries on later ticks).
  On success it merges the answers into the questions, scores locally
  as before, writes the complete attempt in ONE write (same fields as
  v1), and passes the merged ("graded") questions to the result screen
  for the review.
- **Teacher flows** read answers from the answers collection through
  `TestService.fetchQuestionsWithAnswersOnce` (attempt detail, class
  report) and `questionsWithAnswersStream` (question list/editor — a
  small two-stream combiner in TestService; the plain `questionsStream`
  still exists and now returns the public payload).
- **Backward compatibility:** v1 tests in Firestore have `correctIndex`
  embedded in the question docs and no answers collection. Everywhere
  answers are merged, a question with no answers doc keeps its own
  embedded `correctIndex`/`explanation`, so old tests keep working end
  to end (student scoring, review, teacher screens). `fetchAnswersOnce`
  on a legacy test simply returns an empty map.

**Honest limitation of this level:** the Firestore rules (README) allow
public read of `answers`, like `questions` — the protection is that the
app only REQUESTS the answers at submit time, so they are no longer
part of the payload a student receives when a test starts, and casual
inspection no longer reveals them. A modified client could still fetch
the answers collection early or submit a fake score. Full
tamper-proofing requires server-side scoring (Cloud Function, paid
Blaze plan) — step 3 of the fix path — and stays out of scope under
the owner's free-only rule.

### 4. Teacher toggle for student answer review (v1.1.1)

Each test now has a `showAnswers` setting (test editor switch "Show
correct answers after submit", ON by default). When ON, the student
result screen shows the full per-question review after submitting, as
before; when OFF, the review is replaced by a short note and the
student sees only their score/result card. The default is `true` both
in the `TestModel` constructor and in `fromMap` when the field is
missing from a Firestore doc, so every test created before this
setting existed keeps showing reviews exactly as before — no data
migration is needed. Only the DISPLAY is gated: scoring is unchanged
(the student client still fetches the answers internally at submit
time to compute the score), and teacher screens (attempt detail,
results) always show the full review regardless of the setting.

### 5. Mobile-only: web link removed from the share screen (v1.1.2)

Owner decision (2026-11-27): Test Mindset is a mobile app only — the
web version was never deployed, so the student web link shown on the
share screen pointed nowhere. The share screen now shows only the
test code (copy + share text are code-based); students open the app
and enter the code on the home screen. `AppConfig.webBaseUrl` /
`studentLinkFor` remain in the config, unused, in case a web deploy
is ever revived.

## v1.1.4 (2026-11-27) — Google sign-in

Version `1.1.4+6`. Teachers can now sign in with Google from both the
login and register screens ("Continue with Google" button below the
email form, separated by an "or" divider):

- **Dependency:** `google_sign_in: ^6.2.2` (the classic 6.x API —
  deliberately not 7.x, whose API changed completely).
- **Flow:** `AuthService.signInWithGoogle()` runs the Google account
  picker, exchanges the tokens for a Firebase credential
  (`GoogleAuthProvider.credential`) and signs in with
  `signInWithCredential`. It returns a bool: false means the user
  cancelled the picker, which `AuthController.signInWithGoogle()`
  treats as a silent no-op (no snackbar, no navigation). On success
  the controller navigates exactly like email login
  (`Get.offAllNamed(AppRoutes.dashboard)`); on error it shows
  `AuthService.friendlyError` in a snackbar.
- **Teacher doc auto-created:** on a first Google sign-in, if
  `teachers/{uid}` does not exist it is created with the same shape
  register() writes — `name` from the Google profile's displayName,
  `institute` empty, `email`, `createdAt` serverTimestamp. Existing
  docs are left untouched.
- **Logout** also signs out of GoogleSignIn (guarded try/catch), so
  the account picker is offered again next time instead of silently
  reusing the last account.
- **Signing:** release builds move from the ephemeral CI debug key to
  a stable keystore kept in CI secrets, and that keystore's SHA-1 is
  registered in the Firebase project — Google sign-in on Android
  requires the SHA-1 match. Because the signing key changes, phones
  upgrading from v1.1.3 or earlier need a one-time uninstall before
  installing v1.1.4 (account and tests are in the cloud; nothing is
  lost).

## v1.3 (2026-11-27) — Learning Mode: all portions

Version `1.3.0+8`. Learning Mode grows from 2 portions to 11. The
v1.2 pattern is extended, not redesigned: same generator
(`tools/generate_learning_data.py`, new modes `world|topics|maths`,
`all` runs everything), same LessonScreen / TopicScreen /
PracticeQuizScreen (now parametrized by portion), same
ProgressService key scheme. Teacher/student/auth flows untouched.

### Portions and where their content lives

| Portion | Kind | Data file | Source docs |
|---|---|---|---|
| English | 46 lessons, 13 parts | english_lessons_a/b/c.dart | docs/lessons/ |
| Pakistan | map (143 pins) + 6 topics | geography_data.dart | docs/geography/ + docs/pakstudy/ |
| World | map (39 pins) + 2 topics | world_data.dart | docs/world/ |
| Space | 3 topics + solar-system visual | space_data.dart | docs/space/ |
| Computer | 8 topics (5 course + 3 practical) | computer_data.dart | docs/computer/ |
| Maths | 9 lessons with 10 MCQs each | maths_lessons.dart | docs/maths/ |
| Urdu | 5 topics | urdu_data.dart | docs/urdu/ |
| Islamiat | 6 topics | islamiat_data.dart | docs/islamiat/ |
| History | 4 topics | history_data.dart | docs/history/ |
| Tanzeemain aur Muahide | 2 topics | orgs_data.dart | docs/orgs/ |
| Everyday Science | 4 topics | eds_data.dart | docs/eds/ |

- **Pak Studies** topics (movement, leaders, constitutions-govt,
  symbols-firsts) are emitted into the SAME `geoTopics` list, after
  the geography topics — one Pakistan portion, one progress counter.
- **Generic screens:** `PortionScreen` (arguments: portion id) serves
  every topic portion; `LessonsListScreen` (arguments: portion id)
  serves Maths. New routes: `/learn/portion`, `/learn/lessons`,
  `/learn/world-map` — all without AuthMiddleware, like the rest of
  Learning Mode.
- **Progress keys:** lessons/topics keep `learn_done_<id>` /
  `learn_best_<id>`. The id for a topic is its `progressId`: the
  plain doc id for the Pakistan portion (v1.2 keys preserved, no
  progress lost on upgrade) and `'<portion>:<id>'` for every other
  portion, so portions can never collide. `learn_last_subject` now
  stores the portion id; the home resume chip resolves lessons
  (English/Maths) and topics (any portion) from it. The world map
  quiz has its own best key, `learn_best_world_map_quiz` (the
  Pakistan one stays `learn_best_map_quiz`).

### World map

- Asset: `assets/learning/world_map.jpg` — 2000×1000 JPEG, 262 KB.
  Source: Wikimedia Commons file "Blue Marble Next Generation +
  topography + bathymetry.jpg" (3600×1800), NASA Earth Observatory
  data produced by Reto Stöckli; the file description states
  "Equirectangular projection" and the image is public domain.
  Downscaled to 2000 px wide at JPEG quality 80.
- Calibration: the image is a full plate carrée — edges are exactly
  lon −180..180 and lat 90..−90 (2:1 aspect, no latitude cropping),
  so pins use x = (lon + 180) / 360, y = (90 − lat) / 180
  (`WorldFeature.xFraction/yFraction`). Calibration was verified by
  plotting known pins (Everest, Nile mouth, Panama, Greenland,
  Baikal, Bering, Sahara, Amazon, Indonesia) onto the image — all
  landed on the right landforms.
- Pins: 39 (23 from world-features.md, 16 from gulfs-straits.md).
  Categories: for world-features.md the generator maps the doc's own
  section headings to chips (Darya, Registran, Pahar, Canal/Aabnaye,
  Jheelain, Jazire); for gulfs-straits.md the category comes from the
  feature name (Strait/Channel → Aabnaye, Gulf → Khaleej, Bay → Bay,
  Sea → Samandar). `WorldMapScreen` reuses the Pakistan MapScreen
  pattern (InteractiveViewer, chips, bottom-sheet detail, 10-round
  Map Quiz) with its own controller and quiz-best key.

### Solar-system visual (Space portion)

`lib/learning/widgets/solar_system_visual.dart` — drawn entirely
with Flutter widgets (no images): a dark card with a horizontally
scrollable row, Sun + 8 planets as coloured circles in correct
order and roughly relative sizes (compressed — true ratios would
make Mercury invisible). Real colours: Mercury grey, Venus
yellowish, Earth blue, Mars red-orange, Jupiter banded tan (striped
ClipOval), Saturn pale gold with an elliptical ring, Uranus pale
cyan, Neptune deep blue. Tapping a body opens a bottom sheet with
that body's full section text: the generator splits
docs/space/solar-system.md by its planet headings into
`planetSections` (Sun + 8). The full solar-system text also remains
a normal reading topic; the asteroid-belt and Pluto sections exist
only in the topic, not as tappable bodies.

### Visual-note cards ("Tasveer ka khayal")

For the computer, everyday-science, islamiat, history and space
portions, the generator's topic parser runs in tasveer 'card' mode:
a "Tasveer ka khayal" line (own block, bare heading + description
block, mid-block line, or the closing "Aakhir me tasveer..." section)
becomes a `LessonBlock.visual` — rendered by LessonBlocksView as a
highlighted tertiary card with an image icon and the full
description text. English lessons keep the v1.2 behaviour (the
section is not part of the body); orgs topics run in 'strip' mode
(their two tasveer blocks are dropped); urdu/world/pakstudy docs
contain none. Counts in v1.3: computer 60, eds 36, history 17,
islamiat 5, space 2 visual cards. These are DESCRIBED diagrams, not
drawn images — producing real diagram artwork per card is future
work; the card text is the full doc description, nothing is hidden.

### Generator discipline (kept from v1.2)

Parse report prints per-file block/MCQ/pin counts; problems are
collected, not silently passed: maths lessons must have exactly 10
MCQs with 4 options and a full answer key, world pins must total
39, and a leak check asserts no 'Pin:' text survives into any
rendered body. v1.3 run: no parse problems; the regenerated English
data files are byte-identical to v1.2 and geography_data.dart only
gained the 4 Pak Studies topics (309 insertions, 0 deletions).
Parser issues are fixed in the parser, never in the master docs —
including docs/computer/practical-excel.md, whose real Excel
formulas contain asterisks (=F2/300*100) that pass through as
content.

### Honest limits

- No local Flutter SDK: this build was hand-checked (brace balance
  across all lib files, API consistency against the v1.2 code) and
  CI is the compile proof, same as v1.1–v1.2.
- Urdu portion text mixes Roman Urdu with Urdu-script words/verses;
  it renders with the platform's default fonts (Android handles
  Urdu script natively). No bundled Urdu font is shipped.
- The solar-system sizes/colours are a teaching visual, not a
  scale model; the doc text says so where it matters.

## v1.3.1 (2026-11-27) — audit fixes (content + generator only)

An independent audit of v1.3 (210 sampled MCQs, all facts, pins, style
and structure) found exactly three defects; all three are fixed here:

1. Wrong answer key, grammar-25 MCQ 8 ("She speaks very softly" —
   very = ?). The doc's key line read "Jawab A nahi, jawab B hai...",
   and the generator took the rejected first letter (A, adjective);
   the correct answer is B (adverb). Fixed at both layers: the doc
   line now uses the standard format ("8. Jawab B hai, adverb. ..."),
   and `parse_key` in tools/generate_learning_data.py is hardened —
   when a key line contains a "nahi" rejection between two "jawab"
   mentions, the letter after the LAST "jawab" wins. Verified: Q8 now
   generates correctIndex 1, and no other MCQ key changed anywhere
   (all 550 English + Maths keys diffed against the v1.3 output).
2. Missing closing recaps. `parse_features` dropped each feature
   file's closing recap section (the text after the last feature's
   Pin) — e.g. the dams north-to-south order line and the borders
   length trick never reached students. The generator now appends
   that trailing content to the last feature's body. Affected files:
   geography rivers, dams-barrages, borders, coast-ports,
   deserts-plains, doabs, heritage, lakes, mountains, passes, and
   world world-features + gulfs-straits. Feature/pin counts are
   unchanged (Pakistan 143, World 39) and no "Pin:" text leaks.
3. History order. docs/history/wars-712-1947.md presented the Third
   Battle of Panipat (1761) before Plassey (1757). The Plassey
   section now comes first (1757 → 1761 → Buxar 1764), moved
   unchanged; the closing recap's warning about this exact order
   trap is kept.

## v1.4 (2026-11-27) — real interactive maps (owner feedback on v1.3.1)

The owner rejected the static relief-image maps outright: "fazul"
(worthless), all 143 pins mixed together, nothing understandable.
He pointed at mapcarta.com and asked for a map like that — "3d".
Both maps are now REAL slippy maps.

- Library: flutter_map 8.3.2 (+ latlong2 0.9.1) — the one new
  dependency. Its API was verified against the published package
  source before writing any code (MapOptions.initialCameraFit /
  cameraConstraint, TileLayer, MarkerLayer, RichAttributionWidget).
- Tiles: OpenTopoMap (https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png,
  subdomains a/b/c, maxNativeZoom 15). Its hill-shaded relief and
  contour lines are what makes mountains/valleys look raised —
  the closest free tile style to Mapcarta's terrain view. The map
  carries the required attribution on the map itself
  (RichAttributionWidget, bottom-left): © OpenStreetMap
  contributors, © OpenTopoMap (CC-BY-SA), SRTM data.
- Pins sit at their real lat/lon as flutter_map Markers (the old
  image-calibration fractions are gone from the screens; the model
  getters remain, marked legacy). Pins are category-coloured
  teardrops with the place's first letter in a white circle.
- THE MIX FIX: no category is selected by default, so the map
  opens CLEAN — just terrain and a hint bar ("Upar se aik qisam
  chunein"). Tapping a category chip shows ONLY that category's
  pins; tapping it again clears back to none. 'Sab' still exists
  as a chip but is never the default. Rotation is disabled so
  north stays up and labels stay readable.
- Pakistan: opens fitted to the country (lat 23.4–37.3,
  lon 60.5–80.5), camera contained to Pakistan + margin
  (CameraConstraint.contain), zoom 4–16. World: opens on the
  whole world (zoom from 2), no bounds constraint.
- Map Quiz works on the real map: MapOptions.onTap gives the
  tapped LatLng; correct = within 120 km (Pakistan) / 900 km
  (world) of the target, judged by haversine distance. After each
  answer the correct pin is revealed AND the camera moves to it,
  so the student sees where the place actually is. Best-score
  keys unchanged (learn_best_map_quiz / learn_best_world_map_quiz).
- Caching / offline: FMTC 10.1.1 was evaluated (it pairs with
  flutter_map ^8.1.1) but NOT integrated: flutter_map 8.3's
  NetworkTileProvider already ships a built-in disk caching
  provider (enabled by default, ~1 GB cap in the platform cache
  dir), which gives exactly the wanted behaviour — an area viewed
  once reopens offline — with zero native dependencies. FMTC's
  ObjectBox backend would have added native libraries and an
  init step in main() for no user-visible gain. If tiles fail
  (offline, area never viewed), an amber banner says in plain
  Roman Urdu: "Naqsha load karne ke liye internet chahiye — aik
  dafa khul jaye to save ho jata hai." Already-cached areas keep
  working silently.
- Removed: assets/learning/pakistan_relief.jpg and
  assets/learning/world_map.jpg plus the pubspec assets block —
  nothing else referenced them (the whole Learning Mode is now
  asset-free; content is bundled Dart data).
- Honest limit: a real-time 3D globe like Google Earth (tilt,
  orbit, extruded terrain in the hand) is NOT possible in this
  stack — flutter_map is a 2D slippy map. What the student gets
  is the Mapcarta experience: real pan/zoom over shaded relief
  where the mountain ranges visibly rise out of the map.

## v1.5 (2026-11-27) — a map image inside every point's detail

Owner feedback on v1.4: the details are still text-only and boring —
"jo details hain uski bhi map ki images add krna hr point ki... konsy
country hain... sirf static text bore krdy ga". Every map point now
carries its own map picture, showing where it is and what surrounds it.

- Snapshot pipeline: tools/generate_map_snapshots.py (new; Python +
  Pillow, venv in tools/.venv) stitches OpenTopoMap tiles — the same
  source as the live maps — into one JPEG per place, centred on the
  feature with an orange teardrop marker at its exact position.
  Tiles are fetched politely (User-Agent identifying the app,
  ~4 requests/second max) into a disk cache at ~/workspace/tile-cache/,
  so rebuilds run offline-fast (the shipped set: 2,191 tile reads,
  0 new fetches). Tile data (c) OpenStreetMap contributors,
  (c) OpenTopoMap (CC-BY-SA), SRTM.
- Zoom per category, tuned so the surroundings show: Pakistan —
  Darya 7, Bandh/Barrage 8, Daray 8, Pahar 7, Doab 8, Heritage 9,
  Sarhad 6, Sahel 7, Registran/Maidan 7, Jheelain 8. World —
  seas/gulfs/bays 3, straits/canals 6, rivers 4, mountains 5,
  deserts 4, lakes 5, islands 5.
- Coverage: all 143 Pakistan features + all 39 world features get a
  snapshot at assets/learning/maps/pakistan|world/<feature-id>.jpg.
  MapFeature / WorldFeature gained an imageAsset field, filled by
  tools/generate_learning_data.py from the path pattern — and the
  generator now FAILS (exit 1) if any referenced snapshot file is
  missing, so a data build can never ship a dangling image path.
  Both detail sheets show the snapshot full-width at the top, with
  the text body below it.
- Reading topics: new LessonBlockType.image (asset path in text,
  caption in note), rendered full-width with rounded corners by
  LessonBlocksView. The countries topic gets each country's own
  snapshot (all 30 countries in countries.md; centroid table in the
  generator, zoom 3 for the giants, 4 default, 5 for small
  countries) at the start of that country's section. The five ocean
  snapshots (zoom 2–3, centres picked so the surrounding continents
  show — the Indian Ocean is centred at -15/75 so India and
  Pakistan's coast are in frame) sit together, in ocean order, in
  the world-terms topic's "Ocean aur Sea ka farq" section. Why
  there: the oceans' prose sections in world-features.md sit before
  that file's first pin and parse into map features only — they
  never reach a topic; ocean-vs-sea is actually taught in
  world-terms, so the ocean pictures live with that lesson.
- Size watch: at 720x520 / quality 78 the 217 snapshots totalled
  23.66 MB (projected APK ~86 MB, over the ~85 MB line), so the
  shipped set was regenerated at 640x470 / quality 72 = 16.83 MB
  total (projected APK ~79 MB; v1.4 APK was 62.2 MB). Regenerate
  with other dimensions via the script's --width/--height/--quality
  flags if a future build needs it.
- Folded in: the v1.4 pre-delivery check's one cosmetic nit — the
  on-map attribution now renders "(c) OpenTopoMap (CC-BY-SA)"
  exactly as these notes claim (prependCopyright: false removed
  in topo_map.dart).
- Untouched: every content text, all progress keys, the live maps
  themselves, and all teacher/student flows.

## First build — files the Flutter SDK must generate

This scaffold was written by hand (no Flutter SDK on the writing
machine). Before the first GitHub Actions build, these SDK-generated
pieces must exist; the hand-written files are template-accurate, so
regeneration is safe if the customizations are re-checked afterwards:

- `android/gradle/wrapper/gradle-wrapper.jar` (binary; cannot be
  hand-written) and `android/local.properties` (written by the Flutter
  tool on the CI machine automatically).
- `web/` platform files (`web/index.html` etc.) for the web build.

Practical route used by the owner's other projects: in the Actions
workflow (or once locally), run
`flutter create --project-name test_mindset --org com.muhammad --platforms android,web .`
in the repo root, then verify the three customizations survived:
`applicationId = "com.muhammad.mindset"` in `android/app/build.gradle`,
`android:label="Test Mindset"` + the INTERNET permission in
`AndroidManifest.xml`, and `MainActivity.kt` under
`kotlin/com/muhammad/mindset/`. Commit the generated wrapper jar and
`web/` folder with the repo (workflow files need the owner's `workflow`
token scope workaround — push code first, add the workflow via the
GitHub web UI, as with his other repos).

## Firebase — what is NOT done yet (owner steps)

- No Firebase project exists yet; `lib/firebase_options.dart` is a
  placeholder with `isConfigured = false`, so the app currently starts
  on the setup-pending screen by design. Full steps: README
  "Firebase setup" (create project, add Android app
  `com.muhammad.mindset`, add Web app, paste config, enable
  Email/Password auth, create Firestore, paste the suggested rules).
- `AppConfig.webBaseUrl` is the placeholder
  `https://testmindset.pages.dev` — update it to the real deployed domain
  before sharing links, or the links on the Share screen will point at
  a domain that does not exist yet.
- The google-services Gradle plugin is intentionally NOT wired in the
  skeleton (it fails the build without `google-services.json`). The
  exact two lines to add are marked with NOTE comments in
  `android/app/build.gradle` and `android/settings.gradle`.

## Dependency versions (pubspec.yaml)

Pinned to stable majors known to coexist: `get ^4.7.2`,
`firebase_core ^3.6.0`, `firebase_auth ^5.3.1`,
`cloud_firestore ^5.4.4`, `google_sign_in ^6.2.2` (v1.1.4; classic
6.x API, not 7.x), `file_picker ^13.4.0` (same major as the
owner's PDF editor app), `csv ^6.0.0`, `share_plus ^13.3.1`
(`SharePlus.instance.share(ShareParams(...))` API), `intl ^0.19.0`,
`flutter_map ^8.3.2` + `latlong2 ^0.9.1` (v1.4; real maps).
If a future `pub get` conflicts, prefer bumping the Firebase trio
together (core/auth/firestore majors move in lockstep).


## Addendum 2026-11-27 — Firebase Spark quota note (verified from Firebase pricing summaries)

Spark (free) tier: $0, no card, hard stop at quota. Firestore: 1 GiB stored,
50,000 reads/day, 20,000 writes/day, 20,000 deletes/day, 10 GiB egress/month.
Auth: 50,000 MAU. Fits the owner's FREE-ONLY rule.

Consequence of the §6 data model (each question = its own document): a
100-question test costs ~100 reads per student attempt → roughly 500 full
100-question attempts/day before the daily read quota stops the app (plus
teacher reads/writes). Accepted as a known v1 limit — plenty to start.
If usage ever approaches it, the fix is bundling a test's questions into a
few larger documents (fewer reads per attempt), not a paid plan.

Name note (updated 2026-11-27): the original working name was dropped after
a namesake check found earn-money trivia apps using it. The owner chose
**Test Mindset** as the FINAL name on 2026-11-27 (checked the same day: no
exact-match app on Play; a near-namesake "Test Minds" exam-prep app exists —
different name, no block). Package id is com.muhammad.mindset, Dart
package name test_mindset, repo renamed to test-mindset.

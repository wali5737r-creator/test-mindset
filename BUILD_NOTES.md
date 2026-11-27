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
    auth_service.dart            Register/login/logout/reset + teachers/{uid}
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
`cloud_firestore ^5.4.4`, `file_picker ^13.4.0` (same major as the
owner's PDF editor app), `csv ^6.0.0`, `share_plus ^13.3.1`
(`SharePlus.instance.share(ShareParams(...))` API), `intl ^0.19.0`.
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

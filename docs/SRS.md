# Test Mindset — Online Quiz Maker (SRS v1.0, 2026-11-27)

Owner: Muhammad. Built by Glint. Reference product studied 2026-11-26: rayvila.com
(features matched, design and text original — nothing copied).

## 1. Product

A free online quiz maker for **Pakistani teachers, academies and students**
(PPSC / FPSC / NTS / CSS / board-exam preparation). A teacher creates an
account, builds a test, adds questions, sets a timer, and shares ONE link.
Students open the link (no app install, no login), enter their name, take the
timed test, and see their result instantly. The teacher sees all results in
one dashboard.

Name: **Test Mindset** — FINAL, decided by the owner 2026-11-27 (the earlier
working name was dropped after a namesake check; name lives in one
place, `lib/config/app_config.dart`).
Package: `com.muhammad.testmindset`. Project: `~/workspace/test-mindset-app/`.
This project is COMPLETELY SEPARATE from WolfTyping and Pakistan Finance
Calculators (separate repo, separate Firebase project, separate deploy).

## 2. Stack (all free)

- Flutter (one codebase) → Android APK + Web app (shareable links run on web).
- Firebase Spark (free) plan: Authentication (email/password), Cloud
  Firestore (tests, questions, attempts/results).
- GitHub Actions builds the APK (same pipeline as gta-remote / pdf-editor).
- Web build hosted on Cloudflare Pages (free), its own project.
- State management: GetX (owner's settled choice).

## 3. Users

- **Teacher** — registers/logs in, owns tests and results.
- **Student** — no account; opens a link or enters a test code, gives name
  (+ optional roll/ID), takes the test, sees own result.

## 4. Features v1 (core — Rayvila-matched)

Teacher:
1. Register (institute/name, email, password), login, forgot password.
2. Dashboard: my tests list (title, questions count, status, attempts count).
3. Create/edit test: title, description, duration (minutes), marks per
   question, negative marks per wrong answer (default 0), shuffle questions
   on/off, status Draft / Published / Closed.
4. Questions: add/edit/delete MCQ (question text, 4 options, one correct,
   optional explanation), up to 200 per test. Question text supports Urdu.
5. Import questions from CSV/text file (format documented in README).
6. Publish → short test code (6 chars) + shareable link + copy/share buttons.
7. Results: per test, list of attempts (student name, score, %, time used,
   date), attempt detail (per-question correct/wrong review), export CSV,
   delete attempt, clear results.

Student:
8. Open link `/#/t/<code>` or enter code on home screen → test intro page
   (title, questions, duration, negative marking note) → name (+ optional
   roll) → start.
9. Test screen: countdown timer, question palette (answered/unanswered),
   one question at a time with Next/Previous + a scroll-all view toggle,
   auto-submit at zero, confirm-before-submit dialog.
10. Result screen: score, %, correct/wrong/skipped counts, time used, full
    answer review with explanations. Result saved to teacher's dashboard.

## 5. Improvements over Rayvila (built into v1 or v1.1)

- One modern, consistent design (Rayvila has 3 mismatched looks).
- Pakistan-first: categories PPSC/FPSC/NTS/CSS/Board; Urdu question support.
- Timed practice WITH scores (Rayvila's free Q&A is show/hide answer only).
- Results do NOT auto-delete in 30 days (kept until teacher deletes, within
  free-tier limits).
- Student result certificate-style card (shareable) — v1.1.
- Free practice section (no login): sample sets in real test mode — v1.1.
- Google sign-in — v1.1 (needs extra Firebase/Android config).
- Clean English, no typos; contact form in app — v1.1.

## 6. Data model (Firestore)

- `teachers/{uid}`: name, institute, email, createdAt.
- `tests/{testId}`: ownerId, code (unique, indexed by query), title,
  description, durationMin, marksPerQuestion, negativeMarks, shuffle,
  status, questionCount, createdAt.
- `tests/{testId}/questions/{qid}`: text, options[4], correctIndex,
  explanation, order.
- `tests/{testId}/attempts/{aid}`: studentName, roll, answers[], score,
  total, correct, wrong, skipped, timeUsedSec, submittedAt.
- Student read of a test is by code query; questions are read once at start;
  the correct answers must NOT be sent to the student before submit —
  v1 ships answers with questions for simplicity of the free tier build and
  marks this as a known v1 limitation; v1.1 moves scoring to a Cloud
  Function or split collections (public question doc without correctIndex +
  private answer doc readable only by owner; scoring on client after submit
  by fetching answers once — documented in BUILD_NOTES).

## 7. Non-goals v1

Payments, blog, YouTuber panel, API, image/video questions (v2 candidate),
proctoring. No paid service of any kind (owner's FREE-ONLY rule).

## 8. Owner steps (only Muhammad can do)

1. Create the Firebase project (free, ~5 min, Glint guides screen by screen)
   under his Google account; Glint then wires the config files.
2. Logo/branding approval when a logo is proposed (name is final: Test Mindset).
3. Own-device test of the APK and the student link.

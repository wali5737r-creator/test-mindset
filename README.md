# Test Mindset — Online Quiz Maker

A free online quiz maker for Pakistani teachers, academies and students
(PPSC / FPSC / NTS / CSS / board-exam preparation).

A teacher creates an account, builds a test, adds questions, sets a timer,
and shares **one link**. Students open the link — **no app install, no
login** — enter their name, take the timed test, and see their result
instantly. The teacher sees all results in one dashboard.

- **Package id:** `com.muhammad.mindset`
- **Stack:** Flutter (Android APK + Web from one codebase) · Firebase
  (Auth + Cloud Firestore, free Spark plan) · GetX
- **App name** lives in one place: `lib/config/app_config.dart`
  (`AppConfig.appName`) — change it there and in
  `android/app/src/main/AndroidManifest.xml` (launcher label) to rename.

> Status: v1 code is complete. The app shows a friendly "setup pending"
> screen until Firebase is configured (see below). Nothing paid is used
> anywhere.

## Features (v1)

**Teacher**
- Register (name, institute, email, password), login, forgot password.
- Dashboard: my tests with question count, status and attempts count.
- Create/edit test: title, description, duration (minutes), marks per
  question, negative marks per wrong answer, shuffle on/off,
  status Draft / Published / Closed.
- Questions: add/edit/delete MCQs (question text, 4 options, one correct,
  optional explanation), up to **200 per test**. Urdu text works.
- Import questions from a CSV file (format below).
- Publish → a 6-character test code + shareable link, with copy/share
  buttons.
- Results per test: student name, score, %, correct/wrong/skipped,
  time used, date; per-attempt question-by-question review; export CSV;
  delete one attempt; clear all results.
- Results are **not** auto-deleted after 30 days — they stay until the
  teacher deletes them.

**Student (no login)**
- Open the link `/#/t/<code>` or enter the code on the home screen.
- Intro page: test title, question count, duration, negative-marking
  note → name (+ optional roll number) → start.
- Test screen: countdown timer (auto-submits at zero), question palette
  (answered / unanswered), one-question view **and** scroll-all view,
  confirm-before-submit dialog.
- Result screen: score, %, correct/wrong/skipped, time used, and a full
  answer review with explanations. The result is saved to the teacher's
  dashboard automatically.

## CSV import format

In the question list screen, tap the **Import CSV** button and pick a
`.csv` (or `.txt`) file. Columns, in this order:

```
question,optionA,optionB,optionC,optionD,correct,explanation
```

- A header row with these names is detected and skipped.
- `correct` accepts **A / B / C / D** or **1 / 2 / 3 / 4**.
- `explanation` is optional (the column may be left empty or omitted).
- Rows with an empty question/option or an invalid `correct` value are
  skipped, and the app reports how many were imported and skipped.
- Import stops at the 200-questions-per-test limit.
- Wrap a field in double quotes if it contains a comma.

Example (`questions.csv`):

```csv
question,optionA,optionB,optionC,optionD,correct,explanation
What is the capital of Pakistan?,Karachi,Lahore,Islamabad,Quetta,C,Islamabad became the capital in 1967.
Which is the largest planet?,Earth,Jupiter,Mars,Venus,2,Jupiter is the largest planet in our solar system.
"Pakistan came into being on ____.",14 August 1947,23 March 1940,27 Ramadan 1366,None of these,A,
```

Tip: make the file in Excel or Google Sheets and use
**File → Save As / Download → CSV**.

## Firebase setup (one time, free, ~10 minutes)

The app code is finished; only a Firebase project has to be created and
its values pasted in. The owner creates the project (it must be under
the owner's Google account); Glint can guide screen by screen.

1. **Create the project**
   - Go to https://console.firebase.google.com → *Add project* →
     name it (e.g. `test_mindset`) → continue. Google Analytics can be
     skipped/off. Create project.

2. **Register the Android app**
   - In the project, click the Android icon → package name:
     `com.muhammad.mindset` → Register app.
   - Download **google-services.json** and put it in `android/app/`.
   - Add the google-services Gradle plugin (the exact lines are marked
     with a NOTE comment in `android/app/build.gradle` and
     `android/settings.gradle`):
     - `android/settings.gradle`, in `plugins {}`:
       `id "com.google.gms.google-services" version "4.4.2" apply false`
     - `android/app/build.gradle`, in `plugins {}`:
       `id "com.google.gms.google-services"`

3. **Register the Web app**
   - Project settings (gear icon) → *Your apps* → Web icon (`</>`) →
     nickname `Test Mindset Web` → Register app.
   - Copy the shown `firebaseConfig` values into
     `lib/firebase_options.dart` (the `web` and `android` constants —
     the Android values are in Project settings → the Android app),
     then set `isConfigured = true` in that file.
   - (Shortcut if Flutter is installed locally: `dart pub global activate
     flutterfire_cli` then `flutterfire configure` rewrites
     `firebase_options.dart` for you.)

4. **Enable Email/Password sign-in**
   - Build → Authentication → Get started → Sign-in method tab →
     **Email/Password** → Enable → Save.

5. **Create Firestore**
   - Build → Firestore Database → Create database → Start in
     **production mode** → Create.
   - Then open the **Rules** tab, paste the rules below, and Publish.

### Suggested Firestore security rules

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // A teacher can only touch their own profile.
    match /teachers/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    match /tests/{testId} {
      // Anyone with the link/code can read a test (students have no login).
      allow read: if true;
      // Only signed-in teachers can create; only the owner can change/delete.
      allow create: if request.auth != null
                    && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null
                    && resource.data.ownerId == request.auth.uid;

      match /questions/{qid} {
        // Public half of a question (text, options, order) - no answers.
        allow read: if true;
        allow write: if request.auth != null
          && get(/databases/$(database)/documents/tests/$(testId)).data.ownerId
             == request.auth.uid;
      }

      match /answers/{qid} {
        // The answer half (correctIndex, explanation). Readable by anyone,
        // like questions - BUT the app only requests this collection at
        // submit time, so answers are never part of the payload a student
        // receives when a test starts. Honest limit: a modified client
        // could still fetch these early; fully tamper-proof scoring needs
        // a server-side Cloud Function (paid Blaze plan) - see
        // BUILD_NOTES.md.
        allow read: if true;
        allow write: if request.auth != null
          && get(/databases/$(database)/documents/tests/$(testId)).data.ownerId
             == request.auth.uid;
      }

      match /attempts/{aid} {
        // Students submit results without a login.
        allow create: if true;
        // Only the test's owner can read or delete results.
        allow read, delete: if request.auth != null
          && get(/databases/$(database)/documents/tests/$(testId)).data.ownerId
             == request.auth.uid;
      }
    }
  }
}
```

6. **Set the real web domain** (after the web build is deployed):
   in `lib/config/app_config.dart`, set `AppConfig.webBaseUrl` to the
   deployed address (e.g. `https://testmindset.pages.dev`) so the share
   links point to the right place.

## Building

Builds run in GitHub Actions (same pattern as the owner's other apps):

- APK: `flutter build apk --release`
- Web: `flutter build web --release` → deploy `build/web` to a new,
  separate Cloudflare Pages project.

Before the first CI build, the Flutter-SDK-generated files that cannot
be written by hand must exist — see **BUILD_NOTES.md** ("First build"
section).

## Answer privacy (v1.1)

Since v1.1, each question is stored as **two** documents: the public
question (`questions/{qid}` — text, options, order) and its answer
(`answers/{qid}` — correct index, explanation). A student's device
receives **no answers when a test starts**; it fetches the answers
collection once, at submit time, scores locally, and then writes the
complete attempt. Tests created with v1 keep working: their answers are
embedded in the question documents and are used as a fallback wherever
an answers document is missing.

Honest limit: scoring still happens on the student's device and the
answers collection is readable under the free-tier rules above, so a
*modified* client could in theory fetch answers early or fake a score.
Fully tamper-proof scoring needs a server-side Cloud Function (paid
Blaze plan) and is out of scope under the free-only rule — see
`BUILD_NOTES.md`.

## What is new in v1.1

- **Shareable student result card** — after a test, the student sees a
  result card (app name, their name, test title, score, %, correct /
  wrong / skipped, date, test code) and can share it as an image with
  the **Share result** button (it falls back to a text share if the
  image cannot be created). It is a result card, not a certificate.
- **Class report for teachers** — the results screen now opens with
  total attempts, class average %, the highest scorer, and a
  per-question breakdown (how many students answered each question
  correctly, out of how many attempted it).
- **Answers split out of the student payload** — see "Answer privacy"
  above.

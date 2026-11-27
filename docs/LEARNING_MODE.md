# Test Mindset — Learning Mode (Design)

**Status:** Design v1.0 — 2026-11-27. Owner's direction: app me Teacher Mode aur
Student (code) Mode ke sath aik teesra **Learning Mode** ho, jisme subject-wise
parhai ho — PPSC one-paper ki tayyari ke liye. Pehla subject: **English Grammar**
(24 units). Har lesson hamari apni likhi hui, original, teacher-voice me —
Roman Urdu explanation pehle, English rule sath, aur examples jahan rule ka
istemaal saaf nazar aye. Koi video copy nahi, koi bacho wali tone nahi —
adult PPSC aspirant ke liye, lekin itna asaan ke kamzor tareen student bhi
concept kabhi na bhule.

---

## 1. Learning Mode kahan baithega

Home screen (`/home`) par abhi do raste hain: student code entry aur teacher
login. Learning Mode **teesri entry** ke tor par ayega — aik alag card/button:

```
+--------------------------------------------------+
|  TEST MINDET (home)                              |
|  [ Students: enter your test code        ]       |
|  [ Teacher Login                         ]       |
|  [ 📚 Learning Mode — PPSC ki tayyari    ]  <--  |
+--------------------------------------------------+
```

- **Koi login nahi, koi internet nahi, koi Firebase nahi.** Learning content
  app ke andar bundled hoga (Dart data files), progress device par local
  save hogi. Ye jaan-boojh kar Teacher/Student modes se alag rakha gaya hai:
  learning kabhi band na ho, chahe server ho ya na ho.
- Learning Mode ki routes AuthMiddleware se **bahar** hongi (student routes
  ki tarah open).

### Naye routes (`lib/routes/app_routes.dart` me izafa)

| Route | Screen | Kaam |
|---|---|---|
| `/learn` | `LearnHomeScreen` | Subject list + overall progress |
| `/learn/subject/:subjectId` | `SubjectScreen` | Us subject ke lessons ki list |
| `/learn/lesson/:lessonId` | `LessonScreen` | Poora lesson (scroll) |
| `/learn/quiz/:lessonId` | `LessonQuizScreen` | Lesson ke 10 practice MCQs |

### Nayi files (jab build hoga)

```
lib/learning/
  learning_routes.dart        (upar wale routes ke naam)
  models/lesson.dart          (neeche wala data model)
  data/subjects.dart          (subject list)
  data/grammar_lessons.dart   (24 grammar lessons ka data)
  data/<subject>_lessons.dart (aane wale subjects)
  services/progress_service.dart  (SharedPreferences wrapper)
  screens/learn_home_screen.dart
  screens/subject_screen.dart
  screens/lesson_screen.dart
  screens/lesson_quiz_screen.dart
  widgets/lesson_blocks.dart  (rule box, example card, trap card, table, diagram)
```

Dependency: sirf aik naya package — `shared_preferences` (progress ke liye).
Baaki sab maujooda stack (Flutter + GetX) par.

---

## 2. Screens — tafseel

### 2.1 Learn Home (Subject list)
- Har subject aik card: naam (English + Roman Urdu), total lessons,
  complete lessons ka count, progress bar, "Jari rakhein" chip agar
  darmiyan me chhoda hua lesson ho.
- Pehla subject live: **English Grammar (24 lessons)**. Baaki subjects
  "Jald aa raha hai" badge ke sath dikhenge (neeche roadmap dekhen) taake
  structure pehle din se subject-wise ho.

### 2.2 Subject Screen (Lesson list)
- Lessons number ke hisaab se (Unit 1, 2, 3...) — har row: number, title
  (English + Roman Urdu), chhota sa one-line note, aur status:
  - ✓ tick — lesson parh liya
  - 🏆/score chip — practice quiz ka best score (masalan 8/10)
  - ▶ "Jari rakhein" — jo lesson aakhri dafa khula tha
- Upar subject ki total progress (masalan "24 me se 7 lessons complete").

### 2.3 Lesson Screen
Lesson ka template (neeche §4) hi screen ki tartib hai — aik lamba scroll:
1. Title + "Ye lesson kyun zaroori hai"
2. Concept (Roman Urdu, teacher voice)
3. **English Rule** box (highlighted card)
4. Misaalein — har example aik card: jumla (key hissa bold/color),
   neeche Roman Urdu note
5. Kahan use hota hai
6. Yaad rakhne ki trick (alag rang ka card — ye hissa har lesson ki jaan hai)
7. Aam ghalti / PPSC trap — wrong ✗ vs right ✓ jode
8. Tasveer/diagram blocks (jahan lesson me hon)
9. Neeche do button: **"Practice MCQs (10)"** aur **"Lesson Complete ✓"**
   (complete dabane se progress save; na dabaye to bhi quiz pass karne par
   auto-complete).

### 2.4 Practice Quiz (per lesson)
- Har lesson ke sath usi ke 10 PPSC-style MCQs (lesson data me hi mojood).
- Aik waqt me aik sawal, 4 options; option tap karne par **foran** sahi/ghalat
  + aik line ki explanation (waisa hi jaisa answer key me likha hai).
- Aakhir me score card (result card wale andaaz me): score, percentage,
  ghalat sawalo ki review. Best score local save hota hai.
- Quiz dobara dene ki poori ijazat — koi timer nahi (ye practice hai,
  imtihan nahi; timer wale test Teacher Mode me hain).

### 2.5 Progress (local, offline)
`ProgressService` (SharedPreferences) — keys:
- `learn_done_<lessonId>` → bool (lesson complete)
- `learn_best_<lessonId>` → int (quiz best score, 0–10)
- `learn_last_lesson` → String (resume ke liye)
- `learn_last_subject` → String
- Subject progress = us ke lessons ke done count se hesap (alag save nahi).
- Progress sirf is device par hai; app uninstall → progress khatam
  (v1 ke liye qabool hai — learning free hai, account nahi).

---

## 3. Lesson data model

Template ke har hisse ka aik field. Dart sketch (build ke waqt final hoga):

```dart
class Lesson {
  final String id;            // 'grammar-01'
  final String subjectId;     // 'english-grammar'
  final int unit;             // 1
  final String titleEn;       // 'A, An and Nouns'
  final String titleUrdu;     // 'A, An aur Nouns — har cheez ka naam'
  final String whyImportant;  // Roman Urdu, 2-3 lines (PPSC relevance)
  final List<ConceptBlock> concept;   // teacher-voice explanation
  final List<String> englishRules;    // English Rule box ki lines
  final List<Example> examples;       // >= 8
  final String usage;                 // 'Kahan use hota hai' text
  final List<String> usageSentences;  // 2 paper-style sentences
  final String trick;                 // yaad rakhne ki trick
  final List<Trap> traps;             // wrong vs right jode
  final List<Mcq> mcqs;               // exactly 10
  final List<String> diagramIdeas;    // visual aids ki description
  final int minutes;                  // andazan waqt, masalan 8
}

class ConceptBlock {
  final String? heading;      // chhota heading (optional)
  final String urdu;          // Roman Urdu paragraph
  final String? english;      // sath English line/term (optional)
}

class Example {
  final String sentence;      // 'She is an honest officer.'
  final String highlight;     // app me rang se highlight hone wala hissa, masalan 'an'
  final String noteUrdu;      // aik line: kyun?
}

class Trap {
  final String wrong;         // 'He is a honest man. ✗'
  final String right;         // 'He is an honest man. ✓'
  final String noteUrdu;      // ghalti ki wajah
}

class Mcq {
  final String question;
  final List<String> options; // exactly 4
  final int correctIndex;     // 0-3
  final String explanation;   // aik line, Roman Urdu/simple English
}
```

- Content **Dart data files** me const lists ki surat me hoga — koi JSON
  parse nahi, koi server nahi, app size par asar na ke barabar.
- Har lesson ka source pehle `docs/lessons/<id>.md` me likha jayega
  (review ke liye), phir wahi content Dart data me convert hoga. Markdown
  hi master copy hai.

---

## 4. Lesson template (har lesson lazmi isi tartib par)

1. **Title** — English + Roman Urdu subtitle
2. **Ye lesson kyun zaroori hai** — PPSC paper me ye kahan/kese ata hai
3. **Concept — asaan alfaaz me** — teacher voice, kahani/misaal jahan fit ho
4. **English Rule** — crisp rule box
5. **Misaalein (Examples)** — kam az kam 8, har aik ke sath aik line Roman
   Urdu note. Key hissa data model ke `highlight` field se nishan-zada
   hoga aur app use rang se dikhayega — lesson ke text ke andar koi
   markdown nishan nahi hoga (neeche Style law dekhen)
6. **Kahan use hota hai** — asal zindagi ke istemal + 2 paper-style jumle
7. **Yaad rakhne ki trick** — aik hook jo zindagi bhar yaad rahe
8. **Aam ghalti (PPSC trap)** — Pakistani students ki ghaltiyan, wrong vs right
9. **Practice — PPSC style MCQs** — bilkul 10, har aik ki answer key +
   aik line explanation
10. **Tasveer/Diagram idea** — 1–2 visual aids ki description

### Style law — lesson kese likha jayega (ghair-mutabadil)

Owner ki hidayat (2026-11-27): pehle likhe gaye lessons parhne me AI ke
likhe hue lagte thay. Har lesson aise likha jayega jaise aik asal,
tajurba-kaar Pakistani English teacher class me parhata hai. Ye qanoon
template ki tartib se upar hai — tartib wahi rahegi, lekin pesh-kash
hamesha is law ke mutabiq hogi:

- Lesson ke text ke andar koi markdown sajawat nahi hogi: koi asterisk
  nahi, koi bold ya italic nahi, koi ## wale heading nahi, koi dash wali
  list nahi, koi table ya quote-block nahi. Text beh-te hue jumlo aur
  paragraphon me hoga.
- Section ke unwaan saada alfaaz me plain line honge, jaise "Pehle noun
  ko samajh lo". Blank line se section alag hoga, bas.
- Lehja: mehboob classroom ustad ka, jo students se seedha mukhatib ho
  (tum keh kar). Chhoti kahaniyan, board par samjhane wala andaaz,
  garam-joshi aur aitmaad. Roman Urdu ki rawani boli jane wali zabaan
  jaisi ho.
- Har paragraph ko zehen me bol kar parho. Agar wo report ya AI summary
  jaisa lage to dobara likho, jab tak wo aik insan ke parhane jaisa na
  lage.
- English wahan aye jahan ustad board par likhta hai: qanoon saada
  English jumlo me, prose ke beech me fit andaaz se pesh kiya jaye
  (jaise "Board par qanoon yun likha jata hai"), aur misaalon me.
- Misaalein teaching me buni hui hon ya board wale numberon (1. 2. 3.)
  me likhi hon — number classroom me fit hai, asterisk aur dash nahi.
  Har misaal ke sath us ki chhoti si Roman Urdu wajah ho.
- Ghalat aur sahi ke jode board wale andaaz me likhe jayen: "Ghalat: ..."
  aur "Sahi: ..." wali lines, sath "Wajah: ..." ki line.
- Practice MCQs asal paper ke format me rahen ge (sawal, phir A. B. C.
  D. options), kyunke yehi asal imtehan ka format hai. Answer key usi
  ustad wale lehje me, har jawab ke sath aik line ki wajah.
- Tasveer/diagram ke khayal aakhir me saada prose lines me hon ge.
- Voice standard: simple Roman Urdu pehle; English sirf rule, terms aur
  misaalon ke liye; koi robotic "AI" lehja nahi; sabr, misaal, aur
  "ye wala paper me ata hai" wali rehnumai har lesson me ho.

---

## 5. Tasveer / Diagram — kese handle hoga

Do tareeqe, pehla pehle:

1. **In-app visual blocks (preferred):** zyada tar "diagrams" asal me
   styled Flutter widgets honge — color-coded jumla breakdown (har word
   ke neeche us ka label), tables (masalan tense table, plural rules
   table), wrong/right jode wale cards. Faida: hamesha saaf (crisp),
   size zero, dark/light dono me theek, aur text ke sath update asaan.
   `lesson_blocks.dart` me reusable widgets: `RuleBox`, `ExampleCard`,
   `TrapCard`, `BreakdownSentence` (word-by-word rang), `RuleTable`.
2. **Bundled image assets (jahan asal tasveer chahiye):** masalan
   prepositions ke liye billi/meiz wali tasveer. `assets/learning/<lessonId>-<n>.png`
   naam se pubspec.yaml me `assets/learning/` register hoga. Budget:
   poori grammar course ke liye kul ~2–3 MB se zyada nahi — har tasveer
   chhoti, compressed. Tasveer baad me produce hogi; lesson markdown me
   sirf us ka **idea** likha jata hai (template step 10) taake content
   tasveer ke intezar me na ruke.

---

## 6. English Grammar — poori 24-unit syllabus (PPSC level)

Source structure: "Basic English Grammar for Children" (Grammar Tips)
playlist ke 24 units — lekin har unit ko **PPSC one-paper ki satah** tak
uthaya gaya hai. Har unit ke sath wo extra adult-level points diye hain jo
bacho wali version me nahi hote lekin paper me atay hain. **Har lesson
original hoga — video ka text/andaaz copy nahi hoga.**

| # | Unit | Scope (aik line) | PPSC level par extra (lazmi) |
|---|---|---|---|
| 1 | A, An + Nouns | Noun kya hai; singular countable ke sath a/an | Awaaz wala qanoon: a university, an honest, an heir, a European, a one-way; abbreviations (an M.A., an SDO); uncountable ke sath a/an nahi; abstract nouns par article ki trap |
| 2 | Plural Nouns | Aik se zyada — plural banane ke usool | s/es/ies/ves saare spelling rules; irregular (men, children, teeth); same-form (sheep, deer); compound (brothers-in-law); Latin/Greek (criteria, phenomena); news/mathematics singular; uncountable ki plural trap (informations ✗) |
| 3 | Pronouns + am/is/are | I/you/he/she/it/we/they aur be-verb ka jod | Subject vs object pronoun (between you and me); "It is I" formal andaaz; har subject ke sath sahi be-verb ki fori pehchan |
| 4 | What / This / That | Ye/wo — demonstratives aur what-sawal | this/that/these/those ka faasla + waqt wala istemal (this morning); it vs this ki trap; what vs which ka farq (pehchan) |
| 5 | Prepositions of Place | in, on, at, under, behind, between | Jagah ke sath at/in/on ka farq (at home, in Lahore, on the table); in the corner vs at the corner; beside/besides trap |
| 6 | There is / There are | Kisi cheez ke hone ka bayan | Qareeb wale noun se agreement (there are a pen and two books ✗ trap); sawal/nafi ki surat; there vs it |
| 7 | Possessive Adjectives + Whose | my, your, his, her, its, our, their; whose ke sawal | **its vs it's** ki mashhoor trap; possessive adjective vs pronoun ka farq (pehchan); whose vs who's |
| 8 | Adjectives / Adverbs | Cheez ki khoobi aur kaam ka tareeqa | Adjectives ki tartib (opinion-size-age-colour-origin); -ly adverbs; irregular adverbs (fast, hard, well); **good vs well**, hardly = mushkil se (negative sense) |
| 9 | Verbs | Kaam wale alfaaz; verb ki shaklein | V1–V5 forms ka system; irregular verbs ki aham list (go-went-gone); action/helping/linking verbs; transitive/intransitive ki pehchan |
| 10 | Question Sentences | Yes/no aur wh- sawal banane ka tareeqa | do/does/did ka sahara; lafz-tartib; **indirect question ki trap** (I know where he is ✓, where is he ✗); question tag ki pehchan |
| 11 | Negative Sentences | Nafi wale jumle — not, don't, doesn't, didn't | Helping verb ke baad not; doesn't/didn't ke sath base verb; double negative trap; hardly/seldom pehle se negative hain |
| 12 | Imperative | Hukum, darkhwast, mashwara | Let's wala andaaz; Don't se nafi; please ki jagah; reported commands ki pehchan (ordered him to go) |
| 13 | Uncountable Nouns | Jo gine nahi ja sakte | Aham list: advice, information, furniture, news, luggage, homework, scenery; much/a piece of ka istemal; **advices/informations/furnitures ✗** traps |
| 14 | Possessive / Objective Pronouns | mine, yours, his, hers; me, him, her, us, them | "A friend of mine" wala andaaz; between you and **me** ✓ (I ✗); adjective ke baad pronoun nahi ata |
| 15 | Helping Verbs — can / must / have to | Qudrat, ijazat, majboori | **mustn't (mana hai) vs don't have to (zaroorat nahi)** ka aham farq; could/might ki narmi; had to (past) |
| 16 | Some / Any + How many / How much | Kuch — countable vs uncountable miqdar | Darkhwast/peshkash me **some** (Would you like some tea?); few/little vs **a** few/**a** little ka matlab-badal farq; many/much ki sahi jagah |
| 17 | Comparative / Superlative | Muqabla aur sab se barha hua | -er/more ke usool; irregular (good-better-best, bad-worse-worst); as...as; **more better ✗**; elder vs older; the + superlative |
| 18 | Past Tense | Guzra hua waqt — simple past | -ed spelling rules; irregular verbs ki mukammal aham list; did + base verb (did went ✗); waqt ke isharay (yesterday, last night); **yesterday I have gone ✗** trap |
| 19 | Present / Past Continuous | Chal raha kaam — be + -ing | -ing spelling (run-running, die-dying); aadat vs abhi ka farq; **stative verbs** (know, believe, like) continuous nahi hote; while/when ke sath past continuous |
| 20 | Future — will / going to | Aane wala waqt | will = fori faisla/waada; going to = pehle se plan/andaza; shall (I/we); **time clause trap**: when he comes (will come ✗) |
| 21 | Frequency Adverbs + Prepositions of Time | Kitni dafa, aur waqt ke at/on/in | always/usually/sometimes ki jagah (main verb se pehle, be ke baad); **at** 5 o'clock, **on** Monday, **in** June; at night, at the weekend traps |
| 22 | Infinitive & Gerund | to + verb, aur verb + -ing | Konsi verbs ke baad to (want, decide), konsi ke baad -ing (enjoy, avoid); gerund subject ban kar (Smoking is bad); **stop smoking vs stop to smoke** ka farq |
| 23 | Present / Past Participle | -ing aur -ed adjectives | **boring vs bored, interesting vs interested** ki barri trap; participle verb ke hisse ke tor par (has gone, was written); jumla chhota karne ki pehchan |
| 24 | Passive Voice | Kaam par zor, karne wale par nahi | Har tense ki passive table; by ka istemal/khamoshi; kab passive behtar hai (daftar/sarkari angrezi); imperative ki passive (Let it be done); double-object passive ki pehchan |

---

## 7. Aane wale subjects (roadmap — abhi sirf Grammar)

Structure subject-wise hai taake baad me ye add ho saken (owner ke kehne par,
isi template par):
- **Everyday Science** — PPSC one-paper ka hissa
- **Pakistan Studies** — tareekh, tehreek-e-Pakistan, constitutions
- **Islamiat** — Urdu/English dono medium ke notes
- **General Knowledge / Current Affairs** — (current affairs dated hoga,
  is liye alag update cycle)
- **Basic Mathematics** — percentage, ratio, average (one-paper style)

Har naya subject = aik nayi data file + subjects.dart me aik entry.
App code dobara nahi badlega.

---

## 8. Build ki tartib (jab owner build kahe)

1. `shared_preferences` add + `ProgressService`
2. Lesson model + `grammar-01`, `grammar-02` ka data (gold standard —
   docs/lessons me tayyar hai) + teeno screens + quiz screen
3. Home screen par Learning card + routes (open, baghair middleware)
4. Baaki 22 grammar lessons isi template par (batch me)
5. Har lesson ka apna 10-MCQ quiz sath hi

**Quality rule:** jo lesson template ke saare 10 hisso par poora na utre
(8+ examples, 10 MCQs with explained key, trick, traps), wo app me nahi
jayega. Pehle do lessons (grammar-01, grammar-02) is standard ka namuna hain.

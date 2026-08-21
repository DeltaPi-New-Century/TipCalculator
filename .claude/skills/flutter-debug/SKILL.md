---
name: flutter-debug
description: Debug TipCalculator Dart/Flutter defects — compile/syntax errors, runtime exceptions, async and state bugs, Gemini/HTTP failures. Reviews the code before proposing anything and always returns at least 2 remediation options. Use on any crash, red screen, failing test, analyzer error, stack trace, or "why does X not work".
---

# Flutter Debug

Sequence is mandatory: **reproduce → locate → review → propose (≥2) → apply chosen fix → verify**. Never patch before the review step.

## 1. Triage

Classify first, it decides the tooling:

| Class | Signal | Tool |
|---|---|---|
| Syntax / type | analyzer output, red squiggles | `flutter analyze` |
| Runtime | stack trace, exception | read trace top frame first |
| Async | hang, `null` after `await`, unhandled `Future` | trace the `Future` chain |
| State | stale UI, no rebuild | check `Provider` / `notifyListeners()` |
| Network / API | Gemini or ip-api failure | check status code, headers, body shape |
| Build / platform | Gradle, Xcode, CMake | platform dir under `android/`, `ios/`, … |

## 2. Commands

```bash
flutter analyze                 # syntax + type + lint, run this first, always
dart format --output=none --set-exit-if-changed .
flutter test                    # test/widget_test.dart
flutter test --plain-name "<test name>"
flutter run -d windows          # or -d chrome / -d <device-id>
flutter run --verbose           # build/toolchain failures
flutter doctor -v               # toolchain sanity, only when build fails
flutter clean && flutter pub get  # last resort, stale build artifacts
```

## 3. Review before remediation (required)

Before writing any fix, state in ≤5 lines:

- **Symptom** — observed behaviour, exact error string quoted.
- **Root cause** — `file:line` + the mechanism, not the symptom restated.
- **Blast radius** — other call sites reached by the same path (find with Grep).
- **Why the current code does it** — the intent that was there, so the fix does not delete a feature.

If root cause is not provable from the code, say so and add a diagnostic (log/breakpoint) as step 1 rather than guessing a fix.

## 4. Propose ≥2 remediations

Fixed format, one block each, then a one-line recommendation:

```
Option A — <name>
  Change: <what, file:line>
  Pros:   <1 line>
  Cons:   <1 line>
  Risk:   low | med | high
Option B — <name>
  ...
Recommend: A — <one-line reason>
```

Options must be genuinely different (e.g. *fix at the call site* vs *fix in the service* vs *change the contract*), never "do it" vs "don't do it". Include the cheap-and-narrow option and the correct-but-larger option when they differ.

## 5. Project-specific traps

- `lib/service/gemini.dart:58` — `.catchError((_) {})` returns `null` into a `Future<TipPorcentData>`; failures surface later as a null-deref far from the cause. Any Gemini bug report starts here.
- `lib/service/config.dart:9` — `GEMINI_API_KEY` is empty and `dotenv` is commented out; a 400/403 from Gemini is a config problem, not a code problem.
- `responseData['candidates'][0]['content']['parts'][0]['text']` — unchecked index chain; a safety-blocked or empty Gemini response throws `RangeError`/`NoSuchMethodError`, and the model returns free text that `jsonDecode` may reject (`FormatException`).
- `http://ip-api.com` is cleartext — blocked by Android cleartext policy and iOS ATS on release builds; symptom is a network failure only on device.
- `Config` fields are `static final` — they read once at first access; a `.env` loaded after that is ignored.
- `Provider` state: a mutation without `notifyListeners()` shows as "value correct in logs, wrong on screen".

## 6. Verify

Re-run `flutter analyze` + `flutter test`, and exercise the actual path (`flutter run`) for runtime bugs. Report what was run and its result — if a check was skipped, say which and why.

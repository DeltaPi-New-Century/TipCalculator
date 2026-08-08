---
name: sast-audit
description: Security review of TipCalculator — static analysis of entry points (user input, network, API keys, platform config), dependency audit for EOL/obsolete/vulnerable packages, and remediation proposals reviewed before any change. Use for security review, SAST, "check for vulnerabilities", secret handling, dependency/CVE checks, or before a release.
---

# Security Code Quality (SAST)

Static analysis first, then dependencies, then proposals. **Report before you remediate** — never push a security change without the user seeing the finding and choosing a fix.

## 1. Entry-point inventory

Enumerate every place untrusted data enters, then trace each to its sink:

| Entry point | Where | Sink to check |
|---|---|---|
| User text input | `amount_widget.dart`, `people_widget.dart`, `tipping_widget.dart` | parsing, arithmetic, prompt string |
| Gemini API response | `lib/service/gemini.dart` | `jsonDecode`, index chains, UI render |
| ip-api geolocation | `lib/service/geolocation.dart` | country → prompt, UI |
| Remote gist DB | `lib/service/database.dart` (`Config.DB_PATH`) | parsed into schemas, cached to disk |
| Local persistence | `shared_preferences`, `path_provider` | deserialization, trust on read-back |
| Platform config | `android/`, `ios/`, `web/`, `assets/.env` | permissions, cleartext, ATS, secrets |
| CI | `.github/workflows/*.yaml` | secret exposure, action pinning |

## 2. Static checks to run

```bash
flutter analyze                                  # includes security-relevant lints
grep -rnE "AIza|api[_-]?key|secret|token|password|Bearer " lib/ android/ ios/ web/ assets/ .github/
git log --oneline -S "AIza" -- .                 # a key ever committed? history matters
cat .gitignore | grep -i env                     # is assets/.env ignored?
```

Veracode workflows already exist in `.github/workflows/` — read `veracode.yml` before proposing new scanning, and extend it rather than duplicating it.

## 3. Known exposure classes in this codebase

Check each on every audit; each is a real finding until proven otherwise.

- **API key shipped in the client.** `Config.GEMINI_API_KEY` is compiled into the app; `dotenv` + `assets/.env` is *not* a secret store — assets are extractable from the APK/IPA/web bundle. Any Gemini key in a released build must be treated as public. Correct answers are a proxy backend or a restricted/quota-capped key, not obfuscation.
- **Secrets in VCS.** `assets/.env` is declared in `pubspec.yaml` assets. Verify it is git-ignored and that no key exists anywhere in git history.
- **Cleartext HTTP.** `Config.IP_API_URL` is `http://` — MITM can control `country`, which flows into the Gemini prompt and into what the user is told to pay. Use HTTPS.
- **Prompt injection.** `country` and `type` interpolate into the prompt (`gemini.dart:34`). Untrusted geolocation + untrusted user text = attacker-influenced model output rendered as financial advice. Allowlist the values.
- **Unvalidated deserialization.** `responseData['candidates'][0]['content']['parts'][0]['text']` then `jsonDecode` on model output — crash and logic-abuse surface. Validate shape and types.
- **Silent failure.** `.catchError((_) {})` at `gemini.dart:58` hides security-relevant errors (auth failures, tampering, TLS errors) from both user and logs.
- **Remote code-adjacent data.** `Config.DB_PATH` points at a public gist; whoever controls it controls app data. Pin, validate, and fail closed.
- **Platform config.** Android `usesCleartextTraffic`, `android:exported`, `INTERNET`-only permissions; iOS `NSAppTransportSecurity` exceptions; web CSP. Flag any wildcard exception.
- **Logging.** No `print` of responses, keys, or full URLs with query params.

## 4. Dependency audit — EOL / obsolete

```bash
flutter pub outdated                 # current vs upgradable vs latest, per package
flutter pub deps --style=compact     # transitive tree
flutter pub upgrade --dry-run
dart pub global activate pana && pana --no-warning   # optional, per-package health
```

For each direct dependency in `pubspec.yaml` (`http`, `provider`, `language_code`, `path_provider`, `flutter_dotenv`, `cupertino_icons`, `shared_preferences`, `flutter_lints`) report:

| Package | Pinned | Latest | Status | Note |
|---|---|---|---|---|

Status values: `current`, `minor-behind`, `major-behind`, **`EOL`** (discontinued on pub.dev, unmaintained >2y, or replaced by a successor), **`vulnerable`** (known advisory). Check the pub.dev page for the "discontinued"/"replaced by" flag and last-publish date; check GitHub Security Advisories / OSV for the package name. Also flag `environment: sdk: ^3.8.1` if the Dart/Flutter channel itself is out of support.

Call out specifically: `flutter_dotenv` used as a secrets mechanism (misuse, see §3), and the commented-out `google_mobile_ads` — either remove the line or track its version.

## 5. Report format

One line per finding, worst first. No praise, no filler.

```
[SEV] file:line — <vulnerability class>: <what an attacker does>. Impact: <concrete>.
```

Severity: `CRITICAL` (remote compromise / key theft), `HIGH` (data integrity or exploitable path), `MEDIUM` (needs preconditions), `LOW` (hardening), `INFO`. Include CWE where it is unambiguous. State clearly when a finding is theoretical vs reachable in the current code.

## 6. Review, then propose ≥2 remediations

For each `HIGH`+ finding, before touching code:

```
Finding: <id> — <one line>
Reachable: <yes/no, path>
Option A — <mitigation>
  Change: <what, where>
  Residual risk: <what remains>
  Effort: S | M | L   Breaking: yes/no
Option B — <different mitigation, e.g. architectural>
  ...
Recommend: <A|B> — <reason>
```

Options must differ in kind (mitigate at the boundary vs remove the exposure vs move the trust off-device). Apply only what the user approves; re-run `flutter analyze` and the secret grep afterwards and report results.

## 7. Handling a leaked key

If a live key is found in the repo or history, say so plainly and stop: revoking/rotating it in Google AI Studio comes first, before any code change — removing it from the file does not un-leak it, and rewriting git history is destructive and needs explicit user approval.

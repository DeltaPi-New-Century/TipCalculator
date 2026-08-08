---
name: code-quality
description: Enforce Dart/Flutter code quality in TipCalculator — lint compliance (flutter_lints), redundancy removal, input/output sanitization, naming and structure. Always proposes at least 2 improvement options before changing code. Use before commits/PRs, after adding a feature, or when asked to clean up, refactor, or "make this better".
---

# Code Quality

Scope: readability, lint, redundancy, sanitization, structure. **Not** bug hunting (`flutter-debug`) and **not** vulnerabilities (`sast-audit`).

## 1. Baseline commands

```bash
flutter analyze                                   # must be clean, zero issues
dart format .                                     # canonical formatting
dart format --output=none --set-exit-if-changed . # CI check form
flutter pub outdated                              # dependency drift
dart fix --dry-run                                # analyzer-proposed auto fixes
dart fix --apply                                  # only after reviewing the dry run
```

`analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`. Never silence a lint with `// ignore:` to make output clean — fix the code, or justify the ignore in a trailing comment on the same line.

## 2. Lint rules worth enabling here

Propose (do not silently add) additions to `analysis_options.yaml`:

```yaml
linter:
  rules:
    prefer_single_quotes: true
    require_trailing_commas: true
    avoid_print: true              # use debugPrint / a logger
    unawaited_futures: true
    always_declare_return_types: true
    prefer_final_locals: true
    avoid_dynamic_calls: true      # catches responseData['a'][0]['b'] chains
analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore
```

Note: `Config` uses `SCREAMING_CASE` fields, which violates `constant_identifier_names`/`non_constant_identifier_names`. Renaming is API-breaking across `tip_data.dart` — treat it as its own proposal, not a drive-by edit.

## 3. Redundancy checklist

- Duplicated widget subtrees across `amount_widget.dart`, `people_widget.dart`, `tipping_widget.dart`, `total_widget.dart` → extract a shared widget into `lib/components/`.
- Commented-out dead code (`gemini.dart:61-89`, `config.dart:1-18`) → delete; git history is the archive.
- Repeated `jsonDecode` + manual map indexing → one `fromJson` factory per schema in `lib/schemas/`.
- Duplicate HTTP setup → it belongs in `lib/service/network.dart` only.
- Getter/field pairs that only forward (`_minVal` → `minVal`) → collapse to a `final` public field unless the privacy is load-bearing.
- Same string literal in 3+ places → a constant.

## 4. Sanitization

**Inbound (user).** `TextField` amounts and people counts: validate with `int.tryParse`/`double.tryParse`, never `parse` on raw input; clamp ranges (people ≥ 1, amount ≥ 0, finite, not `NaN`); apply `inputFormatters` (`FilteringTextInputFormatter.digitsOnly` or a decimal regex) so bad input cannot be typed; reject before it reaches the model layer.

**Outbound (into the Gemini prompt).** `country` and `type` are interpolated into the prompt at `gemini.dart:34`. Constrain them to a known enum/allowlist and strip newlines and braces — free text there is prompt injection, and it is also what makes the response un-parseable.

**Inbound (API/network).** Every external map access is untrusted: use `is` checks or a typed `fromJson` with defaults, not chained `[]`. Wrap `jsonDecode` of model text in `try/catch (FormatException)`. Never interpolate an API response into a UI string without escaping/limiting length.

**Formatting.** Money and percentages go through `NumberFormat` (`intl`) with the active locale — not string concatenation.

## 5. Propose ≥2 improvements (required)

Never mass-refactor unasked. Report findings, then offer options:

```
Finding: <file:line> — <problem, 1 line>

Option A — <minimal>
  Change: <what>
  Effort: S | M | L   Risk: low | med | high
  Gain:   <lint/redundancy/robustness>
Option B — <structural>
  ...
Recommend: <A|B> — <one-line reason>
```

At minimum one cheap local fix and one structural fix. Apply only the option the user picks; then re-run `flutter analyze` and `flutter test` and report the result.

## 6. Definition of done

- `flutter analyze` → `No issues found!`
- `dart format --set-exit-if-changed .` → exit 0
- `flutter test` passes
- No new `// ignore:` without a same-line justification
- No commented-out code added

---
name: project-docs
description: Write and maintain TipCalculator documentation for both human contributors and AI agents — README, CONTRIBUTING, architecture notes, service docs, ADRs, doc comments. Optimized for easy reading and low maintenance. Use when asked to document, update the README, explain the architecture to newcomers, or after a change that makes existing docs wrong.
---

# Project Documentation

Two audiences, one source. Humans need the *why* and how to get running; agents need exact paths, commands, and constraints. Write once, serve both — no separate "AI version".

## Doc map

| File | Owns | Update when |
|---|---|---|
| `README.md` | What the app is, install, run, build, config | user-facing behaviour or setup changes |
| `CONTRIBUTING.md` | Dev setup, workflow, standards, PR checklist | process or tooling changes |
| `CLAUDE.md` | Agent context: layout, commands, invariants, traps | structure or invariants change |
| `docs/architecture.md` | Layers, data flow, state, external services | a service or dependency is added/removed |
| `docs/adr/NNNN-<slug>.md` | One decision, its context, alternatives, consequences | a non-obvious decision is made |
| Dartdoc `///` | Public class/method contracts | signature or behaviour changes |

Keep it flat. Do not create a `docs/` tree deeper than one level, and do not add a file unless something above cannot hold it.

## Rules for easy reading

1. **Lead with the task**, not the theory: "Run the app" before "Architecture".
2. **Copy-pasteable commands** in fenced blocks, one command per line, no `$` prefix.
3. **Tables** for anything enumerable (env vars, services, commands, layers).
4. **≤4 lines per paragraph.** Split rather than sprawl.
5. **Link to code with paths**: `lib/service/gemini.dart` — not "the Gemini service somewhere".
6. **Say the why.** A doc that only restates the code is the doc that rots first.
7. **Absolute dates** (`2026-08-06`), never "recently" or "currently".
8. **No screenshots of text**, no ASCII art that must be hand-realigned.

## Rules for easy maintenance

- **Single source of truth.** A fact lives in exactly one file; elsewhere link to it. Version numbers come from `pubspec.yaml` — do not restate them in prose.
- **Do not document what code already states.** No file-by-file inventories, no per-parameter tables that duplicate signatures.
- **Doc comments over prose docs** for API contracts — they sit next to the code and move with it.
- **Every doc change ships in the PR that caused it.** A separate "update docs" PR is already a bug.
- **Delete instead of appending "(deprecated)"** — git keeps history.
- **Verify commands before writing them.** Every command in a doc must have been run.

## Contributor onboarding must cover

Prerequisites (Flutter SDK matching `environment: sdk: ^3.8.1`) · clone · `flutter pub get` · config setup (`assets/.env` keys and where to obtain a Google AI Studio key — **never a real key in docs**, only placeholders) · `flutter run -d <device>` · `flutter analyze` · `flutter test` · `dart format .` · branch and commit conventions · PR checklist · where to file issues.

## Agent context (`CLAUDE.md`) must cover

Project layout by directory · the exact command list · invariants (e.g. `Config` is `static final`, read once) · known traps (silent `catchError` in `gemini.dart`, empty API key, cleartext ip-api) · what not to touch (generated files, platform dirs) · which skill to use for which task (`flutter-debug`, `code-quality`, `sast-audit`, `project-docs`, `token-lean`).

## ADR template

```markdown
# NNNN — <decision title>
Date: YYYY-MM-DD · Status: proposed | accepted | superseded by NNNN

## Context
<the forces, 3-5 lines>

## Decision
<what we do, 1-3 lines>

## Alternatives
- <option> — rejected because <reason>

## Consequences
- <what this makes easy / hard / requires later>
```

## Dartdoc style

```dart
/// Requests a tip percentage range for [country] and service [type].
///
/// Returns a [TipPorcentData]. Throws [FormatException] if the model
/// response is not the expected JSON shape.
```

One-line summary, blank comment line, then detail. Document thrown exceptions and null behaviour — those are the parts callers get wrong.

## Before finishing

- Every command in the doc was actually run.
- Every path referenced exists.
- No secret, key, token, or personal path in the text.
- New reader can go from clone to running app using only the doc.

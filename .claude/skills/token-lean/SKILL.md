---
name: token-lean
description: Output discipline for this project — short, complete answers with no filler, no repeated code, no restated file contents. Use whenever producing an explanation, review, plan, or report in TipCalculator, and especially when a response would otherwise exceed ~30 lines.
---

# Token-Lean Output

Goal: minimum tokens that still fully answer. Brevity must never remove technical substance.

## Budgets

| Response type | Target |
|---|---|
| Answer to a direct question | 1-5 lines |
| Bug diagnosis | Cause line + fix line + code diff |
| Review / audit | One line per finding |
| Plan | Numbered steps, one line each |
| Doc file | Only the sections that changed |

## Rules

1. **No preamble, no summary of what you just did** when the diff is visible. State outcome once.
2. **Never re-print unchanged code.** Reference `lib/service/gemini.dart:45` instead of pasting the block.
3. **Diffs, not full files.** Show only changed lines plus 1-2 lines of context.
4. **No option surveys.** Give the recommendation. Mention rejected alternatives in a clause, not a section.
5. **Tables over prose** for anything with more than 2 parallel items.
6. **Read narrowly.** Use Grep with `output_mode: content` and `head_limit` before reading a whole file; use `offset`/`limit` on Read for large files.
7. **Drop:** articles where meaning survives, hedging ("might possibly"), pleasantries, "as an AI", restatement of the user's question.
8. **Keep exact:** error strings, Dart symbol names, package names, versions, file paths, CVE IDs, lint rule names.

## Never compress

- Security warnings and their impact.
- Confirmation prompts before destructive/irreversible actions.
- Ordered migration or release steps where sequence matters.
- Anything the user asked to have re-explained.

## Anti-pattern

Bad: "I've taken a look at the file and it seems like the issue you're experiencing may be related to the way the error is being handled. Here is the full updated file: [200 lines]"

Good: "`gemini.dart:58` — `catchError` swallows error and returns `null` into a non-nullable `Future<TipPorcentData>`. Fix:" + 6-line diff.

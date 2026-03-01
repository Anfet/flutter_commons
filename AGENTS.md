# AGENTS

This file defines project-specific agents and how we use them while developing `flutter_commons`.

## Purpose

- Keep repetitive engineering workflows consistent
- Speed up reviews and maintenance
- Build shared checklists that grow over time

## Documentation Language

- All project documentation must be written in English.
- Applies to `README.md`, `CHANGELOG.md`, `AGENTS.md`, and files under `docs/`.
- If source comments or notes are added for users/contributors, prefer English by default.

## Agent registry

### `widget-reviewer`

Focus:
- Widget lifecycle (`initState`, `didUpdateWidget`, `dispose`)
- Animation/controller safety
- Runtime UI regressions
- Semantics/accessibility basics

Input:
- Changed files under `lib/src/widgets`

Output:
- Prioritized findings (`high`/`medium`/`low`)
- Suggested fixes with concrete file paths and lines

---

### `api-guardian`

Focus:
- Public API compatibility
- Deprecations and migration paths
- Naming and consistency of exported symbols

Input:
- Changes in `lib/flutter_commons.dart` and exported `lib/src/**`

Output:
- Breaking change warnings
- Suggested migration notes for consumers

---

### `quality-gate`

Focus:
- Analyzer warnings/errors
- Test health and missing coverage
- Release readiness checklist

Input:
- Whole repository

Output:
- Pass/fail checklist before merge/release

## Default workflow

1. Run `widget-reviewer` for widget-related changes.
2. Run `api-guardian` if public exports changed.
3. Run `quality-gate` before merge.

## Checklist templates

### Widget change checklist

- [ ] Lifecycle handling is safe when props change dynamically
- [ ] Async callbacks check `mounted` where required
- [ ] Controllers/listeners are attached and detached correctly
- [ ] Visual behavior covered by at least one widget test

### Release checklist

- [ ] `flutter analyze` run
- [ ] `flutter test` run
- [ ] Changelog updated if behavior changed

## Notes

- This is a living document; append conventions instead of rewriting from scratch.
- When a recurring bug pattern appears, add a checklist item here.

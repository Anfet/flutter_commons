# flutter_commons

Core Flutter package with reusable widgets, utils, extensions, and UI infrastructure.

## Status

- Type: internal package (`publish_to: none`)
- Dart SDK: `>=3.10.0 <4.0.0`
- CI: Flutter `3.38.10` on the stable channel (Dart 3.10.x)
- Main entrypoint: `lib/flutter_commons.dart`

## Project goals

- Reuse common UI and utility code across apps
- Keep business projects thinner and easier to maintain
- Provide stable primitives for widgets, data/state wrappers, and helpers

## Package structure

- `lib/src/widgets` - reusable widgets and UI primitives
- `lib/src/ui` - bloc-oriented UI base classes and mixins
- `lib/src/utils` - async/control-flow and infrastructure helpers
- `lib/src/extensions` - extension methods for Dart/Flutter types
- `lib/src/data` - value wrappers and data primitives
- `lib/src/storage` - persistent property abstractions
- `lib/src/theming` - theming helpers
- `test` - discovered unit and widget tests (`*_test.dart`)
- `lib/lints.yaml` - analysis options that enable the analyzer plugin in a consuming project
- `flutter_commons_lints` - analyzer plugin with Bloc and `WaitableEvent` rules (a separate Dart package)

## Quick start

```dart
import 'package:flutter_commons/flutter_commons.dart';
```

### Mutex example

```dart
final mutex = Mutex();
await mutex.lock(() async {
  // critical section
});
```

### PagedLoader example

```dart
final loader = PagedLoader<String, void>(
  itemsPerPage: 20,
  onDemand: (page, perPage, [arguments]) async => fetchItems(page, perPage),
);

await loader.loadPage();
final items = loader.items;
```

## Analyzer plugin

The `flutter_commons_lints` plugin reports Bloc and `WaitableEvent` mistakes
that otherwise surface only at runtime: a missing `on<OnInit>`, unhandled
events of a sealed event type, a `WaitableEvent` handler that never completes
the event, and more. Enable it in the consuming project's
`analysis_options.yaml` with one line:

```yaml
include:
  - package:flutter_lints/flutter.yaml
  - package:flutter_commons/lints.yaml
```

No path is needed: the plugin ships in this repository and its version always
matches the `flutter_commons` version the project depends on. Diagnostics are
shown in the IDE and by `dart analyze`; `flutter analyze` does not report them.
See `flutter_commons_lints/README.md` for the rules, suppression and
limitations.

## Local development

- Analyze: `flutter analyze`; plugin diagnostics: `dart analyze`
- Run tests: `flutter test`
- Plugin tests: `dart test` in `flutter_commons_lints`
- Outdated deps: `flutter pub outdated`

Note: Flutter discovers only files matching `*_test.dart`; all retained tests use
matcher assertions rather than VM `assert` statements.

## Current priorities

- Stabilize widget lifecycle behavior
- Improve test coverage for animation and interaction widgets
- Remove deprecated API usages

## Backlog template

Use this section to append tasks gradually.

- [ ] Add widget tests for `SlidingWidget`, `RevealingWidget`
- [ ] Document each public widget with usage snippet

## Contribution notes

- Keep APIs backward-compatible when possible
- Prefer small, focused PRs
- Run `flutter analyze` before opening PR

## License

See `LICENSE`.

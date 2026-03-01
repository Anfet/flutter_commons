# flutter_commons

Core Flutter package with reusable widgets, utils, extensions, and UI infrastructure.

## Status

- Type: internal package (`publish_to: none`)
- Dart SDK: `>=3.10.0 <4.0.0`
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
- `test` - tests (currently minimal)

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

## Local development

- Analyze: `flutter analyze`
- Run tests: `flutter test`
- Outdated deps: `flutter pub outdated`

Note: Flutter discovers only files matching `*_test.dart`.

## Current priorities

- Stabilize widget lifecycle behavior
- Improve test coverage for animation and interaction widgets
- Remove deprecated API usages

## Backlog template

Use this section to append tasks gradually.

- [ ] Add widget tests for `SlidingWidget`, `CollapsibleWidget`, `RevealingWidget`
- [ ] Add semantics coverage for keyboard/buttons
- [ ] Document each public widget with usage snippet

## Contribution notes

- Keep APIs backward-compatible when possible
- Prefer small, focused PRs
- Run `flutter analyze` before opening PR

## License

See `LICENSE`.

## Documentation

- Project docs index: `docs/README.md`

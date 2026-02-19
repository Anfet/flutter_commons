# flutter_commons

Core shared Flutter package with reusable utilities, UI primitives, data models, extensions, and lightweight infrastructure helpers.

## What is included

- UI helpers and widgets (`SlidingButton`, digit keyboard, animation wrappers, spacers)
- BLoC-oriented UI base classes and mixins
- Utility abstractions (`Mutex`, `QueryScheduler`, `PagedLoader`)
- Data wrappers (`Loadable`, `Maybe`, `Range`, `Pair`, etc.)
- Storage properties for primitive and JSON values
- Extension methods for common Dart/Flutter types
- Theming and routing helpers

## Installation

Internal package (currently `publish_to: none`), add as a dependency from your mono-repo or git source.

```yaml
dependencies:
  flutter_commons:
    git:
      url: https://github.com/Anfet/flutter_commons.git
      ref: release/1.0.27
```

## Quick start

Import the main entrypoint:

```dart
import 'package:flutter_commons/flutter_commons.dart';
```

### `Mutex` example

```dart
final mutex = Mutex();

await mutex.lock(() async {
  // critical section
});
```

### `PagedLoader` example

```dart
final loader = PagedLoader<String>(
  itemsPerPage: 20,
  onDemand: (page, perPage) async => fetchItems(page, perPage),
);

await loader.loadNextPage();
final currentItems = loader.items;
```

### `QueryScheduler` example

```dart
final scheduler = QueryScheduler();

final request = scheduler.get<String>(
  () async => loadData(),
  priority: QueryPriority.normal,
  tag: 'profile',
);

final value = await request;
```

## Development

- Run analyzer: `dart analyze`
- Run tests: `flutter test`

Note: test files must follow `*_test.dart` naming to be discovered by Flutter test runner.

## License

See `LICENSE`.

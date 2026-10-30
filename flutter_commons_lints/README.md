# flutter_commons_lints

Analyzer plugin for projects built on `flutter_commons`. It reports Bloc and
`WaitableEvent` mistakes that otherwise surface only at runtime, and offers
quick fixes for two of them.

## Enabling

A project that depends on `flutter_commons` (git or path dependency) includes
the options file shipped with the package:

```yaml
include:
  - package:flutter_lints/flutter.yaml
  - package:flutter_commons/lints.yaml
```

`lib/lints.yaml` declares the plugin with a path relative to itself, so the
project needs no path of its own, and the plugin version always matches the
`flutter_commons` version in `pubspec.lock`. Restart the Dart analysis server
after adding the include or changing the `flutter_commons` version.

All rules are warnings and are active as soon as the file is included.

Diagnostics are shown in the IDE and by `dart analyze`. As of Flutter 3.44,
`flutter analyze` does not report plugin diagnostics; use `dart analyze` in CI.

### Suppressing

- One occurrence: `// ignore: flutter_commons_lints/<rule_name>` on the line
  above.
- A whole file: `// ignore_for_file: flutter_commons_lints/<rule_name>`.

A rule cannot be turned off for the whole project through the include:
`plugins: flutter_commons_lints: diagnostics:` without a `path` is ignored, and
`analyzer: errors:` does not recognize plugin codes. Turning a rule off
project-wide needs a full plugin entry with its own `path` instead of the
include, which suits only path dependencies.

## Rules

| Rule | Reports | Quick fix |
| --- | --- | --- |
| `bloc_missing_on_init` | A concrete direct `Bloc` subclass with `BlocEvent` events that does not register `on<OnInit>`. | Registers `on<OnInit>(onInit)` and adds an empty `onInit` handler after the constructor. |
| `bloc_widget_without_init_event` | A `BlocWidgetState` that creates (`onCreateBloc`) a Bloc whose event type cannot accept `OnInit` and does not override `onInitializationEvent`. | — |
| `bloc_unhandled_event` | A direct `Bloc` subclass whose event type is `sealed` and some concrete event has no `on<...>` registration, directly or through a parent type. | Registers `on<Event>(onEvent)` and adds an empty handler for every listed event. |
| `waitable_complete_without_result` | `complete()` without a result on a `WaitableEvent<T>` with a non-nullable `T`. | — |
| `waitable_event_not_completed` | A handler of a `WaitableEvent` that never calls `complete` or `fail` on the event. | — |
| `add_and_wait_non_waitable` | A directly constructed non-waitable event passed to `addAndWait`. | — |

### Limits

- `add_and_wait_non_waitable` checks generative constructor calls; variables and factory constructors may return a waitable subtype.
- Registrations are read from the constructors of the Bloc itself. A Bloc
  extending another custom Bloc is not checked by `bloc_missing_on_init` and
  `bloc_unhandled_event`, because its base may register the handlers.
- `waitable_event_not_completed` checks the handler body only. When the event
  is passed anywhere else (another method, a field, a collection), it is
  assumed to be completed there. A Bloc with `AutoCloseWaitableEvents` is not
  reported for events whose result type is `void` or nullable.

## Development

```sh
dart pub get
dart analyze
dart test
```

Rules are tested with `analyzer_testing` against minimal `bloc` and
`flutter_commons` stubs in `test/rule_test_base.dart`; keep the stubs in sync
with the members the rules inspect.

# flutter_commons_lints

Analyzer plugin for projects built on `flutter_commons`. It reports Bloc and
`WaitableEvent` mistakes that otherwise surface only at runtime, and offers
quick fixes for two of them.

## Enabling

Add the plugin to the project's `analysis_options.yaml`. The path is relative
to that file:

```yaml
plugins:
  flutter_commons_lints:
    path: ../siberian_core/flutter_commons_lints
```

Restart the Dart analysis server after changing the `plugins` section. All
rules are warnings and are enabled as soon as the plugin is listed. A single
rule is turned off under `diagnostics`:

```yaml
plugins:
  flutter_commons_lints:
    path: ../siberian_core/flutter_commons_lints
    diagnostics:
      waitable_event_not_completed: false
```

Suppress one occurrence with
`// ignore: flutter_commons_lints/<rule_name>`.

Diagnostics are shown in the IDE and by `dart analyze`. As of Flutter 3.44,
`flutter analyze` does not report plugin diagnostics; use `dart analyze` in CI.

## Rules

| Rule | Reports | Quick fix |
| --- | --- | --- |
| `bloc_missing_on_init` | A concrete direct `Bloc` subclass with `BlocEvent` events that does not register `on<OnInit>`. | Registers `on<OnInit>(onInit)` and adds an empty `onInit` handler after the constructor. |
| `bloc_widget_without_init_event` | A `BlocWidgetState` that creates (`onCreateBloc`) a Bloc whose event type cannot accept `OnInit` and does not override `onInitializationEvent`. | — |
| `bloc_unhandled_event` | A direct `Bloc` subclass whose event type is `sealed` and some concrete event has no `on<...>` registration, directly or through a parent type. | Registers `on<Event>(onEvent)` and adds an empty handler for every listed event. |
| `waitable_complete_without_result` | `complete()` without a result on a `WaitableEvent<T>` with a non-nullable `T`. | — |
| `waitable_event_not_completed` | A handler of a `WaitableEvent` that never calls `complete` or `fail` on the event. | — |

### Limits

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

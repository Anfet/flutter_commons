## Unreleased

### Extensions fixes

- `String.toDouble` defaults to `0.0` (was `0.9`). `String.reversed` works on grapheme clusters.
- `DoubleExt.truncFraction` no longer loses a digit to float error (`0.29` stays `0.29`), which also fixes
  `NumericUtils.calculateEnteredQuantity`. `isInt` accepts error below an integer and is `false` for NaN and infinity.
- `maxOf`, `minOf` and `sumOf` apply `test` to numeric elements too, and throw `ArgumentError` for non-numeric
  elements without `test`. `randomElement` and `takeRandom` throw `StateError` on an empty collection.
- `randomLightColor` keeps every channel light.
- `DateTime`: `weeksInMonth`, `startOfTheWeek` and `endOfTheMonth` are daylight-saving safe; `addMonths` and `nextMonth`
  clamp the day to the target month and keep the time of day (and UTC); `nextDay` keeps the time of day; `endOfTheDay`
  is `23:59:59.999`.
- `Map.join` skips `null` values unless `addEmptyValues` is set. `Duration / 0` throws `ArgumentError`.
- `scheduleOnNextFrame` skips the callback once the state is unmounted and requests a frame. `BuildContext.size`,
  `padding`, `viewInsets` and `viewPaddings` subscribe only to their own `MediaQuery` aspect.
- Removed `ListExt.map` and the `Duration` `+`, `-`, `*` extension operators: the built-in members always won, so they
  were never called.

### Widgets

- `InkButton` gained `decoration`, `clipBehavior` and `foregroundInk`. A
  `decoration` (gradient, image, outline, shadow) is painted below the ink, so
  the splash stays visible without nesting `Material`, `Ink` and `InkWell` by
  hand; when no `customBorder` or `border` is given, the clip and ink shape are
  taken from it. `clipBehavior` defaults to the previous `Clip.hardEdge`.
  `foregroundInk` paints the splash above an opaque child. `Padding` is no
  longer inserted when `padding` is null. The change is API-compatible.

### Listenables and Bloc helpers

- `mapValue` chains no longer leak: `MappedValueListenable` listens to its
  source only while it has listeners, so a chain is released once nobody
  listens to its tail, even without `dispose()`. The mapper now runs lazily
  (first read or listener) instead of in the constructor; while detached,
  `value` is computed from the source on every read.
- New `mapValueAsync` / `AsyncMappedValueListenable` maps a `ValueListenable`
  through an asynchronous mapper into a `ValueListenable<Loadable<Y>>`. Only
  the result for the latest source value is applied.
- New `CancellableRegistry` holds the shared registration logic of
  `BlocListenables` and `StateListenable` and can be used by other owners.
  Both mixins gained `own()` to dispose a notifier with the owner.
- `onStreamChange`, `onValueChanged` and `onAnyChange` accept `onError`.
  `onValueChanged` and `onAnyChange` accept `delivery:
  ListenableDelivery.latest`, which collapses notifications queued behind a
  slow mapper to the newest one.
- `onAnyChange` and `NotifierCancellable` accept any `Listenable` instead of
  `ChangeNotifier`; `NotifierCancellable.notifier` is now typed `Listenable`.
- **Breaking:** `addAndWait` takes a `WaitableEvent<T>`, so passing an event
  without `WaitableEvent` is a compile-time error and `T` is inferred from the
  event. Callers that pass a variable typed as the Bloc's base event must use
  the concrete event type. An event of another Bloc fails with
  `IllegalArgumentException`.
- `WaitableEvent.complete()` without a result for a non-nullable `T` now fails
  the wait with `ArgumentError` instead of throwing inside the handler and
  leaving the caller waiting.
- New `AutoCloseWaitableEvents` Bloc mixin finishes a wait its handler left
  pending: with the handler's error, with `null` for a `void`/nullable result,
  or with a `StateError` otherwise. Completing an event after its handler
  returned is not supported with this mixin.
- `debounce`, `debounceRestartable` and `throttle` fail the waitable events
  they drop with `StaleWaitEventException.dropped()` instead of leaving
  `addAndWait` waiting. Custom dropping transformers can do the same through
  `failDroppedWaitableEvent`; `DebounceStreamTransformer` and
  `ThrottleStreamTransformer` gained `onDropped`.
- New `debounceRestartable` event transformer: a newer debounced event cancels
  the handler of the previous one.
- `BlocLogging.onEvent` takes the typed event.

### Analyzer plugin

- New `flutter_commons_lints` analyzer plugin in this repository reports a
  missing `on<OnInit>`, a `BlocWidgetState` without an initial event for a
  narrowly typed Bloc, unhandled events of a sealed event type, `complete()`
  without a required result, and `WaitableEvent` handlers that never complete
  the event. Quick fixes add the missing `onInit` and event handlers. See
  `flutter_commons_lints/README.md`; diagnostics are shown by `dart analyze`
  and the IDE, not by `flutter analyze`.
- Consuming projects enable the plugin with
  `include: package:flutter_commons/lints.yaml`; no plugin path is needed.

## 1.1.34+0 - 2026-09-11

### Widgets

- `SlidingButton` gained an optional `onProgressChanged` callback reporting
  slider progress (`0..1`). It fires for drag, internal animations and
  accessibility activation alike, only when the value actually changes, and is
  reported before `onSuccess` starts so consumers observe the final `1.0`. The
  initial `value` applied during `initState` does not trigger it, so progress
  driven effects such as haptics do not fire on mount. The addition is
  API-compatible for existing consumers.

## 1.1.32+0 - 2026-09-06

This private compatibility release keeps the existing public API while restoring
the intended no-breaking behavior of storage and asynchronous helpers.

### Storage and data

- `RevertableProperty.delete()` again stages deletion until `commit()`. Calling
  `revert()` cancels both a staged deletion and a staged value change, and the
  committed value remains available while the deletion is pending.
- Deletion commits reload custom child properties through `getValue()` and
  preserve drafts changed or reverted while deletion or its reload is pending.
  Failed deletion commits remain retryable without discarding newer drafts.
- Built-in stored properties now use their configured defaults when persisted
  values are malformed, and emit a diagnostic log instead of throwing. JSON
  properties also repair their persisted value with the fallback; storage I/O
  failures remain observable.
- `FileStorage` accepts safe nested relative names, rejects traversal and
  absolute-path forms, treats an empty name as absent (`get` returns `''`,
  `exists` returns `false`), preserves missing-file errors for non-empty
  reads, and ignores only missing-target errors during deletion/clear.
- Existing custom `StorableProperty` subclasses remain supported. `FinalValue`
  can now distinguish an unset value from an explicitly set `null`, and `Lazy`
  caches a successfully produced `null` instead of invoking its initializer
  repeatedly.
- `Loadable.copyWith` can preserve or explicitly clear nullable fields, and
  clearing an error also clears its stack trace.

### Asynchronous utilities

- `Cancellable` pipelines now expose `cancelAndWait()` for deterministic
  cleanup, report mapper errors safely, and close derived subscriptions and
  BLoCs without late callbacks after disposal.
- Naturally completed stream registrations now release owner tracking, and
  registrations created during or after State disposal or BLoC close are
  cancelled immediately without invoking their queued callbacks.
- `PagedLoader` keeps only successful pages, maintains deterministic page order,
  ignores stale requests after `clear()` or `dispose()`, and permits explicit
  refresh of an historical page after the end of the list was reached.
- `QueryScheduler` now completes dropped in-flight requests, prevents terminal
  requests from being retried, and handles retry failures deterministically.
  `Mutex` isolates waiter failures while preserving serialized execution.
- `Future.atLeast` now waits only for the remaining minimum duration. List,
  numeric, range, and formatter helpers validate invalid counts and can be
  reused safely without retaining parser state.
- Debounce and throttle transformers handle re-entrant delivery, cancellation,
  independent broadcast listeners, and paused output subscriptions safely.

### Widgets and accessibility

- `PinCode` now exposes safe label, hint, focus, enabled, and entered-progress
  semantics with an optional progress builder; PIN digits remain excluded from
  the accessibility tree. Keyboard controls and controller state stay in sync.
- `SlidingButton` supports the same confirmation flow for accessibility
  activation as for a completed drag, reports `onSuccess` failures, prevents
  repeated success callbacks, and cleans up pointer and animation state when
  disabled or disposed.
- `Flashing` ignores stale initial callbacks after a same-frame cancellation
  while preserving completion callbacks for flashes already in progress.
- `SlidingWidget` now cancels delayed starts when updated or disposed and
  releases replaced curve animations during orientation and curve changes.
- `CollapsibleWidget` now resumes an incomplete expansion or collapse after
  keyed reparenting instead of remaining frozen at an intermediate size.
- Keyboard visibility percentages are recalculated after window resizing.
  `KeyboardVisibilityBuilder` now forwards its public child for child-only
  rendering and stable child subtrees across visibility updates.
  Legacy widget lifecycle transitions and disabled-control semantics are safer.
- `InkButton` exposes the relevant `InkWell` customization options, and
  `HoveredDecorator` supports shape, clipping, and interactive hover scaling.

### Images, layout, and text

- Image providers now honor the decoder contract, dispose codecs after frame
  extraction, dispose recorded `Picture` objects, and provide stable Base64
  cache keys.
- Added tight `TextUtils` paragraph measurements with line-count and truncation
  information, plus optical-size support for `TextStyle` weight helpers.
  `MountedCheck`, `BlocWidget`, and waitable events now preserve lifecycle and
  generic-result safety, including deterministic timeout/closure completion.
- Repeated text enrichment and existing range/formatter edge cases now have
  deterministic behavior.

### SDK and quality gates

- The supported Dart baseline is `>=3.10.0 <4.0.0`.
- CI now checks formatting, whitespace, analysis, tests, coverage, a minimal
  web consumer build, package archive validation, and tracked credential
  material. The package remains private (`publish_to: none`).

## 1.0.30+0 - 2026-08-31

- Added `InkButton` optional `border` parameter. `InkButton` clips to `Clip.hardEdge`, so a border drawn by wrapping it in a decorated container is shaved off at the corners, and the wrapper has to repeat `borderRadius` and keep the two in sync by hand. Passing a `BorderSide` now builds a `RoundedRectangleBorder` shape that paints and clips the outline together. Existing call sites are unaffected: without a `border` the widget still uses `borderRadius` exactly as before.

## 1.0.29+0 - 2026-08-21

- Added `HoveredDecorator` optional `scale` parameter, folding the portal-local `HoverScale` widget's scale-on-hover behavior into `HoveredDecorator` so a single widget covers both decoration-swap and scale hover effects.

## 1.0.28+0 - 2026-03-01

### Breaking Changes

- `AppearingWidget` API changed:
  - Removed `show` parameter.
  - Visibility is now derived from `child`:
    - `child != null` -> appear
    - `child == null` -> hide with animation, then clear
- Added optional `sizeCurve` and `opacityCurve` for animation customization.
- `Flashing` API changed:
  - Removed `flashReaction`.
  - Added edge-trigger boolean `flash` (`false -> true` starts animation).
  - Added optional `onFlashed` callback to signal animation completion.
- `ScrollFocusable` API changed:
  - Renamed `isFocused` to `focus` (edge-triggered: `false -> true` runs focus).
  - Added `delay`, `curve`, `alignment`, `alignmentPolicy`, and `onFocused`.
  - Removed internal `ShotReaction`-based trigger mechanism.
- Removed external `flutter_logger` dependency and export.
  - Logging API is now provided by local `src/logging.dart` (`logMessage`).

### Changes

- Added `RangeJoiner` for merging bounded ranges with a custom comparator callback.
- `SlidingButton` improvements:
  - Added guard against `onSuccess` re-entry while previous callback is pending.
  - Added semantics defaults (`label`, `hint`, progress `value`) and API for custom semantics text.
  - Added corrected default names:
    - `kDefaultThumbElevation`
    - `defaultTrackBackgroundColorBuilder`
    - `defaultThumbBackgroundColorBuilder`
  - Kept previous typo-named statics as deprecated aliases for compatibility.
- `PagedLoader` improvements:
  - Fixed `nextPageToBeLoaded` progression to load subsequent pages instead of repeating current page.
  - Kept aggregated `items` deterministic by page order even when explicit pages are loaded out of order.
  - Guarded stream emission after `dispose()` to avoid adding events to a closed controller.

## 1.0.27+0 - 2026-02-19

- Fixed critical recursive getter in `Maybe.v`.
- Fixed critical recursive getter in `GlobalKeyExt.requireContext`.
- Fixed `QueryScheduler.drop()` to preserve queue structure and complete cancelled requests with error.
- Fixed `PagedLoader` to keep `itemsNotifier` synchronized after page load and error paths.
- Added `bloc` dependency alignment with exported `package:bloc/bloc.dart`.

## 1.0.26+2

- Previous internal release.

## 0.0.1

- Initial package scaffold.

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

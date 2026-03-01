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

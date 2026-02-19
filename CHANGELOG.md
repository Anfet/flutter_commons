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

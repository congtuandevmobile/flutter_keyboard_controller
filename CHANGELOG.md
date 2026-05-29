## v1.0.1

### Android — Critical fix: keyboard-type switch height tracking

- **Root cause**: `WindowInsetsAnimationCompat.Callback` only fires during animated transitions. On Samsung and other Android devices, switching keyboard type (e.g. text → number) triggers a _static layout pass_ with no animation — `onProgress`/`onEnd` are never called, leaving `heightNotifier` stuck at the old keyboard height. The toolbar and auto-scroll would appear mispositioned after the switch.

- **Fix**: Added `setOnApplyWindowInsetsListener` as a safety-net listener alongside the animation callback. It fires on _every_ inset change regardless of animation, ensuring `heightNotifier` is always up to date. The `isAnimating` flag prevents duplicate events when both listeners fire for the same transition.

### Android — Toolbar positioning: `Positioned` inside `ValueListenableBuilder` inside `Stack`

- **Root cause**: Returning a `Positioned` widget from inside a `ValueListenableBuilder.builder` that is itself a child of `Stack` causes undefined layout on Android — `Positioned` must be a **direct** child of `Stack`'s render tree to receive `StackParentData`.

- **Fix**: Changed to `Positioned.fill(child: VLB(...))` with `Align + Padding(bottom: kbH)` inside the builder — the same pattern used by `KeyboardStickyView`. No more black screen or layout artifacts on Android.

### Android — Toolbar type-switch flicker: `pendingHide` lambda capture

- **Root cause**: The deferred `didHide` suppression used a `Runnable` (captured by value). `cancelPendingHide()` set `pendingHideRunnable = null` but the already-queued `Runnable` still ran and emitted `keyboardDidHide`, causing `heightNotifier` to reset and the toolbar to flicker.

- **Fix**: Changed `pendingHideRunnable: Runnable?` to a Kotlin lambda variable `pendingHide: (() -> Unit)?`. The `decorView.post {}` closure captures `pendingHide` **by reference** — after `cancelPendingHide()` sets it to `null`, `pendingHide?.invoke()` is safely skipped.

### Architecture: `KeyboardGeometryService`

- Extracted Element Tree traversal (`visitAncestorElements`) and scroll-offset math (`RenderBox.localToGlobal`) from `_KeyboardAwareScrollViewState` into `lib/src/services/KeyboardGeometryService`.
- `KeyboardAwareScrollView` is now a thin UI layer; geometry logic is independently unit-testable without rendering a widget tree.

### `KeyboardAwareScrollView` — replaced `Future.delayed` with `addPostFrameCallback`

- Removed the arbitrary `focusScrollDelay` (previously 120 ms) in favour of `WidgetsBinding.instance.addPostFrameCallback`.
- `_scrollGeneration` counter still cancels stale callbacks from rapid taps.
- `_isDismissing` + `ModalRoute.isCurrent` guard still blocks scroll when a bottom sheet opens.
- Android's new `setOnApplyWindowInsetsListener` sets `_isDismissing` promptly so the single-frame (≈ 16 ms) window is sufficient on all devices.

### API cleanup (non-breaking)

- Removed `focusScrollDelay` parameter from `KeyboardAwareScrollView` — was no longer used after the `addPostFrameCallback` migration. Parameter was never mentioned in guides; removal has no user impact.
- Removed private dead code `_resolveScrollContextLegacy` from `_KeyboardAwareScrollViewState`.

### `KeyboardToolbar` new features

- `actions: List<KeyboardToolbarAction>` — custom icon buttons with optional selected-state circle highlight.
- `margin` / `borderRadius` — floating pill style above keyboard.
- `KeyboardDismissBehavior` in `KeyboardToolbarScaffold` no longer requires `resizeToAvoidBottomInset: true`; uses `KeyboardStickyView` via `Stack + Positioned.fill` when `false`.
- `toolbarScrollClearance` — auto-injects extra scroll padding into nested `KeyboardAwareScrollView` via `KeyboardToolbarInset` `InheritedWidget`.

### `KeyboardChatScrollView` — fix `whenAtEnd` mode missing rebuild

- `_onScroll` now calls `setState` when `_wasAtEnd` changes so `_liftPaddingFor` re-evaluates correctly while keyboard is already visible.

### README

- Added visual preview table (GIFs).
- Added `KeyboardGeometryService` and Android two-layer tracking architecture notes.
- Replaced "2 large vs 18 micro rebuilds" with O(N) vs O(1) notation.
- Added `KeyboardScrollBoundary` usage in the main `KeyboardAwareScrollView` code example.
- Added `KeyboardProvider` placement warning (must wrap `MaterialApp`, not `Scaffold`).
- Added `height` behavior `RenderBox` tight-vs-loose constraint explanation.

---

## v1.0.0

### Breaking change

- `KeyboardProvider` now accepts `dismissBehavior` parameter — defaults to `KeyboardDismissBehavior.manual` (no change in existing behavior).

### New feature

- **`KeyboardDismissBehavior`** enum added to `KeyboardProvider`:
  - `manual` — keyboard never auto-dismissed (default, backward-compatible)
  - `onTap` — dismiss when user taps anywhere outside a focused input
  - `onDrag` — dismiss when user starts scrolling
  - `onTapAndDrag` — dismiss on both tap and scroll

## v0.0.4

- Fix: Remove Package.swift on iOS

## v0.0.3

### Update README

- Rewrote intro — removed inaccurate claim about `MediaQuery.viewInsetsOf`, replaced with accurate description of targeted rebuild advantage
- Updated comparison table: `MediaQuery.viewInsetsOf` vs library, removed misleading rows, added real differentiators (rebuild scope, progress 0→1, event types, interactive dismiss, `setInputMode`, `preload`)
- Updated installation version to `^0.0.2`

---

## v0.0.2

### Update README

- Added full parameter tables for all widgets with defaults
- Added `KeyboardProvider` dedicated section
- Added `FocusedInputLayout`, `FocusedInputTextChangedEvent`, `FocusedInputSelectionChangedEvent` documentation
- Added `KeyboardEventType.interactive` to event reference
- Added `KeyboardControllerScope` method table
- Added `AndroidSoftInputMode` behavior explanation
- Added `KeyboardAwareScrollView` full params + fallback note
- Added `KeyboardAvoidingView.enabled` param + layout-stability explanation
- Added `KeyboardChatScrollView.onEndVisible` + `safeAreaBottom` documentation
- Added `KeyboardAnimation` event listening example

---

## v0.0.1

### Initial release

- **KeyboardProvider** — root widget that tracks keyboard state via native platform channels. Wraps your app once; all descendants get access to live keyboard data.
- **KeyboardAnimation** — exposes `heightNotifier`, `progressNotifier`, and `isVisibleNotifier` as `ValueNotifier`s for efficient, targeted rebuilds.
- **KeyboardController** — static API to dismiss keyboard, query visibility, and set Android soft-input mode.
- **KeyboardChatScrollView** — chat-optimised scroll view with four lift behaviours: `always`, `whenAtEnd`, `persistent`, `never`.
- **KeyboardStickyView** — sticks any widget to the top of the keyboard and animates it frame-by-frame.
- **KeyboardToolbar** — Prev / Next / Done toolbar above the keyboard with customisable labels, arrow colour, and Done colour.
- **KeyboardToolbarScaffold** — convenience scaffold that wires up `KeyboardToolbar` with a single line.
- **KeyboardAwareScrollView** — auto-scrolls to keep the focused `TextField` visible as the keyboard opens.
- **KeyboardAvoidingView** — lightweight alternative to Flutter's `resizeToAvoidBottomInset` for fine-grained control.
- iOS: frame-accurate keyboard tracking via `CADisplayLink` with easing-curve interpolation.
- Android: frame-accurate tracking via `WindowInsetsAnimationCompat`.
- Android: `setInputMode` / `setDefaultMode` support.

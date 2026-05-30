## v1.0.3

### Performance — iOS: zero-allocation event emission

- **Before**: `emit()` created a new `[String: Any]` dictionary literal on every call — 60 heap allocations per second during keyboard animation (CADisplayLink ticks at 60 fps).
- **After**: Pre-allocated `reusableEvent` dictionary is mutated in-place each call. `FlutterEventSink` serializes synchronously on the main thread before the next tick, so there is no data-race risk. Result: 0 allocations per frame during animation.

### Performance — Android: cached display density

- **Before**: `decorView.resources.displayMetrics.density` was read in `onStart`, `onProgress` (called 60× per second), and `onEnd` — three redundant property traversals per animation that always return the same value.
- **After**: `density` is captured once in `onPrepare` (fires before the animation begins) and reused across all three callbacks. Display density never changes mid-animation.

### Performance — Dart: `KeyboardGeometryService` context cache + type check

- **Expando cache**: `resolveTargetContext` previously walked the element-tree ancestor chain on every scroll trigger for every focus change. Results are now cached per `FocusNode` in a weak-keyed `Expando` — subsequent calls for the same focused field return in O(1) without traversal. Cache entries are invalidated automatically when the `FocusNode` is garbage-collected or its context is unmounted.

- **`is TextField` instead of `toString()`**: The plain-`TextField` ancestor check was `element.widget.runtimeType.toString() == 'TextField'`, which allocates a `String` object per element during traversal. Replaced with `element.widget is TextField` (direct vtable type check, zero allocation) after adding a non-circular `package:flutter/material.dart` import for `TextField` only.

---

## v1.0.2

### Android — Critical fix: `onStart` always fired `willShow` regardless of direction

- **Root cause**: `bounds.upperBound.bottom` in `WindowInsetsAnimationCompat.Callback.onStart` is the _maximum amplitude_ of the animation — it always equals the keyboard height regardless of whether the keyboard is opening or closing. The original `endHeight = bounds.upperBound.bottom; isShowing = endHeight > 0` evaluated to `true` unconditionally. As a result `keyboardWillShow` was emitted even during dismiss, so `_isDismissing` was never set to `true` in `KeyboardAwareScrollView` and the overscroll-clamp was always bypassed when pressing Done.

- **Fix**: Read the target inset via `ViewCompat.getRootWindowInsets(decorView)?.getInsets(WindowInsetsCompat.Type.ime())?.bottom` in `onStart`. Android completes a layout pass to the _target state_ before `onStart` fires, so this value is always accurate — `0` for closing, `> 0` for opening or type-switch.

  | Action | `targetImeBottom` | Event emitted |
  |---|---|---|
  | Keyboard opens | `> 0` | `keyboardWillShow` ✓ |
  | Keyboard closes (Done) | `0` | `keyboardWillHide` ✓ |
  | Type switch (text → number) | `> 0` | `keyboardWillShow` ✓ |

### iOS — Fix: toolbar stretch/jitter during field switch (`SafeArea` → `viewPaddingOf`)

- **Root cause**: `SafeArea` inside the toolbar row subscribes to `MediaQuery.viewInsets`. When the user switches focus between two text fields, Flutter's engine temporarily clears the `TextInput` client, which causes `MediaQuery.viewInsets.bottom` to briefly reset to 0. `SafeArea` immediately adds ~34 px of home-indicator padding (since it thinks the keyboard is gone), stretching the toolbar for one frame. A frame later, `viewInsets` is restored and `SafeArea` removes the padding — the toolbar snaps back.

- **Fix — Dart (`KeyboardToolbar`)**: Replaced `SafeArea` with a `ValueListenableBuilder` driven by `animation.heightNotifier`. Bottom padding is computed as `(MediaQuery.viewPaddingOf(context).bottom − kbHeight).clamp(0, safeBottom)`. `viewPaddingOf` returns the physical device safe-area constant (home-indicator height), which never changes with keyboard state — the toolbar height is now stable across all field switches.

### `KeyboardAwareScrollView` — Synchronous delta translation (zero-jitter dismiss)

- **Root cause**: Bottom padding shrank per-frame via `_onHeightChanged`, causing `maxScrollExtent` to decrease each frame. When `pixels > maxScrollExtent`, `BouncingScrollPhysics` produced a "scroll up → spring back" glitch. The previous safety-clamp (`jumpTo` in `didHide`) fired after the frame was already painted, adding a second visible snap.

- **Fix** — three coordinated changes:

  1. **Single source of truth**: `_paddingNotifier` is updated exclusively inside `_onHeightChanged`. Removed the direct assignments that were in `didShow` and `didHide`, ensuring `heightDelta` is never accidentally zeroed before the clamp runs on the last frame.

  2. **Synchronous delta translation**: `jumpTo(expectedMaxExtent)` runs _before_ `_paddingNotifier.value = newHeight` so `pos.maxScrollExtent` still reflects the old layout when `expectedMaxExtent = (maxScrollExtent − heightDelta).clamp(0, ∞)` is computed. Both `pixels` and `maxScrollExtent` change by the same delta in the same frame — no spring lag, no 1-frame jitter.

  3. **Clamp to `expectedMaxExtent` not `pixels − Δ`**: Prevents over-scrolling when `pixels` is far above the new max.

### `KeyboardAwareScrollView` — Kill switch for stale `animateTo`

- Added `_scrollController.position.jumpTo(position.pixels)` in `willHide` and `didHide` handlers. Calls `goIdle()` on the scroll position, immediately stopping any in-flight `animateTo` from `_scrollToFocusedInput` before the keyboard starts or finishes hiding.

### `KeyboardAwareScrollView` — Duration-aware scroll trigger in `didShow`

- **Root cause**: On Android, static keyboard type switches (e.g. numpad → text) are handled by `setOnApplyWindowInsetsListener` which emits `didShow` with `duration = 0` — no `keyboardMove` frames are produced, so `heightNotifier` is never updated. `_paddingNotifier` remained at the old keyboard height, `maxScrollExtent` was stale, and `targetOffset` was clamped to the wrong value, leaving the focused field partially hidden.

- **Fix**: When `didShow` carries `duration == 0` (instant switch), `_paddingNotifier.value` is set explicitly to the new height before queuing `addPostFrameCallback` — this forces `SingleChildScrollView` to rebuild with the correct `maxScrollExtent` before `_scrollToFocusedInput` runs. When `duration > 0` (animated show), `_paddingNotifier` has already been tracking per-frame via `_onHeightChanged` so `_scrollToFocusedInput` is called directly without delay.

### `KeyboardGeometryService` — Plain `TextField` ancestor detection

- **Root cause**: `resolveTargetContext` only matched `FormField` subclasses (`TextFormField`). Plain `TextField` and multiline (`maxLines > 1`) `TextField` widgets were not caught — the traversal fell back to the inner `EditableText` bounds, which excludes the bottom border and padding. The focused field's bottom edge was measured too high, leaving the border hidden behind the keyboard.

- **Fix**: Added `element.widget.runtimeType.toString() == 'TextField'` to the ancestor check (same string-comparison pattern used for `KeyboardScrollBoundary` to avoid circular imports). `FormField` still takes priority when found higher in the tree (e.g. `TextFormField`).

### Example — iOS keyboard preload on startup

- Added `KeyboardController.preload()` call in `_MyAppState.initState` via `addPostFrameCallback`. Warms up the iOS keyboard cache after the first frame so any screen's first keyboard appearance is instant with no cold-start delay.

---

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

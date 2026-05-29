# flutter_keyboard_controller

**Frame-by-frame keyboard tracking for Flutter** — smooth animations, auto-scroll forms, chat UIs, sticky toolbars, and a full imperative API. Built on native `CADisplayLink` (iOS) and `WindowInsetsAnimationCompat` + `OnApplyWindowInsetsListener` (Android).

[![pub.dev](https://img.shields.io/pub/v/flutter_keyboard_controller.svg)](https://pub.dev/packages/flutter_keyboard_controller)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Preview

|                                      Form auto-scroll                                       |                                   Chat lift                                   | Sticky toolbar |
|:-------------------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------:|:---:|
|                                      ![form-scroll](https://github.com/user-attachments/assets/f4d36d06-0255-4585-ad18-458d9249be56)                                       |                                ![chat-lift](https://github.com/user-attachments/assets/6cb5d3e7-3b3a-448d-b523-f0b3f233b74c)                                 | ![toolbar](https://github.com/user-attachments/assets/6dc5f38d-5b49-4fa3-953f-cdd6bed2c03d) |
| `KeyboardAwareScrollView` auto-scrolls to the focused field including labels and error text | `KeyboardChatScrollView` lifts the message list with 4 configurable behaviors | `KeyboardToolbar` slides in sync with the keyboard, pixel-perfect |

---

## Why this library?

### Flutter's built-in keyboard handling

Flutter ships two mechanisms:

**`Scaffold(resizeToAvoidBottomInset: true)`** (default)
- Scaffold body shrinks **in one jump** when keyboard animation ends — not per-frame.
- `TextField.scrollPadding` calls `Scrollable.ensureVisible()` on the raw `TextField` bounds — ignores labels or error text below the field.
- Android: on some devices (Samsung) a keyboard-type switch causes a *static layout pass* with no animation, so Flutter's scroll simply doesn't fire.

**`MediaQuery.viewInsetsOf(context)`**
- Returns height only **after** animation ends.
- Every widget reading it rebuilds — cascades through the entire `InheritedWidget` tree.
- No progress value (0→1), no lifecycle events, no interactive-dismiss tracking.

### Deep comparison

| | Flutter built-in | flutter_keyboard_controller |
|---|---|---|
| Height timing | After animation ends | **Every frame** |
| Progress 0→1 | ❌ | ✅ `progressNotifier` |
| Lifecycle events | ❌ | ✅ `willShow / didShow / willHide / didHide / move / interactive` |
| iOS interactive dismiss | Estimated | ✅ `CADisplayLink` exact position |
| Android keyboard-type switch | ❌ Missed on Samsung | ✅ `setOnApplyWindowInsetsListener` safety net |
| Rebuild scope | Entire `MediaQuery` subtree | Single `ValueListenableBuilder` |
| Auto-scroll to field | ✅ raw `TextField` only | ✅ full widget bounds (label + error) via `KeyboardScrollBoundary` |
| Auto-scroll when `resizeToAvoidBottomInset: false` | ❌ | ✅ |
| Global dismiss (tap/drag) | Per-ScrollView only | ✅ `KeyboardProvider.dismissBehavior` |
| Chat lift behaviors | ❌ | ✅ `KeyboardChatScrollView` |
| Sticky widget above keyboard | ❌ | ✅ `KeyboardStickyView` |
| Prev/Next/Done toolbar | ❌ | ✅ `KeyboardToolbar` |
| `dismiss(keepFocus, animated)` | ❌ | ✅ |
| Preload keyboard (iOS lag) | ❌ ~300 ms | ✅ `KeyboardController.preload()` |
| Android soft-input mode | Manifest only | ✅ `setInputMode()` at runtime |

### Performance

```
Flutter built-in: O(N) — rebuilds the entire MediaQuery subtree (Scaffold → theme → every consumer)
                         every time the keyboard opens or closes.

This library:     O(1) — only the specific Padding/Transform wrapper updates via ValueListenableBuilder.
                         Heavy widgets (lists, cards, images) remain completely static.
```

Always pass stable content as `child:` to `ValueListenableBuilder` so it never rebuilds per-frame:

```dart
// ✅ child: never rebuilds — only Padding wrapper does (~60×/s during anim)
ValueListenableBuilder<double>(
  valueListenable: context.keyboard.heightNotifier,
  child: const MyList(),
  builder: (_, height, child) => Padding(
    padding: EdgeInsets.only(bottom: height),
    child: child,
  ),
);
```

---

## Which widget should I use?

```
What are you building?
│
├─ Form with many text fields → KeyboardAwareScrollView
│
├─ Chat / AI-chat UI         → KeyboardChatScrollView + KeyboardStickyView
│
├─ Fixed layout (compose,    → KeyboardAvoidingView  (adjusts whole container)
│  search bar, login page)     OR KeyboardStickyView (just the input bar)
│
└─ Form + Prev/Next/Done     → KeyboardToolbar (pair with KeyboardAwareScrollView)
```

### `KeyboardAvoidingView` vs `KeyboardStickyView` — most common confusion

| | `KeyboardAvoidingView` | `KeyboardStickyView` |
|---|---|---|
| What adjusts | The **entire** layout container | **One** specific widget |
| Content behind keyboard | ✅ Never hidden | ❌ Keyboard overlaps it |
| Use case | Compose screen | Chat input bar |

---

## Installation

```yaml
dependencies:
  flutter_keyboard_controller: ^1.0.0
```

- **Android**: min SDK 24.
- **iOS**: min iOS 13.

---

## Quick start

```dart
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

void main() {
  runApp(
    // ⚠️ KeyboardProvider must wrap your entire app (above MaterialApp /
    // CupertinoApp). Placing it below Scaffold causes keyboard state to reset
    // on every route push/pop and bottom-sheet open.
    KeyboardProvider(
      dismissBehavior: KeyboardDismissBehavior.onTapAndDrag,
      child: MaterialApp(home: MyApp()),
    ),
  );
}
```

---

## KeyboardProvider

Root widget. Required for all features.

> **⚠️ Important**: Always place `KeyboardProvider` **above** `MaterialApp` / `CupertinoApp`. If placed below `Scaffold`, keyboard state resets on every route push/pop and breaks overlay handling for dialogs and bottom sheets.

```dart
KeyboardProvider(
  enabled: true,
  dismissBehavior: KeyboardDismissBehavior.onTapAndDrag,
  child: MaterialApp(...),  // ✅ correct — wraps the entire app
)
```

| `KeyboardDismissBehavior` | Effect |
|---|---|
| `manual` | Never auto-dismiss (default) |
| `onTap` | Dismiss on tap outside |
| `onDrag` | Dismiss on scroll |
| `onTapAndDrag` | Both |

### Reading keyboard state

```dart
final animation = context.keyboard;          // subscribes — widget rebuilds
final animation = context.keyboardOrNull;    // no subscription
```

---

## KeyboardAwareScrollView

**When to use**: Multi-field forms (sign-up, profile, settings).

**How it works**:
- Adds bottom padding = keyboard height so `maxScrollExtent` grows → content is scrollable above keyboard.
- `_onFocusChanged` fires on every focus change → `addPostFrameCallback` triggers `_scrollToFocusedInput`.
- `KeyboardGeometryService` calculates the target scroll offset using the field's `RenderBox` coordinates.
- `_isDismissing` + `ModalRoute.isCurrent` prevent unwanted scrolls when a bottom sheet opens.
- Android: `setOnApplyWindowInsetsListener` catches static keyboard-type switches that `WindowInsetsAnimationCompat` misses.

**vs Flutter built-in**:
- Flutter: body snaps, scrolls to raw `TextField` bounds only, fails on `resizeToAvoidBottomInset: false`.
- This: smooth per-frame padding, scrolls to full widget height (labels + errors), works independently of Scaffold.

```dart
Scaffold(
  resizeToAvoidBottomInset: false,
  body: KeyboardAwareScrollView(
    padding: const EdgeInsets.all(16),
    children: [
      // Plain field — scrolled to raw TextField bounds
      TextField(decoration: InputDecoration(labelText: 'Email')),

      // Custom widget — KeyboardScrollBoundary tells the scroll view to
      // include the label AND the red error text below the field.
      // Without it, only the raw TextField bounds are used and the error
      // text gets hidden behind the keyboard.
      KeyboardScrollBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Password'),
            const TextField(obscureText: true),
            const Text(
              'Must be at least 8 characters',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
      ),

      FilledButton(onPressed: submit, child: const Text('Sign in')),
    ],
  ),
)
```

### `KeyboardScrollBoundary` — for custom input widgets

Wrap your custom widget's root **once** so `KeyboardAwareScrollView` measures the full widget height (label + input + error text). No per-screen config needed — every screen using `KeyboardAwareScrollView` benefits automatically.

```dart
// Inside AppTextInput.build() — wrap once, works everywhere:
return KeyboardScrollBoundary(
  child: Column(children: [label, textField, errorText]),
);
```

### Parameters

| Param | Default | Description |
|---|---|---|
| `children` | required | Content widgets |
| `padding` | `null` | Outer padding |
| `scrollPadding` | `EdgeInsets.all(20)` | Gap between field and keyboard edge |
| `animationDuration` | `300 ms` | Scroll animation duration |
| `animationCurve` | `Curves.easeOut` | Scroll animation curve |
| `physics` | platform | `ScrollPhysics` |
| `scrollContextFinder` | `null` | Override ancestor traversal |

---

## KeyboardAvoidingView

**When to use**: Fixed layouts where the entire container must adapt to the keyboard — login screen, compose screen, search overlay.

**How it works**:
- `LayoutBuilder` captures parent height once. `ValueListenableBuilder` on `heightNotifier` applies the behavior per-frame.
- Always returns the **same wrapper widget type** regardless of keyboard state, so Flutter never unmounts the subtree and `FocusNode`s keep their state.

**vs Flutter built-in**:
- Flutter's `resizeToAvoidBottomInset: true` snaps the body in one step.
- `KeyboardAvoidingView` follows the keyboard smoothly every frame.

```dart
Scaffold(
  resizeToAvoidBottomInset: false,
  body: KeyboardAvoidingView(
    behavior: KeyboardAvoidingBehavior.padding,
    child: Column(children: [
      Expanded(child: content),
      inputBar,  // lifts smoothly with keyboard
    ]),
  ),
)
```

### Behaviors

| `behavior` | Effect | Constraints |
|---|---|---|
| `padding` | Adds `paddingBottom` | Works with any parent |
| `height` | Reduces `maxHeight` | Parent must give **loose** constraints (`Flexible`, not `Expanded`) |
| `position` | Translates view upward | Content may go behind AppBar |
| `translateWithPadding` | Half translate + half padding | Middle ground |

> ⚠️ **`height` behavior** requires a parent with **loose** constraints. Use `Flexible` instead of `Expanded`.
>
> *Why?* `Expanded` passes **tight** constraints (exact size) to its child. When the Flutter layout engine receives tight constraints it ignores any attempt to shrink the child — `KeyboardAvoidingView` simply can't reduce its height. `Flexible` passes **loose** constraints (maximum size), which allows the view to actually shrink to dodge the keyboard.

---

## KeyboardChatScrollView

**When to use**: Chat, messaging, AI assistant — reversed list with a floating input bar.

**How it works**:
- `ListView(reverse: true)` with `padding.bottom` adjusted per-frame via `heightNotifier`.
- No viewport resize — keyboard overlays. Lifting is pure padding change (no `jumpTo` needed).
- Four lift behaviors match popular apps.

**vs Flutter built-in**: No built-in equivalent. The naive `resizeToAvoidBottomInset: true` approach causes the list to flash/jump on keyboard open.

```dart
Scaffold(
  resizeToAvoidBottomInset: false,
  body: Stack(children: [
    Positioned.fill(
      child: KeyboardChatScrollView(
        liftBehavior: KeyboardLiftBehavior.whenAtEnd,
        extraBottomPadding: 72,  // floating input bar height
        safeAreaBottom: MediaQuery.of(context).viewPadding.bottom,
        children: messages.map((m) => MessageBubble(m)).toList(),
      ),
    ),
    ValueListenableBuilder<double>(
      valueListenable: context.keyboard.heightNotifier,
      child: InputBar(),
      builder: (_, kbH, child) => Positioned(
        left: 0, right: 0, bottom: kbH, child: child!,
      ),
    ),
  ]),
)
```

### Lift behaviors

| `liftBehavior` | When lifts | Inspired by |
|---|---|---|
| `always` | Every time keyboard opens | Telegram |
| `whenAtEnd` | Only when at newest message | WhatsApp, ChatGPT |
| `persistent` | Opens and stays lifted | Claude.ai |
| `never` | Never lifts | Perplexity |

---

## KeyboardStickyView

**When to use**: A single widget (input bar, send button) that must always sit just above the keyboard.

**How it works**:
- `Align(bottomCenter) + Padding(bottom: kbH + extraOffset)` driven by `heightNotifier`.
- Follows the keyboard **pixel-perfectly** every frame including iOS interactive swipe-dismiss.

**vs Flutter built-in**: `MediaQuery.viewInsetsOf` only updates after animation — widget teleports. `KeyboardStickyView` slides smoothly.

```dart
Stack(
  children: [
    Positioned.fill(child: chatList),
    KeyboardStickyView(
      offset: const KeyboardStickyOffset(closed: 0, opened: 8),
      child: InputBar(),
    ),
  ],
)
```

---

## KeyboardToolbar

**When to use**: Forms with multiple fields where Prev/Next/Done navigation improves UX.

**How it works**:
- `_ToolbarVisibility` subscribes to `lastEventNotifier` (not `heightNotifier`) so it reacts to lifecycle events, not per-frame height.
- Slides in/out via `ClipRect + Align(heightFactor)` in sync with keyboard animation.
- `KeyboardToolbarScaffold` with `resizeToAvoidBottomInset: false` uses a `Stack + Positioned.fill(VLB)` so `Positioned` inside `VLB` issue is avoided.
- Android: `_isSwitching` flag + `_savedKbH` keeps toolbar at correct height during keyboard-type switches.

**vs Flutter built-in**: No built-in toolbar. Workarounds using `MediaQuery` cause the toolbar to teleport (appear/disappear in one frame) instead of sliding.

```dart
KeyboardToolbarScaffold(
  resizeToAvoidBottomInset: false,
  toolbar: KeyboardToolbar(
    margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    borderRadius: BorderRadius.circular(100),  // pill
    doneLabel: 'Xong',
    arrowColor: Colors.blue,
    doneColor: Colors.blue,
    onPrev: () => FocusScope.of(context).previousFocus(),
    onNext: () => FocusScope.of(context).nextFocus(),
    actions: [
      KeyboardToolbarAction(icon: Icons.tag, onPressed: insertTag),
      KeyboardToolbarAction(
        icon: Icons.photo_camera_outlined,
        onPressed: openCamera,
        isSelected: _cameraMode,
        selectedColor: Colors.blue,
      ),
    ],
  ),
  body: KeyboardAwareScrollView(children: [...]),
)
```

### `KeyboardToolbar` parameters

| Param | Default | Description |
|---|---|---|
| `doneLabel` | `'Done'` | Dismiss button text (multilang) |
| `arrowColor` | primary | Prev/Next arrow color |
| `doneColor` | primary | Done button color |
| `showArrows` | `true` | Show Prev/Next arrows |
| `actions` | `[]` | Custom icon buttons (≤ 5) |
| `margin` | `null` | Outer margin for floating pill effect |
| `borderRadius` | `null` | Corner radius for pill shape |
| `toolbarScrollClearance` | `64` | Extra scroll padding so fields clear the toolbar |

---

## KeyboardAnimation — raw values

```dart
final animation = context.keyboard;

// Only this widget rebuilds per frame
ValueListenableBuilder<double>(
  valueListenable: animation.heightNotifier,
  child: const MyFAB(),
  builder: (_, height, fab) => Positioned(
    right: 16, bottom: 16 + height, child: fab!,
  ),
);
```

| Notifier | Type | Description |
|---|---|---|
| `heightNotifier` | `ValueNotifier<double>` | Keyboard height in dp (0 when hidden) |
| `progressNotifier` | `ValueNotifier<double>` | Progress 0→1 |
| `isVisibleNotifier` | `ValueNotifier<bool>` | Whether keyboard is visible |
| `lastEventNotifier` | `ValueNotifier<KeyboardEventData?>` | Last native event |

### Lifecycle events

```dart
animation.lastEventNotifier.addListener(() {
  switch (animation.lastEvent?.type) {
    case KeyboardEventType.willShow: // about to appear
    case KeyboardEventType.didShow:  // fully visible
    case KeyboardEventType.willHide: // about to hide
    case KeyboardEventType.didHide:  // fully hidden
    case KeyboardEventType.move:     // per-frame during animation
    case KeyboardEventType.interactive: // iOS swipe-dismiss
  }
});
```

---

## KeyboardController — imperative API

```dart
await KeyboardController.dismiss();
await KeyboardController.dismiss(keepFocus: true);   // hide keys, cursor stays
await KeyboardController.dismiss(animated: false);   // iOS: instant

final visible = await KeyboardController.isVisible();
final state   = await KeyboardController.state();    // height, isVisible

KeyboardController.preload();                        // iOS: eliminate cold-start lag

// Android only
KeyboardController.setInputMode(AndroidSoftInputMode.adjustNothing);
KeyboardController.setDefaultMode();
```

---

## Architecture notes

### Android — two-layer keyboard tracking

This library uses **two complementary mechanisms** on Android:

1. **`WindowInsetsAnimationCompat.Callback`** — tracks per-frame height during animated keyboard transitions. Fires `willShow/move/didShow/willHide/didHide` events.

2. **`setOnApplyWindowInsetsListener`** (safety net) — catches *static* keyboard-type switches (e.g. text → number keyboard) where Android performs a layout pass with no animation. Without this, `heightNotifier` would stay at the old value and the toolbar/scroll would appear mispositioned.

The `isAnimating` flag prevents duplicate events when both fire for the same transition.

### `KeyboardGeometryService`

DOM traversal and scroll-offset math are extracted into `KeyboardGeometryService` (under `lib/src/services/`). This means:
- `KeyboardAwareScrollView` is a thin UI layer — only renders and triggers events.
- Geometry logic is independently unit-testable without rendering.

### `KeyboardScrollBoundary`

A zero-overhead marker widget (`build` returns `child` unchanged). `KeyboardGeometryService.resolveTargetContext` walks ancestors looking for it. Wrap your custom input's root widget **once** — no per-screen config.

---

## API summary

### Widgets

| Widget | Purpose |
|---|---|
| `KeyboardProvider` | Root — required. Enables all features. |
| `KeyboardScrollBoundary` | Marks full bounds of a custom input (label + input + error) |
| `KeyboardAwareScrollView` | Form scroll — auto-scrolls focused field above keyboard |
| `KeyboardAvoidingView` | Adjusts entire container with 4 behaviors |
| `KeyboardChatScrollView` | Chat list with 4 lift behaviors |
| `KeyboardStickyView` | Sticks one widget to keyboard top edge |
| `KeyboardToolbar` | Prev/Next/Done toolbar above keyboard |
| `KeyboardToolbarScaffold` | Convenience scaffold wiring `KeyboardToolbar` |

### Enums

| Enum | Values |
|---|---|
| `KeyboardDismissBehavior` | `manual`, `onTap`, `onDrag`, `onTapAndDrag` |
| `KeyboardAvoidingBehavior` | `padding`, `height`, `position`, `translateWithPadding` |
| `KeyboardLiftBehavior` | `always`, `whenAtEnd`, `persistent`, `never` |
| `KeyboardEventType` | `willShow`, `didShow`, `willHide`, `didHide`, `move`, `interactive` |
| `AndroidSoftInputMode` | `adjustResize`, `adjustPan`, `adjustNothing`, `adjustUnspecified` |

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

MIT © 2026 Tuan Nguyen Cong

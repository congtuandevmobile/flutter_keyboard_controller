# flutter_keyboard_controller

A Flutter plugin for **smooth, frame-by-frame keyboard animation tracking** on iOS and Android.

Flutter's built-in `MediaQuery.viewInsetsOf` only fires once — at the **end** of the keyboard animation. This library fires a native event on **every frame**, so your UI can follow the keyboard pixel-perfectly with zero jank.

[![pub.dev](https://img.shields.io/pub/v/flutter_keyboard_controller.svg)](https://pub.dev/packages/flutter_keyboard_controller)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Why this library?

| | Flutter built-in | flutter_keyboard_controller |
|---|---|---|
| Keyboard height updates | Once (after animation ends) | Every frame (60 fps+) |
| Smooth animation | ❌ Jumps to final position | ✅ Follows keyboard pixel-by-pixel |
| Chat UI component | ❌ | ✅ `KeyboardChatScrollView` |
| Toolbar above keyboard | ❌ | ✅ `KeyboardToolbar` |
| Sticky widget | ❌ | ✅ `KeyboardStickyView` |
| iOS frame interpolation | ❌ | ✅ `CADisplayLink` |
| Android per-frame events | ❌ | ✅ `WindowInsetsAnimationCompat` |

---

## Features

- 🎞 **Frame-by-frame** keyboard height & progress (0–1) on every vsync
- 💬 **`KeyboardChatScrollView`** — chat list with `always / whenAtEnd / persistent / never` lift behaviors
- 📌 **`KeyboardStickyView`** — any widget that sticks to the keyboard top edge
- 🔧 **`KeyboardToolbar`** — Prev / Next / Done bar with customisable labels and colours
- 📜 **`KeyboardAwareScrollView`** — auto-scrolls to keep focused `TextField` visible
- 🛡 **`KeyboardAvoidingView`** — fine-grained avoidance with 4 modes
- ⚡ **`KeyboardController`** — dismiss, query state, set Android soft-input mode, preload on iOS
- 🎯 **`ValueNotifier`-based** — only subscribed widgets rebuild, zero overhead elsewhere

---

## Installation

```yaml
dependencies:
  flutter_keyboard_controller: ^0.0.1
```

```
flutter pub get
```

### Android

Minimum SDK **24**. No extra configuration needed.

### iOS

Minimum iOS **13**. No extra steps.

---

## Quick start

Wrap your app once with `KeyboardProvider`. All child widgets then have access to live keyboard data:

```dart
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

void main() {
  runApp(
    KeyboardProvider(
      child: MaterialApp(home: MyApp()),
    ),
  );
}
```

---

## KeyboardChatScrollView

The centerpiece for chat / AI-chat UIs. Place it in a `Stack` with a floating input bar:

```dart
Scaffold(
  resizeToAvoidBottomInset: false,
  body: Stack(
    children: [
      // Chat list — viewport never shrinks; padding lifts content instead
      Positioned.fill(
        child: KeyboardChatScrollView(
          liftBehavior: KeyboardLiftBehavior.whenAtEnd,
          extraBottomPadding: 72,   // height of your input bar
          safeAreaBottom: MediaQuery.of(context).viewPadding.bottom,
          children: messages.map((m) => MessageBubble(m)).toList(),
        ),
      ),
      // Input bar — animated above keyboard by plugin
      Positioned(
        left: 0, right: 0,
        bottom: KeyboardControllerScope.of(context).height,
        child: InputBar(),
      ),
    ],
  ),
)
```

### Lift behaviors

| `liftBehavior` | What it does | Matches |
|---|---|---|
| `always` | Lifts content on every keyboard open | Telegram |
| `whenAtEnd` | Lifts only when scrolled to the bottom | ChatGPT, WhatsApp |
| `persistent` | Lifts on open, stays lifted after close | Claude.ai |
| `never` | No automatic lift | Perplexity |

---

## KeyboardToolbar

Prev / Next / Done navigation bar that appears above the keyboard:

```dart
// Option A — convenience scaffold (recommended for forms)
KeyboardToolbarScaffold(
  appBar: AppBar(title: const Text('Profile')),
  toolbar: KeyboardToolbar(
    doneLabel: 'Xong',            // multilang — any String
    arrowColor: Colors.blue,
    doneColor: Colors.blue,
    onPrev: () => FocusScope.of(context).previousFocus(),
    onNext: () => FocusScope.of(context).nextFocus(),
  ),
  body: MyForm(),
)

// Option B — manual placement in a Stack
KeyboardStickyView(
  child: KeyboardToolbar(
    content: Text('2 of 5'),      // optional centre widget
  ),
)
```

`KeyboardToolbarScaffold` uses `resizeToAvoidBottomInset: true` so Flutter's automatic scroll-to-focused-field still works inside the body.

---

## KeyboardStickyView

Any widget that sticks to the top of the keyboard and moves with it frame-by-frame:

```dart
Stack(
  children: [
    Positioned.fill(child: content),
    KeyboardStickyView(
      offset: const KeyboardStickyOffset(closed: 0, opened: 0),
      child: InputBar(),
    ),
  ],
)
```

`KeyboardStickyOffset.closed` — extra dp offset when keyboard is hidden (e.g. safe-area bottom).
`KeyboardStickyOffset.opened` — extra dp offset when keyboard is visible.

---

## KeyboardAwareScrollView

Auto-scrolls to keep the focused `TextField` above the keyboard:

```dart
KeyboardAwareScrollView(
  padding: const EdgeInsets.all(24),
  scrollPadding: const EdgeInsets.all(20),
  children: [
    TextField(decoration: const InputDecoration(labelText: 'First name')),
    TextField(decoration: const InputDecoration(labelText: 'Last name')),
    TextField(decoration: const InputDecoration(labelText: 'Email')),
    const SizedBox(height: 24),
    FilledButton(onPressed: submit, child: const Text('Save')),
  ],
)
```

---

## KeyboardAvoidingView

Fine-grained control over how a widget avoids the keyboard:

```dart
KeyboardAvoidingView(
  behavior: KeyboardAvoidingBehavior.padding,  // padding | height | position | translateWithPadding
  keyboardVerticalOffset: 0,
  child: Column(
    children: [
      Expanded(child: MessageList()),
      InputBar(),
    ],
  ),
)
```

| `behavior` | Effect |
|---|---|
| `padding` | Adds bottom padding equal to keyboard height |
| `height` | Shrinks the widget's max height |
| `position` | Translates the widget upward |
| `translateWithPadding` | Translate + padding (for bottom sheets) |

---

## Raw keyboard animation values

Access live height and progress from any widget in the tree:

```dart
// Fine-grained — only this widget rebuilds when height changes
final animation = KeyboardControllerScope.of(context);

ValueListenableBuilder<double>(
  valueListenable: animation.heightNotifier,
  builder: (context, height, child) {
    return Positioned(bottom: 16 + height, right: 16, child: child!);
  },
  child: const MyFAB(),
);
```

Available notifiers on `KeyboardAnimation`:

| Notifier | Type | Description |
|---|---|---|
| `heightNotifier` | `ValueNotifier<double>` | Current keyboard height in dp |
| `progressNotifier` | `ValueNotifier<double>` | Animation progress 0.0 → 1.0 |
| `isVisibleNotifier` | `ValueNotifier<bool>` | Whether keyboard is visible |
| `lastEventNotifier` | `ValueNotifier<KeyboardEventData?>` | Last raw event from native |

Convenience getters: `animation.height`, `animation.progress`, `animation.isVisible`.

Extension shorthand: `context.keyboard` / `context.keyboardOrNull`.

---

## KeyboardController — imperative API

```dart
// Dismiss keyboard
KeyboardController.dismiss();
KeyboardController.dismiss(keepFocus: true);   // cursor stays, keyboard hides
KeyboardController.dismiss(animated: false);   // iOS: instant dismiss

// Query state
final visible = await KeyboardController.isVisible();
final state   = await KeyboardController.state();
print(state.height);     // double — current height in dp
print(state.isVisible);  // bool

// Android: change soft-input mode
KeyboardController.setInputMode(AndroidSoftInputMode.adjustNothing);
KeyboardController.setDefaultMode();   // restore to adjustResize

// iOS: preload keyboard to avoid first-show lag
KeyboardController.preload();
```

---

## Migration from MediaQuery

**Before** — fires once, content jumps:
```dart
final height = MediaQuery.viewInsetsOf(context).bottom;
```

**After** — fires every frame, content animates smoothly:
```dart
final animation = KeyboardControllerScope.of(context);

ValueListenableBuilder<double>(
  valueListenable: animation.heightNotifier,
  builder: (_, height, child) {
    return Padding(padding: EdgeInsets.only(bottom: height), child: child);
  },
  child: myContent,
);
```

---

## Performance tips

- Use `animation.heightNotifier` in a `ValueListenableBuilder` — only the targeted subtree rebuilds, not the full tree.
- Pass pre-built widgets as the `child` parameter of `ValueListenableBuilder` so they are not recreated per frame.
- Use `KeyboardControllerScope.maybeOf(context)` (instead of `.of`) when the provider might be absent — it returns null gracefully and never throws.
- `KeyboardChatScrollView` rebuilds only its internal `ListView` padding per frame — its message bubble children are untouched.

---

## API Reference

### Widgets

| Widget | Key props |
|---|---|
| `KeyboardProvider` | `enabled` |
| `KeyboardAvoidingView` | `behavior`, `keyboardVerticalOffset`, `duration`, `curve` |
| `KeyboardAwareScrollView` | `children`, `padding`, `scrollPadding`, `animationDuration` |
| `KeyboardStickyView` | `child`, `offset: KeyboardStickyOffset(closed, opened)` |
| `KeyboardToolbar` | `doneLabel`, `arrowColor`, `doneColor`, `onPrev`, `onNext`, `onDone`, `content`, `showArrows` |
| `KeyboardToolbarScaffold` | `toolbar`, `body`, `appBar`, `resizeToAvoidBottomInset` |
| `KeyboardChatScrollView` | `liftBehavior`, `extraBottomPadding`, `safeAreaBottom`, `onEndVisible` |

### Models

| Type | Description |
|---|---|
| `KeyboardAnimation` | Live keyboard state with `ValueNotifier`s |
| `KeyboardEventData` | Payload of each native event — height, progress, duration, type |
| `KeyboardEventType` | `willShow`, `didShow`, `willHide`, `didHide`, `move` |
| `KeyboardState` | Snapshot returned by `KeyboardController.state()` |
| `KeyboardLiftBehavior` | `always`, `whenAtEnd`, `persistent`, `never` |
| `KeyboardAvoidingBehavior` | `padding`, `height`, `position`, `translateWithPadding` |
| `AndroidSoftInputMode` | `adjustResize`, `adjustPan`, `adjustNothing`, `adjustUnspecified` |

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

MIT

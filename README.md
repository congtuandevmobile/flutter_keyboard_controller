# flutter_keyboard_controller

A Flutter plugin for **smooth, frame-by-frame keyboard animation tracking** on iOS and Android.

Unlike `MediaQuery.viewInsetsOf` — which rebuilds every widget that consumes it — this library pushes keyboard height via `ValueNotifier`, so **only the exact widget that needs it rebuilds**. It also exposes raw keyboard lifecycle events and ships pre-built components for chat UIs, toolbars, and sticky views that Flutter's built-in toolkit doesn't provide.

[![pub.dev](https://img.shields.io/pub/v/flutter_keyboard_controller.svg)](https://pub.dev/packages/flutter_keyboard_controller)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Why this library?

| | `MediaQuery.viewInsetsOf` | flutter_keyboard_controller |
|---|---|---|
| Rebuild scope | Every widget that reads it | Only the `ValueListenableBuilder` that subscribes |
| Keyboard height | ✅ | ✅ |
| Progress 0 → 1 | ❌ | ✅ |
| Event types (`willShow`, `didShow` …) | ❌ | ✅ |
| iOS interactive dismiss tracking | ❌ estimate | ✅ `CADisplayLink` real position |
| Chat UI component | ❌ | ✅ `KeyboardChatScrollView` |
| Sticky widget above keyboard | ❌ | ✅ `KeyboardStickyView` |
| Prev / Next / Done toolbar | ❌ | ✅ `KeyboardToolbar` |
| `dismiss(keepFocus, animated)` | ❌ | ✅ |
| Change Android soft-input mode | ❌ | ✅ `setInputMode` |
| Preload keyboard on iOS | ❌ | ✅ `preload()` |

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
  flutter_keyboard_controller: ^0.0.2
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

## KeyboardProvider

`KeyboardProvider` is the **required root widget** that initialises native keyboard tracking and exposes a `KeyboardAnimation` to all descendants via `InheritedNotifier`.

Place it as high as possible in the tree — typically wrapping `MaterialApp`:

```dart
KeyboardProvider(
  enabled: true,   // set false to pause tracking without removing the widget
  child: MaterialApp(home: MyApp()),
)
```

### Reading keyboard state in descendants

```dart
// Subscribes — widget rebuilds on every keyboard event
final animation = KeyboardControllerScope.of(context);

// Does NOT subscribe — safe for use inside listeners / callbacks
final animation = KeyboardControllerScope.maybeOf(context); // nullable

// Extension shorthand
final animation = context.keyboard;        // subscribes, throws if absent
final animation = context.keyboardOrNull;  // nullable, does not subscribe
```

---

## KeyboardChatScrollView

The centerpiece for chat / AI-chat UIs. Uses a `Stack` with a floating input bar so the viewport never shrinks — lifting is done via `padding.bottom` changes instead:

```dart
Scaffold(
  resizeToAvoidBottomInset: false,
  body: Stack(
    children: [
      Positioned.fill(
        child: KeyboardChatScrollView(
          liftBehavior: KeyboardLiftBehavior.whenAtEnd,
          extraBottomPadding: 72,   // fixed height of your input bar
          safeAreaBottom: MediaQuery.of(context).viewPadding.bottom,
          onEndVisible: () { /* user scrolled to bottom */ },
          children: messages.map((m) => MessageBubble(m)).toList(),
        ),
      ),
      // Input bar floats above keyboard, driven by plugin animation
      ValueListenableBuilder<double>(
        valueListenable: KeyboardControllerScope.of(context).heightNotifier,
        child: InputBar(),
        builder: (_, keyboardH, child) => Positioned(
          left: 0, right: 0, bottom: keyboardH, child: child!,
        ),
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

### Parameters

| Param | Default | Description |
|---|---|---|
| `liftBehavior` | `whenAtEnd` | When to lift content |
| `extraBottomPadding` | `0` | Fixed space for the floating input bar |
| `safeAreaBottom` | `0` | `MediaQuery.of(context).viewPadding.bottom` — corrects SafeArea shrink inside input bar when keyboard opens |
| `onEndVisible` | `null` | Called when user scrolls to the newest message (offset ≤ 20 dp in `reverse:true`) |
| `controller` | auto | Custom `ScrollController` |
| `padding` | `null` | Extra `EdgeInsetsGeometry` added to the list |
| `physics` | default | `ScrollPhysics` |
| `clipBehavior` | `Clip.hardEdge` | Clipping behaviour |

---

## KeyboardToolbar

Prev / Next / Done navigation bar that appears above the keyboard:

```dart
// Option A — convenience scaffold (recommended for forms)
KeyboardToolbarScaffold(
  appBar: AppBar(title: const Text('Profile')),
  toolbar: KeyboardToolbar(
    doneLabel: 'Xong',            // multilang — any String
    prevLabel: 'Before',
    nextLabel: 'Continue',
    arrowColor: Colors.blue,      // colour for ‹ › arrows
    doneColor: Colors.blue,       // colour for Done label
    onPrev: () => FocusScope.of(context).previousFocus(),
    onNext: () => FocusScope.of(context).nextFocus(),
    showArrows: true,             // set false to show Done only
    content: const Text('2/5'),   // optional centre widget
  ),
  body: MyForm(),
)

// Option B — manual placement in a Stack
KeyboardStickyView(
  child: KeyboardToolbar(),
)
```

`KeyboardToolbarScaffold` uses `resizeToAvoidBottomInset: true` by default so Flutter's automatic scroll-to-focused-field still works inside the body. The toolbar slides in/out in sync with the keyboard animation — no lag between keyboard and toolbar disappearing.

### `KeyboardToolbarScaffold` parameters

| Param | Default | Description |
|---|---|---|
| `toolbar` | `KeyboardToolbar()` | The toolbar widget |
| `body` | required | Main content |
| `appBar` | `null` | Optional app bar |
| `resizeToAvoidBottomInset` | `true` | Set `false` only when managing layout manually |
| `backgroundColor` | theme | Scaffold background |
| `floatingActionButton` | `null` | FAB |
| `bottomNavigationBar` | `null` | Bottom nav |

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

| `KeyboardStickyOffset` | Description |
|---|---|
| `closed` | Extra dp offset when keyboard is hidden (e.g. safe-area bottom or tab-bar height) |
| `opened` | Extra dp offset when keyboard is visible |

---

## KeyboardAwareScrollView

Auto-scrolls to keep the focused `TextField` visible when the keyboard opens:

```dart
KeyboardAwareScrollView(
  padding: const EdgeInsets.all(24),
  scrollPadding: const EdgeInsets.all(20), // gap between field and keyboard edge
  animationDuration: const Duration(milliseconds: 300),
  animationCurve: Curves.easeOut,
  children: [
    TextField(decoration: const InputDecoration(labelText: 'First name')),
    TextField(decoration: const InputDecoration(labelText: 'Last name')),
    TextField(decoration: const InputDecoration(labelText: 'Email')),
    const SizedBox(height: 24),
    FilledButton(onPressed: submit, child: const Text('Save')),
  ],
)
```

### Parameters

| Param | Default | Description |
|---|---|---|
| `children` | required | Widgets inside the scroll view |
| `scrollController` | auto | Custom `ScrollController` |
| `padding` | `null` | Outer padding of the scroll view |
| `scrollPadding` | `EdgeInsets.all(20)` | Extra gap between the focused field and keyboard edge |
| `animationDuration` | `Duration(ms: 300)` | Duration of the scroll animation |
| `animationCurve` | `Curves.easeOut` | Curve of the scroll animation |
| `physics` | default | `ScrollPhysics` |
| `reverse` | `false` | Reverse scroll direction |
| `shrinkWrap` | `false` | Shrink-wrap content |

> **Fallback:** If no `KeyboardProvider` is in the tree, `KeyboardAwareScrollView` falls back to `WidgetsBindingObserver.didChangeMetrics` — it still auto-scrolls, just without frame-accurate timing.

---

## KeyboardAvoidingView

Fine-grained control over how a widget adjusts its layout when the keyboard appears:

```dart
Scaffold(
  resizeToAvoidBottomInset: false,  // required — let KeyboardAvoidingView handle it
  body: KeyboardAvoidingView(
    behavior: KeyboardAvoidingBehavior.padding,
    keyboardVerticalOffset: 0,
    enabled: true,
    child: Column(
      children: [
        Expanded(child: MessageList()),
        InputBar(),
      ],
    ),
  ),
)
```

### Parameters

| Param | Default | Description |
|---|---|---|
| `behavior` | `padding` | Avoidance mode (see table below) |
| `keyboardVerticalOffset` | `0.0` | Extra dp added on top of keyboard height |
| `enabled` | `true` | Set `false` to temporarily disable without removing the widget |

### Behaviors

| `behavior` | Effect |
|---|---|
| `padding` | Adds `paddingBottom` equal to keyboard height |
| `height` | Reduces the widget's `maxHeight` |
| `position` | Translates the widget upward |
| `translateWithPadding` | Half translate + half padding (for bottom sheets) |

> **Layout stability:** `KeyboardAvoidingView` always wraps the child in the same widget type regardless of keyboard state (`Padding` / `SizedBox` / `Transform`). This prevents Flutter from unmounting the subtree, so `TextField`s never lose their `FocusNode`.

---

## KeyboardAnimation — raw values

Access live keyboard height and progress from any widget:

```dart
final animation = KeyboardControllerScope.of(context);

// ValueListenableBuilder — only this widget rebuilds per frame
ValueListenableBuilder<double>(
  valueListenable: animation.heightNotifier,
  child: const MyFAB(),
  builder: (context, height, child) {
    return Positioned(bottom: 16 + height, right: 16, child: child!);
  },
);
```

### Available notifiers

| Notifier | Type | Description |
|---|---|---|
| `heightNotifier` | `ValueNotifier<double>` | Keyboard height in dp (0 when hidden) |
| `progressNotifier` | `ValueNotifier<double>` | Animation progress 0.0 → 1.0 |
| `isVisibleNotifier` | `ValueNotifier<bool>` | Whether keyboard is currently visible |
| `lastEventNotifier` | `ValueNotifier<KeyboardEventData?>` | Last raw event from native layer |

Convenience getters: `animation.height` · `animation.progress` · `animation.isVisible` · `animation.lastEvent`

### Listening to keyboard events

```dart
final animation = KeyboardControllerScope.of(context);

animation.lastEventNotifier.addListener(() {
  final event = animation.lastEvent;
  if (event == null) return;

  switch (event.type) {
    case KeyboardEventType.willShow:
      print('Keyboard about to show, final height: ${event.height}');
    case KeyboardEventType.didShow:
      print('Keyboard fully visible');
    case KeyboardEventType.willHide:
      print('Keyboard about to hide');
    case KeyboardEventType.didHide:
      print('Keyboard hidden');
    case KeyboardEventType.move:
      print('Animating: ${event.height} dp, progress: ${event.progress}');
    case KeyboardEventType.interactive:
      print('User gesture dismiss: ${event.height} dp');
  }
});
```

### `KeyboardEventData` fields

| Field | Type | Description |
|---|---|---|
| `type` | `KeyboardEventType` | Event category |
| `height` | `double` | Current keyboard height in dp |
| `progress` | `double` | 0.0 (hidden) → 1.0 (fully visible) |
| `duration` | `double` | Native animation duration in ms |
| `timestamp` | `double` | Unix ms when the event was fired |
| `isVisible` | `bool` | `height > 0` |

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
print(state.progress);   // double

// Android: change soft-input mode
KeyboardController.setInputMode(AndroidSoftInputMode.adjustNothing);
KeyboardController.setDefaultMode();   // restore to adjustResize

// iOS: preload keyboard to avoid first-show lag
KeyboardController.preload();
```

### `AndroidSoftInputMode` values

| Value | Effect |
|---|---|
| `adjustResize` | Scaffold body shrinks (Flutter default) |
| `adjustPan` | Window pans upward, body does not shrink |
| `adjustNothing` | Keyboard overlaps content, nothing moves |
| `adjustUnspecified` | System decides |

---

## FocusedInputLayout

Data models for retrieving information about the currently focused text input:

```dart
// FocusedInputLayout — position of the focused field on screen
FocusedInputLayout layout = FocusedInputLayout(
  absoluteRect: Rect.fromLTWH(x, y, width, height),
  isFocused: true,
);
print(layout.absoluteRect);  // Rect in global screen coordinates
print(layout.isFocused);     // bool

// FocusedInputLayout.empty() — default when nothing is focused
final empty = FocusedInputLayout.empty();

// FocusedInputTextChangedEvent — text change event
FocusedInputTextChangedEvent(text: 'Hello');

// FocusedInputSelectionChangedEvent — cursor / selection change
final sel = FocusedInputSelectionChangedEvent(start: 0, end: 5);
print(sel.isCollapsed);  // true when start == end (cursor, not selection)
```

---

## Migration from MediaQuery

**Before** — fires once at end of animation, content jumps:
```dart
final height = MediaQuery.viewInsetsOf(context).bottom;
```

**After** — fires every frame, content follows keyboard smoothly:
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

- Use `animation.heightNotifier` in a `ValueListenableBuilder` and pass your widget as `child` — only the `Positioned`/`Padding` wrapper rebuilds per frame, not the child widget itself.
- Use `KeyboardControllerScope.maybeOf(context)` when the provider might be absent — returns null gracefully, never throws.
- `KeyboardChatScrollView` only rebuilds its internal `ListView` padding per frame — message bubble children are never touched.
- Avoid reading `KeyboardControllerScope.of(context)` at the root of a heavy widget — subscribe only at the leaf that actually needs the value.

---

## API Reference

### Widgets

| Widget | Key props | Defaults |
|---|---|---|
| `KeyboardProvider` | `child`, `enabled` | `enabled: true` |
| `KeyboardAvoidingView` | `child`, `behavior`, `keyboardVerticalOffset`, `enabled` | `behavior: padding`, `offset: 0`, `enabled: true` |
| `KeyboardAwareScrollView` | `children`, `padding`, `scrollPadding`, `animationDuration`, `animationCurve`, `physics`, `scrollController` | `scrollPadding: 20`, `duration: 300ms`, `curve: easeOut` |
| `KeyboardStickyView` | `child`, `offset: KeyboardStickyOffset(closed, opened)` | `closed: 0`, `opened: 0` |
| `KeyboardToolbar` | `doneLabel`, `prevLabel`, `nextLabel`, `arrowColor`, `doneColor`, `onPrev`, `onNext`, `onDone`, `content`, `showArrows`, `backgroundColor`, `borderColor` | `showArrows: true` |
| `KeyboardToolbarScaffold` | `toolbar`, `body`, `appBar`, `resizeToAvoidBottomInset`, `backgroundColor` | `resizeToAvoidBottomInset: true` |
| `KeyboardChatScrollView` | `children`, `liftBehavior`, `extraBottomPadding`, `safeAreaBottom`, `onEndVisible`, `controller`, `padding`, `physics` | `liftBehavior: whenAtEnd`, `extraBottomPadding: 0`, `safeAreaBottom: 0` |

### Models & Enums

| Type | Values / Fields |
|---|---|
| `KeyboardAnimation` | `heightNotifier`, `progressNotifier`, `isVisibleNotifier`, `lastEventNotifier` |
| `KeyboardEventData` | `height`, `progress`, `duration`, `timestamp`, `isVisible`, `type` |
| `KeyboardEventType` | `willShow`, `didShow`, `willHide`, `didHide`, `move`, `interactive` |
| `KeyboardState` | `height`, `isVisible`, `progress` · `KeyboardState.hidden()` |
| `KeyboardLiftBehavior` | `always`, `whenAtEnd`, `persistent`, `never` |
| `KeyboardAvoidingBehavior` | `padding`, `height`, `position`, `translateWithPadding` |
| `AndroidSoftInputMode` | `adjustResize`, `adjustPan`, `adjustNothing`, `adjustUnspecified` |
| `FocusedInputLayout` | `absoluteRect: Rect`, `isFocused: bool` · `.empty()` |
| `FocusedInputTextChangedEvent` | `text: String` |
| `FocusedInputSelectionChangedEvent` | `start: int`, `end: int`, `isCollapsed: bool` |

### KeyboardControllerScope

| Method | Returns | Description |
|---|---|---|
| `KeyboardControllerScope.of(context)` | `KeyboardAnimation` | Subscribes — widget rebuilds on every event |
| `KeyboardControllerScope.maybeOf(context)` | `KeyboardAnimation?` | Does NOT subscribe — returns null if no provider |
| `context.keyboard` | `KeyboardAnimation` | Shorthand for `.of()` |
| `context.keyboardOrNull` | `KeyboardAnimation?` | Shorthand for `.maybeOf()` |

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

MIT © 2025 Tuan Nguyen Cong

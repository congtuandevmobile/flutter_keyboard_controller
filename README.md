# flutter_keyboard_controller

A Flutter plugin for **smooth, frame-by-frame keyboard animation tracking** — inspired by and feature-equivalent to [react-native-keyboard-controller](https://github.com/kirillzyusko/react-native-keyboard-controller).

Native platforms report keyboard height on every animation frame via platform channels. Dart consumes these events through `ValueNotifier`s so widgets only rebuild when they actually need to.

---

## Features

| Feature | Description |
|---|---|
| `KeyboardProvider` | Root widget — initialises tracking, exposes `KeyboardAnimation` via `InheritedNotifier` |
| `KeyboardAnimation` | Live `height`, `progress` (0–1), `isVisible` — updated frame-by-frame |
| `KeyboardAvoidingView` | 4 avoidance modes: `padding`, `height`, `position`, `translateWithPadding` |
| `KeyboardAwareScrollView` | Auto-scrolls to keep the focused input above the keyboard |
| `KeyboardStickyView` | Any widget that sticks to the keyboard top edge |
| `KeyboardToolbar` | Prev / Next / Done navigation toolbar above keyboard |
| `KeyboardChatScrollView` | Chat-optimised list with 4 lift behaviors |
| `KeyboardController` | Imperative API: `dismiss`, `isVisible`, `state`, `setInputMode` |

### Platform support

| Platform | Mechanism |
|---|---|
| **Android** | `WindowInsetsAnimationCompat.Callback` — fires on every animation frame (API 21+) |
| **iOS** | `UIKeyboardWill/DidShow/Hide` notifications + `CADisplayLink` for frame interpolation |

---

## Installation

```yaml
dependencies:
  flutter_keyboard_controller: ^1.0.0
```

### Android

Minimum SDK 24. No extra configuration needed — `androidx.core:core-ktx` is bundled.

### iOS

Minimum iOS 13. No extra steps.

---

## Quick start

Wrap your app (or the subtree that needs keyboard awareness) with `KeyboardProvider`:

```dart
void main() {
  runApp(
    KeyboardProvider(
      child: MaterialApp(home: MyHome()),
    ),
  );
}
```

That's it. All child widgets can now use every feature of the library.

---

## KeyboardAvoidingView

Adjusts its layout when the keyboard appears. Choose between four behaviors:

```dart
KeyboardAvoidingView(
  behavior: KeyboardAvoidingBehavior.padding,   // or height / position / translateWithPadding
  keyboardVerticalOffset: 0,                    // extra dp offset
  duration: Duration(milliseconds: 250),
  curve: Curves.easeOut,
  child: Column(
    children: [
      Expanded(child: MessageList()),
      MessageInputBar(),                        // stays above keyboard
    ],
  ),
)
```

| `behavior` | Effect |
|---|---|
| `padding` | Adds `paddingBottom` equal to keyboard height |
| `height` | Reduces the widget's `maxHeight` |
| `position` | Translates the widget upward |
| `translateWithPadding` | Combines translate + padding (for bottom sheets) |

---

## KeyboardAwareScrollView

A scroll view that automatically scrolls to keep the focused `TextField` visible:

```dart
KeyboardAwareScrollView(
  padding: EdgeInsets.all(24),
  scrollPadding: EdgeInsets.all(20),   // extra space above keyboard edge
  children: [
    TextField(decoration: InputDecoration(labelText: 'Name')),
    TextField(decoration: InputDecoration(labelText: 'Email')),
    // ... more fields
    FilledButton(onPressed: submit, child: Text('Submit')),
  ],
)
```

The view tracks `FocusManager.instance.primaryFocus` to find which input is focused and calculates the required scroll offset at the moment the keyboard appears.

---

## KeyboardStickyView

A widget that sticks to the top of the keyboard and moves with it frame-by-frame:

```dart
// Inside a Stack with resizeToAvoidBottomInset: false
KeyboardStickyView(
  offset: KeyboardStickyOffset(closed: 0, opened: 8),
  child: InputBar(),  // always visible above keyboard
)
```

`KeyboardStickyOffset` lets you fine-tune the position:
- `closed` — extra dp when the keyboard is hidden (e.g. bottom nav bar height)
- `opened` — extra dp when the keyboard is visible

---

## KeyboardToolbar

A Prev / Next / Done navigation toolbar that appears above the keyboard:

```dart
// Option 1 — convenience scaffold
KeyboardToolbarScaffold(
  appBar: AppBar(title: Text('Form')),
  toolbar: const KeyboardToolbar(),
  body: MyForm(),
)

// Option 2 — manual placement in KeyboardStickyView
KeyboardStickyView(
  child: KeyboardToolbar(
    onPrev: () => FocusScope.of(context).previousFocus(),
    onNext: () => FocusScope.of(context).nextFocus(),
    onDone: () => KeyboardController.dismiss(),
    content: Text('3 / 5'),   // optional centre widget
  ),
)
```

---

## KeyboardChatScrollView

A `ListView` optimised for chat UIs. Content can "lift" as the keyboard appears:

```dart
KeyboardChatScrollView(
  liftBehavior: KeyboardLiftBehavior.whenAtEnd,
  children: messages.map((m) => MessageBubble(m)).toList(),
)
```

| `liftBehavior` | Description | App example |
|---|---|---|
| `always` | Content always scrolls up with keyboard | Telegram |
| `whenAtEnd` | Scrolls up only when at the bottom of the list | ChatGPT |
| `persistent` | Scrolls up on show, stays lifted on hide | Claude.ai |
| `never` | No automatic scrolling | Perplexity |

---

## KeyboardAnimation — raw values

Access live keyboard height and progress from any widget:

```dart
// Subscribe — widget rebuilds on every keyboard event
final animation = KeyboardControllerScope.of(context);
print(animation.height);    // e.g. 336.0 dp
print(animation.progress);  // 0.0–1.0
print(animation.isVisible); // bool

// Fine-grained subscription — only rebuilds when height changes
ValueListenableBuilder<double>(
  valueListenable: animation.heightNotifier,
  builder: (context, height, _) {
    return SizedBox(height: height);
  },
)

// Extension shorthand
final animation = context.keyboard;
```

### Building custom animations

Drive any Flutter animation directly from the keyboard height:

```dart
class FloatingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final animation = KeyboardControllerScope.of(context);

    return ValueListenableBuilder<double>(
      valueListenable: animation.heightNotifier,
      builder: (context, height, child) {
        // Move a FAB upward as the keyboard rises
        return Positioned(
          bottom: 16 + height,
          right: 16,
          child: child!,
        );
      },
      child: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.edit),
      ),
    );
  }
}
```

---

## KeyboardController — imperative API

```dart
// Dismiss keyboard
await KeyboardController.dismiss();
await KeyboardController.dismiss(keepFocus: true);   // cursor stays
await KeyboardController.dismiss(animated: false);   // iOS instant hide

// Query state
final visible = await KeyboardController.isVisible();
final state   = await KeyboardController.state();    // KeyboardState
print(state.height);    // double
print(state.isVisible); // bool

// Android: change soft-input mode
await KeyboardController.setInputMode(AndroidSoftInputMode.adjustNothing);
await KeyboardController.setDefaultMode(); // restore adjustResize

// iOS: warm up keyboard to reduce first-show latency
await KeyboardController.preload();
```

---

## KeyboardProvider options

```dart
KeyboardProvider(
  enabled: true,   // set to false to temporarily disable tracking
  child: ...,
)
```

---

## Performance

### Why frame-by-frame tracking matters

Most keyboard packages in Flutter only react to `didChangeMetrics` which fires **once** at the end of the keyboard animation. That means your UI jumps instead of smoothly following the keyboard.

This library fires a `keyboardMove` event on **every frame** during keyboard animation:

```
Android:  WindowInsetsAnimationCompat.onProgress() → called every vsync frame
iOS:      CADisplayLink + UIKeyboard notification timing → frame-interpolated progress
```

### How it's efficient in Flutter

| Concern | Solution |
|---|---|
| Avoid rebuilding the whole tree | `ValueNotifier<double>` per value — only subscribed widgets rebuild |
| Zero-overhead if unused | `KeyboardControllerScope.maybeOf()` returns null gracefully |
| No polling | EventChannel streams pushed from native — no timers on Dart side |
| Dispose properly | `KeyboardAnimation` disposes all inner `ValueNotifier`s |

### Benchmark guidance

- `KeyboardAvoidingView` — rebuilds only the `ValueListenableBuilder` node (~1 widget per frame)
- `KeyboardStickyView` — same — single `Padding` rebuild
- `KeyboardChatScrollView` — one `jumpTo` call per frame during interactive move
- Custom `ValueListenableBuilder` — only the targeted subtree rebuilds

For the absolute best performance on complex UIs, use `animation.heightNotifier` directly in a `ValueListenableBuilder` rather than `KeyboardControllerScope.of(context)` (which makes the entire widget a listener).

---

## Migration from MediaQuery approach

**Before (one-shot, no smooth animation):**
```dart
final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
```

**After (frame-by-frame, smooth):**
```dart
final animation = KeyboardControllerScope.of(context);
// or fine-grained:
ValueListenableBuilder<double>(
  valueListenable: animation.heightNotifier,
  builder: (_, height, child) => ...,
)
```

---

## API Reference

### Models

| Type | Description |
|---|---|
| `KeyboardEventData` | Payload of every native event (height, progress, duration, type) |
| `KeyboardEventType` | `willShow`, `didShow`, `willHide`, `didHide`, `move`, `interactive` |
| `KeyboardState` | Snapshot returned by `KeyboardController.state()` |
| `AndroidSoftInputMode` | `adjustResize`, `adjustPan`, `adjustNothing`, `adjustUnspecified` |
| `FocusedInputLayout` | Absolute rect of the currently focused input |

### Widgets

| Widget | Key props |
|---|---|
| `KeyboardProvider` | `enabled` |
| `KeyboardAvoidingView` | `behavior`, `keyboardVerticalOffset`, `duration`, `curve` |
| `KeyboardAwareScrollView` | `children`, `scrollPadding`, `animationDuration` |
| `KeyboardStickyView` | `child`, `offset: KeyboardStickyOffset` |
| `KeyboardToolbar` | `onPrev`, `onNext`, `onDone`, `content`, `showArrows` |
| `KeyboardToolbarScaffold` | `toolbar`, `body`, `appBar` |
| `KeyboardChatScrollView` | `liftBehavior`, `extraBottomPadding`, `onEndVisible` |

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

MIT

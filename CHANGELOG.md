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

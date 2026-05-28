/// Flutter Keyboard Controller
///
/// A Flutter plugin for smooth, frame-by-frame keyboard animation tracking
/// inspired by react-native-keyboard-controller.
///
/// **Quick start:**
/// ```dart
/// void main() {
///   runApp(
///     KeyboardProvider(
///       child: MaterialApp(home: MyApp()),
///     ),
///   );
/// }
/// ```
library;

// Models
export 'src/models/keyboard_event_data.dart';
export 'src/models/focused_input_layout.dart';
export 'src/models/keyboard_state.dart';

// Core
export 'src/controller/keyboard_controller.dart';
export 'src/provider/keyboard_animation.dart';
export 'src/provider/keyboard_provider.dart';

// Widgets
export 'src/widgets/keyboard_avoiding_view.dart';
export 'src/widgets/keyboard_aware_scroll_view.dart';
export 'src/widgets/keyboard_sticky_view.dart';
export 'src/widgets/keyboard_toolbar.dart';
export 'src/widgets/keyboard_chat_scroll_view.dart';

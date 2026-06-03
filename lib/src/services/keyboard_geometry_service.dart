import 'package:flutter/material.dart' show TextField;
import 'package:flutter/widgets.dart';

/// Stateless service that handles DOM traversal and scroll geometry
/// calculations for [KeyboardAwareScrollView].
///
/// Extracted from the widget so logic is independently testable without
/// rendering a widget tree.
class KeyboardGeometryService {
  KeyboardGeometryService._();

  // Cache resolved scroll-target context per FocusNode.
  // Expando uses weak references — entries are GC'd with their FocusNode.
  static final Expando<BuildContext> _targetContextCache = Expando();

  /// Walks ancestors from [focused] to find the best scroll target context.
  ///
  /// Priority order:
  ///   1. [customFinder] callback (app-provided escape hatch)
  ///   2. `KeyboardScrollBoundary` marker widget (labels + input + error)
  ///   3. `FormField` subclass (reactive_forms, TextFormField, …)
  ///   4. [focused.context] itself (plain TextField fallback)
  static BuildContext? resolveTargetContext({
    required FocusNode focused,
    required BuildContext scrollViewContext,
    BuildContext? Function(FocusNode)? customFinder,
  }) {
    if (customFinder != null) {
      return customFinder(focused) ?? focused.context;
    }

    // Return cached context if still mounted — avoids re-traversing the
    // element tree on every scroll trigger for the same focused field.
    final cached = _targetContextCache[focused];
    if (cached != null && (cached as Element).mounted) return cached;

    BuildContext? result;
    focused.context?.visitAncestorElements((element) {
      if (element.widget is Scrollable ||
          element.widget.runtimeType.toString() == 'KeyboardAwareScrollView') {
        return false;
      }
      // KeyboardScrollBoundary is identified by runtime type string to avoid
      // a circular import (the widget lives in the same package).
      if (element.widget.runtimeType.toString() == 'KeyboardScrollBoundary') {
        result = element;
        return false;
      }
      // FormField covers TextFormField (includes label + error text).
      // TextField: uses `is` operator (no circular import) — avoids toString()
      // per element. FocusNode attaches to inner EditableText, so without this
      // the bounds exclude border and bottom padding.
      if (element.widget is FormField || element.widget is TextField) {
        result = element;
      }
      return true;
    });

    final resolved = result ?? focused.context;
    if (resolved != null) _targetContextCache[focused] = resolved;
    return resolved;
  }

  /// Returns the scroll offset needed to bring [targetContext] into view
  /// above the keyboard, or `null` if no scroll is needed.
  ///
  /// Accounts for the toolbar inset so fields don't hide behind a floating
  /// [KeyboardToolbar].
  static double? calculateScrollOffset({
    required ScrollController controller,
    required BuildContext scrollViewContext,
    required BuildContext targetContext,
    required double keyboardHeight,
    required EdgeInsets scrollPadding,
    required double toolbarInset,
    required double screenHeight,
  }) {
    final renderObj = targetContext.findRenderObject();
    if (renderObj is! RenderBox || !renderObj.attached || !renderObj.hasSize) {
      return null;
    }

    final inputTop = renderObj.localToGlobal(Offset.zero).dy;
    final inputBottom = inputTop + renderObj.size.height;
    final visibleBottom = screenHeight - keyboardHeight;

    final scrollBox = scrollViewContext.findRenderObject() as RenderBox?;
    final safeTop =
        (scrollBox?.localToGlobal(Offset.zero).dy ?? 0) + scrollPadding.top;

    final effectivePaddingBottom = scrollPadding.bottom + toolbarInset;

    double targetOffset = controller.offset;
    bool needsScroll = false;

    if (inputBottom > visibleBottom - effectivePaddingBottom) {
      targetOffset += inputBottom - visibleBottom + effectivePaddingBottom;
      needsScroll = true;
    } else if (inputTop < safeTop) {
      targetOffset -= safeTop - inputTop;
      needsScroll = true;
    }

    if (!needsScroll) return null;

    return targetOffset.clamp(0.0, controller.position.maxScrollExtent);
  }
}

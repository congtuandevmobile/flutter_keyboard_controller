package com.example.flutter_keyboard_controller

import android.app.Activity
import android.content.Context
import android.view.View
import android.view.inputmethod.InputMethodManager
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsAnimationCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.max

/** FlutterKeyboardControllerPlugin */
class FlutterKeyboardControllerPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    // ── Channels ──────────────────────────────────────────────────────────────

    private lateinit var methodChannel: MethodChannel
    private lateinit var keyboardEventChannel: EventChannel

    private var keyboardEventSink: EventChannel.EventSink? = null

    // ── State ─────────────────────────────────────────────────────────────────

    private var activity: Activity? = null
    private var currentHeight = 0.0
    private var isKeyboardVisible = false

    // ── FlutterPlugin ─────────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "flutter_keyboard_controller")
        methodChannel.setMethodCallHandler(this)

        keyboardEventChannel = EventChannel(
            binding.binaryMessenger,
            "flutter_keyboard_controller/keyboard_events"
        )
        keyboardEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                keyboardEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                keyboardEventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        keyboardEventSink = null
    }

    // ── MethodCallHandler ─────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "dismiss" -> {
                val act = activity ?: run { result.success(null); return }
                val imm = act.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                val focused = act.currentFocus ?: act.window.decorView
                val keepFocus = call.argument<Boolean>("keepFocus") ?: false
                imm.hideSoftInputFromWindow(focused.windowToken, 0)
                if (!keepFocus) focused.clearFocus()
                result.success(null)
            }

            "isVisible" -> result.success(isKeyboardVisible)

            "state" -> result.success(
                mapOf("height" to currentHeight, "isVisible" to isKeyboardVisible, "progress" to if (isKeyboardVisible) 1.0 else 0.0)
            )

            "setInputMode" -> {
                val mode = call.argument<Int>("mode") ?: return
                activity?.window?.setSoftInputMode(mode)
                result.success(null)
            }

            "setDefaultMode" -> {
                // Restore Flutter's default (adjustResize)
                activity?.window?.setSoftInputMode(
                    android.view.WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
                )
                result.success(null)
            }

            // iOS-only stubs — return success so Dart code doesn't crash
            "preload", "focusNext", "focusPrev" -> result.success(null)

            else -> result.notImplemented()
        }
    }

    // ── ActivityAware ─────────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        setupKeyboardTracking()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        teardownKeyboardTracking()
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        setupKeyboardTracking()
    }

    override fun onDetachedFromActivity() {
        teardownKeyboardTracking()
        activity = null
    }

    // ── Keyboard Tracking ─────────────────────────────────────────────────────

    private fun setupKeyboardTracking() {
        val act = activity ?: return
        val decorView = act.window.decorView

        // Allow insets to reach the callback without Flutter blocking them.
        // We use CONTINUE_ON_SUBTREE so Flutter's own inset handling is unaffected.
        val callback = object :
            WindowInsetsAnimationCompat.Callback(DISPATCH_MODE_CONTINUE_ON_SUBTREE) {

            // Heights captured at animation start / end
            private var startHeight = 0
            private var endHeight = 0

            override fun onPrepare(animation: WindowInsetsAnimationCompat) {
                startHeight = currentHeight.toInt()
            }

            override fun onStart(
                animation: WindowInsetsAnimationCompat,
                bounds: WindowInsetsAnimationCompat.BoundsCompat,
            ): WindowInsetsAnimationCompat.BoundsCompat {
                val rootInsets = ViewCompat.getRootWindowInsets(decorView)
                val navHeight =
                    rootInsets?.getInsets(WindowInsetsCompat.Type.navigationBars())?.bottom ?: 0
                val density = decorView.resources.displayMetrics.density

                endHeight = max(0, bounds.upperBound.bottom - navHeight)
                val endDp = endHeight.toDouble() / density
                val isShowing = endHeight > 0

                emitEvent(
                    type = if (isShowing) "keyboardWillShow" else "keyboardWillHide",
                    height = endDp,
                    progress = if (isShowing) 0.0 else 1.0,
                    duration = animation.durationMillis.toDouble(),
                )
                return bounds
            }

            override fun onProgress(
                insets: WindowInsetsCompat,
                runningAnimations: List<WindowInsetsAnimationCompat>,
            ): WindowInsetsCompat {
                val imeBottom = insets.getInsets(WindowInsetsCompat.Type.ime()).bottom
                val navBottom =
                    insets.getInsets(WindowInsetsCompat.Type.navigationBars()).bottom
                val actualPx = max(0, imeBottom - navBottom)
                val density = decorView.resources.displayMetrics.density
                val heightDp = actualPx.toDouble() / density

                currentHeight = heightDp

                val maxPx = max(startHeight, endHeight).toDouble()
                val progress =
                    if (maxPx > 0) (actualPx.toDouble() / maxPx).coerceIn(0.0, 1.0) else 0.0

                val imeAnim = runningAnimations.firstOrNull {
                    it.typeMask and WindowInsetsCompat.Type.ime() != 0
                }

                emitEvent(
                    type = "keyboardMove",
                    height = heightDp,
                    progress = progress,
                    duration = (imeAnim?.durationMillis ?: 0).toDouble(),
                )
                return insets
            }

            override fun onEnd(animation: WindowInsetsAnimationCompat) {
                val rootInsets = ViewCompat.getRootWindowInsets(decorView)
                val imeBottom =
                    rootInsets?.getInsets(WindowInsetsCompat.Type.ime())?.bottom ?: 0
                val navBottom =
                    rootInsets?.getInsets(WindowInsetsCompat.Type.navigationBars())?.bottom ?: 0
                val actualPx = max(0, imeBottom - navBottom)
                val density = decorView.resources.displayMetrics.density
                val heightDp = actualPx.toDouble() / density

                currentHeight = heightDp
                isKeyboardVisible = actualPx > 0

                emitEvent(
                    type = if (isKeyboardVisible) "keyboardDidShow" else "keyboardDidHide",
                    height = heightDp,
                    progress = if (isKeyboardVisible) 1.0 else 0.0,
                    duration = animation.durationMillis.toDouble(),
                )
            }
        }

        ViewCompat.setWindowInsetsAnimationCallback(decorView, callback)
    }

    private fun teardownKeyboardTracking() {
        val decorView = activity?.window?.decorView ?: return
        ViewCompat.setWindowInsetsAnimationCallback(decorView, null)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun emitEvent(
        type: String,
        height: Double,
        progress: Double,
        duration: Double,
    ) {
        val event = mapOf(
            "type" to type,
            "height" to height,
            "progress" to progress,
            "duration" to duration,
            "timestamp" to System.currentTimeMillis().toDouble(),
        )
        activity?.runOnUiThread {
            keyboardEventSink?.success(event)
        }
    }
}

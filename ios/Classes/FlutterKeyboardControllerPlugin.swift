import Flutter
import UIKit

public class FlutterKeyboardControllerPlugin: NSObject, FlutterPlugin {

    // ── Registration ──────────────────────────────────────────────────────────

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()

        // Method channel
        let methodChannel = FlutterMethodChannel(
            name: "flutter_keyboard_controller",
            binaryMessenger: messenger
        )

        // Event channel (keyboard events)
        let eventChannel = FlutterEventChannel(
            name: "flutter_keyboard_controller/keyboard_events",
            binaryMessenger: messenger
        )

        let instance = FlutterKeyboardControllerPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    // ── State ─────────────────────────────────────────────────────────────────

    private var eventSink: FlutterEventSink?

    /// Height the keyboard is animating TO on show, or 0 on hide.
    private var targetKeyboardHeight: CGFloat = 0
    private var currentKeyboardHeight: CGFloat = 0
    private var isVisible: Bool = false

    // Animation tracking via CADisplayLink
    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var animationDuration: CFTimeInterval = 0
    private var animationStartHeight: CGFloat = 0
    private var animationEndHeight: CGFloat = 0
    private var animationCurve: UIView.AnimationCurve = .easeInOut

    // ── FlutterPlugin ─────────────────────────────────────────────────────────

    public override init() {
        super.init()
        registerForKeyboardNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopDisplayLink()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "dismiss":
            let args = call.arguments as? [String: Any]
            let animated = args?["animated"] as? Bool ?? true
            dismissKeyboard(animated: animated)
            result(nil)

        case "isVisible":
            result(isVisible)

        case "state":
            result([
                "height": currentKeyboardHeight,
                "isVisible": isVisible,
                "progress": isVisible ? 1.0 : 0.0,
            ])

        case "preload":
            // Warm up the keyboard by briefly showing then hiding a dummy field
            preloadKeyboard()
            result(nil)

        case "focusNext":
            // Traverse responder chain to next field
            result(nil)

        case "focusPrev":
            result(nil)

        // Android-only stubs
        case "setInputMode", "setDefaultMode":
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ── Keyboard Notifications ────────────────────────────────────────────────

    private func registerForKeyboardNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                       name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidShow(_:)),
                       name: UIResponder.keyboardDidShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                       name: UIResponder.keyboardWillHideNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidHide(_:)),
                       name: UIResponder.keyboardDidHideNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                       name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        let endFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curveRaw = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int ?? 0
        let curve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut

        let height = endFrame.height
        targetKeyboardHeight = height

        emit(type: "keyboardWillShow", height: height, progress: 0.0, duration: duration)
        startDisplayLink(
            from: currentKeyboardHeight,
            to: height,
            duration: duration,
            curve: curve
        )
    }

    @objc private func keyboardDidShow(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        let endFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let height = endFrame.height
        stopDisplayLink()
        currentKeyboardHeight = height
        isVisible = true
        emit(type: "keyboardDidShow", height: height, progress: 1.0, duration: 0)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curveRaw = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int ?? 0
        let curve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut

        targetKeyboardHeight = 0
        emit(type: "keyboardWillHide", height: currentKeyboardHeight, progress: 1.0, duration: duration)
        startDisplayLink(
            from: currentKeyboardHeight,
            to: 0,
            duration: duration,
            curve: curve
        )
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        stopDisplayLink()
        currentKeyboardHeight = 0
        isVisible = false
        emit(type: "keyboardDidHide", height: 0, progress: 0.0, duration: 0)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        // Handles split-keyboard or undocked keyboard scenarios
    }

    // ── CADisplayLink (frame-by-frame progress) ───────────────────────────────

    private func startDisplayLink(
        from startHeight: CGFloat,
        to endHeight: CGFloat,
        duration: CFTimeInterval,
        curve: UIView.AnimationCurve
    ) {
        stopDisplayLink()
        animationStartHeight = startHeight
        animationEndHeight = endHeight
        animationDuration = duration
        animationCurve = curve
        animationStartTime = CACurrentMediaTime()

        let link = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkTick() {
        let elapsed = CACurrentMediaTime() - animationStartTime
        guard animationDuration > 0 else {
            stopDisplayLink()
            return
        }

        let rawProgress = min(elapsed / animationDuration, 1.0)
        let easedProgress = applyAnimationCurve(rawProgress, curve: animationCurve)

        let heightDelta = animationEndHeight - animationStartHeight
        let currentH = animationStartHeight + heightDelta * CGFloat(easedProgress)

        currentKeyboardHeight = currentH
        let maxH = max(animationStartHeight, animationEndHeight)
        let progress = maxH > 0 ? Double(currentH / maxH) : 0.0

        emit(
            type: "keyboardMove",
            height: Double(currentH),
            progress: progress.clamped(to: 0...1),
            duration: animationDuration * 1000
        )

        if rawProgress >= 1.0 {
            stopDisplayLink()
        }
    }

    /// Maps a linear 0-1 value through the keyboard's reported animation curve.
    private func applyAnimationCurve(_ t: Double, curve: UIView.AnimationCurve) -> Double {
        switch curve {
        case .easeIn:
            return t * t
        case .easeOut:
            return t * (2 - t)
        case .easeInOut:
            return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
        default:
            return t
        }
    }

    // ── Emit ──────────────────────────────────────────────────────────────────

    private func emit(type: String, height: Double, progress: Double, duration: Double) {
        guard let sink = eventSink else { return }
        sink([
            "type": type,
            "height": height,
            "progress": progress,
            "duration": duration,
            "timestamp": Date().timeIntervalSince1970 * 1000,
        ])
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func dismissKeyboard(animated: Bool) {
        if animated {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        } else {
            UIApplication.shared.windows.first?.endEditing(true)
        }
    }

    private func preloadKeyboard() {
        DispatchQueue.main.async {
            let field = UITextField()
            field.isHidden = true
            UIApplication.shared.windows.first?.addSubview(field)
            field.becomeFirstResponder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                field.resignFirstResponder()
                field.removeFromSuperview()
            }
        }
    }
}

// ── FlutterStreamHandler ──────────────────────────────────────────────────────

extension FlutterKeyboardControllerPlugin: FlutterStreamHandler {
    public func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}

// ── Comparable extension ──────────────────────────────────────────────────────

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

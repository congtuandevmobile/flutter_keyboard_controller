import Flutter
import UIKit

public class FlutterKeyboardControllerPlugin: NSObject, FlutterPlugin {

    // ── Registration ──────────────────────────────────────────────────────────

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()

        let methodChannel = FlutterMethodChannel(
            name: "flutter_keyboard_controller",
            binaryMessenger: messenger
        )
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

    private var currentKeyboardHeight: CGFloat = 0
    private var isVisible: Bool = false

    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var animationDuration: CFTimeInterval = 0
    private var animationStartHeight: CGFloat = 0
    private var animationEndHeight: CGFloat = 0
    private var animationCurve: UIView.AnimationCurve = .easeInOut

    private var pendingDidHide = false
    // Pre-allocated event map — avoids a heap allocation on every CADisplayLink tick.
    private var reusableEvent: [String: Any] = [
        "type": "", "height": 0.0, "progress": 0.0, "duration": 0.0, "timestamp": 0.0,
    ]

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
            preloadKeyboard()
            result(nil)
        case "focusNext", "focusPrev", "setInputMode", "setDefaultMode":
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
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        let endFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curveRaw = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int ?? 0
        let curve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut

        // Cancel any pending hide — keyboard is showing again.
        pendingDidHide = false

        emit(type: "keyboardWillShow", height: Double(endFrame.height), progress: 0.0, duration: duration)
        startDisplayLink(from: currentKeyboardHeight, to: endFrame.height, duration: duration, curve: curve)
    }

    @objc private func keyboardDidShow(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        let endFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let height = endFrame.height
        stopDisplayLink()
        currentKeyboardHeight = height
        isVisible = true
        emit(type: "keyboardDidShow", height: Double(height), progress: 1.0, duration: 0)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let info = notification.userInfo else { return }
        let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curveRaw = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int ?? 0
        let curve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut

        emit(type: "keyboardWillHide", height: Double(currentKeyboardHeight), progress: 1.0, duration: duration)
        startDisplayLink(from: currentKeyboardHeight, to: 0, duration: duration, curve: curve)
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        isVisible = false

        if displayLink != nil {
            // Display link is still in flight — defer the event.
            pendingDidHide = true
        } else {
            // Display link already finished; emit immediately.
            currentKeyboardHeight = 0
            emit(type: "keyboardDidHide", height: 0, progress: 0.0, duration: 0)
        }
    }

    private func startDisplayLink(
        from startHeight: CGFloat,
        to endHeight: CGFloat,
        duration: CFTimeInterval,
        curve: UIView.AnimationCurve
    ) {
        stopDisplayLink()
        
        guard duration > 0 else {
            currentKeyboardHeight = endHeight
            let maxH = max(startHeight, endHeight)
            let progress = maxH > 0 ? Double(endHeight / maxH) : 0.0
            
            emit(type: "keyboardMove", height: Double(endHeight), progress: progress, duration: 0)
            if pendingDidHide {
                pendingDidHide = false
                emit(type: "keyboardDidHide", height: 0, progress: 0.0, duration: 0)
            }
            return
        }

        animationStartHeight = startHeight
        animationEndHeight = endHeight
        animationDuration = duration
        animationCurve = curve
        animationStartTime = CACurrentMediaTime()
        pendingDidHide = false 

        let proxy = WeakTargetProxy(target: self, selector: #selector(displayLinkTick))
        let link = CADisplayLink(target: proxy, selector: #selector(WeakTargetProxy.timerFired(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkTick() {
        let elapsed = CACurrentMediaTime() - animationStartTime
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
            finishDisplayLink()
        }
    }

    /// Called when the display link animation reaches its end frame.
    /// Stops the link and — if a hide was pending — emits `didHide`.
    private func finishDisplayLink() {
        stopDisplayLink()

        if pendingDidHide {
            pendingDidHide = false
            currentKeyboardHeight = 0
            emit(type: "keyboardDidHide", height: 0, progress: 0.0, duration: 0)
        }
    }

    private func applyAnimationCurve(_ t: Double, curve: UIView.AnimationCurve) -> Double {
        if curve.rawValue == 7 {
            let inv = 1.0 - t
            return 1.0 - (inv * inv * inv)
        }
        
        switch curve {
        case .easeIn:      return t * t
        case .easeOut:     return t * (2 - t)
        case .easeInOut:   return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
        default:           return t
        }
    }

    // ── Emit ──────────────────────────────────────────────────────────────────

    private func emit(type: String, height: Double, progress: Double, duration: Double) {
        guard let sink = eventSink else { return }
        reusableEvent["type"] = type
        reusableEvent["height"] = height
        reusableEvent["progress"] = progress
        reusableEvent["duration"] = duration
        reusableEvent["timestamp"] = Date().timeIntervalSince1970 * 1000
        sink(reusableEvent)
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

// ── Extensions ────────────────────────────────────────────────────────────────

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

class WeakTargetProxy {
    weak var target: AnyObject?
    let selector: Selector

    init(target: AnyObject, selector: Selector) {
        self.target = target
        self.selector = selector
    }

    @objc func timerFired(_ link: CADisplayLink) {
        if let target = target {
            _ = target.perform(selector, with: nil)
        } else {
            link.invalidate()
        }
    }
}

Pod::Spec.new do |s|
  s.name             = 'flutter_keyboard_controller'
  s.version          = '1.0.3'
  s.summary          = 'Flutter plugin for targeted keyboard animation via ValueNotifier — chat, toolbar, and sticky widgets included.'
  s.description      = <<-DESC
    Provides frame-by-frame keyboard animation tracking for Flutter. 
    It exposes keyboard height, transition progress (0.0 - 1.0), and lifecycle events 
    via ValueNotifiers, ensuring only subscribed leaf widgets rebuild rather than the entire layout tree. 
    Includes out-of-the-box widgets: KeyboardChatScrollView, KeyboardToolbar,
    KeyboardStickyView, KeyboardAwareScrollView, and KeyboardAvoidingView. 
    On iOS, it leverages CADisplayLink for pixel-perfect synchronization and interactive-dismiss tracking.
  DESC
  s.homepage         = 'https://github.com/congtuandevmobile/flutter_keyboard_controller'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Tuan Nguyen Cong' => 'nguyencongtuan.devmobile@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency         'Flutter'
  s.platform         = :ios, '13.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE'                      => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end

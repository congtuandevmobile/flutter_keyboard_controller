Pod::Spec.new do |s|
  s.name             = 'flutter_keyboard_controller'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for smooth, frame-by-frame keyboard animation tracking.'
  s.description      = <<-DESC
    Mirrors react-native-keyboard-controller for Flutter.
    Provides KeyboardProvider, KeyboardAvoidingView, KeyboardAwareScrollView,
    KeyboardStickyView, KeyboardToolbar, and KeyboardChatScrollView with
    native frame-by-frame keyboard animation tracking via CADisplayLink.
  DESC
  s.homepage         = 'https://github.com/your-org/flutter_keyboard_controller'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
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

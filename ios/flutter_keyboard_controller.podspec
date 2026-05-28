Pod::Spec.new do |s|
  s.name             = 'flutter_keyboard_controller'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for smooth, frame-by-frame keyboard animation tracking.'
  s.description      = <<-DESC
    Smooth, frame-by-frame keyboard animation tracking for Flutter.
    Provides KeyboardProvider, KeyboardAvoidingView, KeyboardAwareScrollView,
    KeyboardStickyView, KeyboardToolbar, and KeyboardChatScrollView with
    native per-frame keyboard height updates via CADisplayLink on iOS.
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

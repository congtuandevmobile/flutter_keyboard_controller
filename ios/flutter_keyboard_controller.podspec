Pod::Spec.new do |s|
  s.name             = 'flutter_keyboard_controller'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for targeted keyboard animation via ValueNotifier — chat, toolbar, and sticky widgets included.'
  s.description      = <<-DESC
    Exposes keyboard height, progress (0-1), and lifecycle events (willShow/didShow/move)
    via ValueNotifier so only subscribed widgets rebuild — not the entire tree.
    Includes KeyboardChatScrollView, KeyboardToolbar, KeyboardStickyView,
    KeyboardAwareScrollView, and KeyboardAvoidingView widgets.
    iOS uses CADisplayLink for accurate interactive-dismiss tracking.
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

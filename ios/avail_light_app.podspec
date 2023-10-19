
Pod::Spec.new do |s|
  s.name             = 'Flutter'
  s.version          = '1.0.0'
  s.summary          = 'A UI toolkit for beautiful and fast apps.'
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :git => 'https://github.com/flutter/engine', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  # Framework linking is handled by Flutter tooling, not CocoaPods.
  # Add a placeholder to satisfy `s.dependency 'Flutter'` plugin podspecs.
  s.vendored_frameworks = 'path/to/nothing'
  s.public_header_files = 'Classes**/*.h'
  s.source_files = 'Classes/**/*'
  s.static_framework = true
  s.vendored_libraries = "**/*.a"
end

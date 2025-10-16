#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint headphones_detection.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'headphones_detection'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter plugin to detect headphones connection status on Android and iOS devices.'
  s.description      = <<-DESC
A Flutter plugin to detect headphones connection status on Android and iOS devices.
                       DESC
  s.homepage         = 'https://github.com/alxmoroz/headphones_detection'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Alexandr Moroz' => 'alexandrmoroz@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

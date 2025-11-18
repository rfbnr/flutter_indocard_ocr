#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_indocard_ocr.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_indocard_ocr'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for Indonesian ID card OCR using Apple Vision.'
  s.description      = <<-DESC
flutter_indocard_ocr is a simple Flutter plugin for recognizing Indonesian ID cards (KTP, NPWP) using native OCR (Optical Character Recognition) engines — Google ML Kit on Android and Apple Vision on iOS.
                       DESC
  s.homepage         = 'https://github.com/rfbnr/flutter_indocard_ocr'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.5'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.5'

  s.ios.frameworks = 'Vision'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_indocard_ocr_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end

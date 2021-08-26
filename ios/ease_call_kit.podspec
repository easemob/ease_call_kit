#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ease_call_kit.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ease_call_kit'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.dependency 'EaseCallKit', '3.8.1.1'
  s.dependency 'AgoraRtcEngine_iOS', '3.3.0'
  s.dependency 'Masonry'
  s.dependency 'SDWebImage'
  s.dependency 'HyphenateChat', '~>3.8.3.1'
  s.dependency 'MBProgressHUD'
  
end

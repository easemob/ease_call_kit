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
  s.source           = { :git => 'http://XXX/EaseCallKit.git', :tag => s.version.to_s }
  s.source_files  = "Classes", "Classes/**/*.{h,m}"
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'
  
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.subspec 'EaseCallKit' do |callkit|
    callkit.frameworks = 'UIKit'
    callkit.libraries = 'stdc++'
    callkit.ios.deployment_target = '9.0'
    callkit.source_files = '../../callkit/Classes/**/*.{h,m}'
    callkit.public_header_files = [
      '../../callkit/Classes/Process/EaseCallManager.h',
      '../../callkit/Classes/Utils/EaseCallDefine.h',
      '../../callkit/Classes/Utils/EaseCallError.h',
      '../../callkit/Classes/Store/EaseCallConfig.h',
      '../../callkit/Classes/EaseCallUIKit.h',
    ]
    callkit.resources = '../../callkit/Assets/EaseCall.bundle'
    callkit.dependency 'HyphenateLite', '~> 3.7.4'
    callkit.dependency 'Masonry'
    callkit.dependency 'AgoraRtcEngine_iOS'
    callkit.dependency 'SDWebImage', '~> 3.7.2'
  end
end

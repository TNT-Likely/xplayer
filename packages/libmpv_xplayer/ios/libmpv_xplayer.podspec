#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint libmpv_xplayer.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  raise "libmpv_xplayer native build failed" unless system("make")
  raise "libmpv_xplayer headers failed" unless system('make -C ../darwin HEADERS_DESTDIR="$(pwd)/Headers"')

  s.name             = 'libmpv_xplayer'
  s.version          = '0.1.0'
  s.summary          = 'Complete native playback assets for XPlayer on iOS'
  s.description      = <<-DESC
  Complete native playback assets for XPlayer on iOS.
                       DESC
  s.homepage         = 'https://github.com/TNT-Likely/xplayer'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'TNT-Likely'

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift', 'Headers/**/*.h'
  s.dependency 'Flutter'

  s.vendored_frameworks = 'Frameworks/*.xcframework'

  s.platform = :ios, '9.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_LDFLAGS' => '$(inherited) -framework Mpv',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GL_SILENCE_DEPRECATION COREVIDEO_SILENCE_GL_DEPRECATION',
    # Flutter.framework does not contain a i386 slice.
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'
end

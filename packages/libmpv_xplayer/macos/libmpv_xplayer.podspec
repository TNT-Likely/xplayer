#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint libmpv_xplayer.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  raise "libmpv_xplayer native build failed" unless system("make")
  raise "libmpv_xplayer headers failed" unless system('make -C ../darwin HEADERS_DESTDIR="$(pwd)/Headers"')

  s.name             = 'libmpv_xplayer'
  s.version          = '0.1.0'
  s.summary          = 'Complete native playback assets for XPlayer on macOS'
  s.description      = <<-DESC
  Complete native playback assets for XPlayer on macOS.
                       DESC
  s.homepage         = 'https://github.com/TNT-Likely/xplayer'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'TNT-Likely'

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift', 'Headers/**/*.h'
  s.dependency 'FlutterMacOS'

  s.vendored_frameworks = 'Frameworks/*.xcframework'

  s.platform = :osx, '10.9'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'OTHER_LDFLAGS' => '$(inherited) -framework Mpv', 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GL_SILENCE_DEPRECATION COREVIDEO_SILENCE_GL_DEPRECATION' }
  s.swift_version = '5.0'
end

Pod::Spec.new do |s|
  s.name = 'xplayer_storekit'
  s.version = '1.0.0'
  s.summary = 'StoreKit membership for XPlayer'
  s.homepage = 'https://github.com/TNT-Likely/xplayer'
  s.license = { :type => 'MIT' }
  s.author = 'XPlayer contributors'
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*.swift'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.frameworks = 'StoreKit'
  s.swift_version = '5.0'
end

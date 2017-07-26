Pod::Spec.new do |s|
  s.name             = "IOCipher"
  s.version          = "0.1.0"
  s.summary          = "Objective-C wrapper for libsqlfs and SQLCipher to create virtual encrypted file systems."
  s.homepage         = "https://github.com/chrisballinger/IOCipher"
  s.license          = 'LGPLv2.1+'
  s.author           = { "Chris Ballinger" => "chris@chatsecure.org" }
  s.source           = { :git => "https://github.com/chrisballinger/IOCipher.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ChatSecure'

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.8'
  s.requires_arc = true

  s.default_subspec = 'standard'

  s.subspec 'common' do |ss|
    ss.source_files = 'IOCipher/*.{h,m}'
    ss.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DHAVE_LIBSQLCIPHER -DSQLITE_HAS_CODEC' }
    ss.dependency 'libsqlfs/SQLCipher'
    ss.dependency 'CocoaLumberjack'
  end

  s.subspec 'standard' do |ss|
    ss.dependency 'IOCipher/common'
  end

  s.subspec 'GCDWebServer' do |ss|
    ss.source_files = 'IOCipher/GCDWebServer/*.{h,m}'
    ss.dependency 'IOCipher/common'
    ss.dependency 'GCDWebServer'
  end
end

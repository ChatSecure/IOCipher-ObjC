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

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'IOCipher' => ['Pod/Assets/*.png']
  }

  s.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -DHAVE_LIBSQLCIPHER -DSQLITE_HAS_CODEC' }

  s.dependency 'libsqlfs/SQLCipher'
end

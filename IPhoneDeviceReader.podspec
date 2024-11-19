Pod::Spec.new do |s|
  s.name        = "IPhoneDeviceReader"
  s.version     = "1.0.4"
  s.summary     = "A library for reading files from iPhone."
  s.homepage    = "https://github.com/kelvinjjwong/IPhoneDeviceReader"
  s.license     = { :type => "MIT" }
  s.authors     = { "kelvinjjwong" => "kelvinjjwong@outlook.com" }

  s.requires_arc = true
  s.swift_version = "5.0"
  s.osx.deployment_target = "14.0"
  s.source   = { :git => "https://github.com/kelvinjjwong/IPhoneDeviceReader.git", :tag => s.version }
  s.source_files = "Sources/IPhoneDeviceReader/**/*.swift"
    
  s.dependency 'LoggerFactory', '~> 1.1.1'
  s.dependency 'SharedDeviceLib', '~> 1.0.3'
end

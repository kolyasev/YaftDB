Pod::Spec.new do |s|
  s.name             = "YaftDB"
  s.version          = "0.1.5"
  s.summary          = "Yet another Swift wrapper for YapDatabase"
  s.homepage         = "https://github.com/kolyasev/YaftDB"
  s.license          = 'MIT'
  s.author           = { "Denis Kolyasev" => "kolyasev@gmail.com" }
  s.source           = { :git => "https://github.com/kolyasev/YaftDB.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Source/**/*.swift'

  s.frameworks =  'Foundation', 'UIKit'
  s.dependency 'YapDatabase', '~> 2.9'
end

Pod::Spec.new do |s|


  s.name         = "Batching"
  s.version      = "0.0.8"
  s.summary      = "A batching library for the analytics events."

  s.homepage     = "https://github.com/arorajatin"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Jatin" => "jatinarora269@gmail.com" }
  s.social_media_url   = "https://twitter.com/jatinarora269"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://gitlab.phonepe.com/iOS/Batching.git", :tag => "#{s.version}" }


  s.source_files  = "Batching", "Batching/**/*.{swift}"

  s.frameworks = "UIKit", "Foundation"

  s.requires_arc = true

  s.dependency 'YapDatabase', '~> 2.9'

end

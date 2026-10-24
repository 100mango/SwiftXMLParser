Pod::Spec.new do |s|
  s.name         = "SwiftXMLParser"
  s.version      = "0.2.0"
  s.summary      = "A Foundation-based XML dictionary utility written in Swift."
  s.description  = <<-DESC
    Parse element-only XML into dictionaries and serialize dictionary values as XML.
  DESC
  s.homepage     = "https://github.com/100mango/SwiftXMLParser"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "100mango" => "100mango@gmail.com" }
  s.social_media_url   = ""
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/100mango/SwiftXMLParser.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*"
  s.frameworks  = "Foundation"
end

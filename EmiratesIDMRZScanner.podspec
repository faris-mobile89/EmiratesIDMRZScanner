#
# Be sure to run `pod lib lint EmiratesIDMRZScanner.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EmiratesIDMRZScanner'
  s.version          = '1.1.0'
  s.summary          = 'Emirates ID MRZ scanner'
  s.swift_version = "4.2"
  
# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Emirates ID Scanner to scan MRZ code
                       DESC

  s.homepage         = 'https://github.com/faris.it.cs@gmail.com/EmiratesIDMRZScanner'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'faris.it.cs@gmail.com' => 'outsource.fn@tra.gov.ae' }
  s.source           = { :git => 'https://github.com/faris.it.cs@gmail.com/EmiratesIDMRZScanner.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'EmiratesIDMRZScanner/Classes/**/*'
  s.resources    = "EmiratesIDMRZScanner/Supporting Files/tessdata"
  
  s.frameworks   =  "Foundation", "UIKit", "AVFoundation", "CoreImage", "AudioToolbox"
  
  s.dependency "EVGPUImage2"
  s.dependency "QKMRZParser"
  s.dependency "SwiftyTesseract"
  
  # s.resource_bundles = {
  #   'EmiratesIDMRZScanner' => ['EmiratesIDMRZScanner/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

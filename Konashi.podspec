#
# Be sure to run `pod lib lint Konashi.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'Konashi'
    s.version          = '0.0.1'
    s.summary          = 'iOS SDK for konashi, a wireless physical computing toolkit for iPhone, iPod touch and iPad.'
    s.swift_versions   = '5.4'
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  
    s.description      = <<-DESC
    iOS SDK for konashi, a wireless physical computing toolkit for iPhone, iPod touch and iPad.
                         DESC
  
    s.homepage         = 'https://github.com/YUKAI/konashi-ios-sdk2'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
    s.author           = { 'YUKAI Engineering.Inc' => 'contact@ux-xu.com' }
    s.source           = { :git => 'https://github.com/YUKAI/konashi-ios-sdk2.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  
    s.ios.deployment_target = '13.0'
  
    s.source_files = 'Sources/**/**.swift'
    
    # s.resource_bundles = {
    #   'Konashi' => ['Konashi/Assets/*.png']
    # }
  
    # s.public_header_files = 'Pod/Classes/**/*.h'
    # s.frameworks = 'UIKit', 'MapKit'
    s.framework  = 'CoreBluetooth'
    s.dependency 'PromisesSwift', '~> 2.0.0'
    s.dependency 'CombineExt', '~> 1.0.0'
  end
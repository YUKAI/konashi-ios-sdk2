#
# Be sure to run `pod lib lint Konashi.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'konashi-ios-sdk2'
    s.module_name      = 'Konashi'
    s.version          = '1.0.0'
    s.summary          = 'iOS SDK for konashi, a wireless physical computing toolkit'
    s.swift_versions   = '5.7'
    s.description      = <<-DESC
      Konashi communicates directly with any iPhone, iPod touch, and iPad which supports Bluetooth Low Energy (BLE) technology. You do not need to apply for an MFi License.
    DESC
  
    s.homepage         = 'https://github.com/YUKAI/konashi-ios-sdk2'
    s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
    s.author           = { 'YUKAI Engineering.Inc' => 'contact@ux-xu.com' }
    s.source           = { :git => 'https://github.com/YUKAI/konashi-ios-sdk2.git', :tag => s.version.to_s }
  
    s.ios.deployment_target = '13.0'
    s.static_framework = true
    s.source_files = 'Sources/**/**.swift'
  
    s.framework  = 'CoreBluetooth'
    s.dependency 'PromisesSwift', '>= 2.1.0'
    s.dependency 'CombineExt', '>= 1.0.0'
    s.dependency 'nRFMeshProvision', '>= 3.2.0'
  end

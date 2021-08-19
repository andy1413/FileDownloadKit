#when call lint should use following command: 
#pod spec lint --sources=https://git.apuscn.com:8443/New-Pika/ViekaPodSpecsRepo,master FileDownloadKit.podspec --allow-warnings
#when call push should use following command:
#pod repo push --sources=https://git.apuscn.com:8443/New-Pika/ViekaPodSpecsRepo,master ViekaPodSpecsRepo FileDownloadKit.podspec --allow-warnings
#
# Be sure to run `pod lib lint FileDownloadKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'FileDownloadKit'
  s.version          = '0.1.19'
  s.summary          = 'A short description of FileDownloadKit.'
# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://git.apuscn.com:8443/New-Pika/FileDownloadKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'anddygon@gmail.com' => 'gongxiaopeng@apusapps.com' }
  s.source           = { :git => 'git@git.apuscn.com:New-Pika/FileDownloadKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.ios.deployment_target = '11.0'
  s.source_files = 'FileDownloadKit/Classes/**/*'
  
  # s.resource_bundles = {
  #   'FileDownloadKit' => ['FileDownloadKit/Assets/*.png']
  # }
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'LzmaSDK-ObjC', '~> 2.1.1'
  s.dependency 'Zip', '~> 2.1.1'
  s.dependency 'Alamofire', '~> 5.0'
end
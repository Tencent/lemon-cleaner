#
# Be sure to run `pod lib lint LemonBigOldFile.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LemonBigOldFile'
  s.version          = '0.1.0'
  s.summary          = 'A short description of LemonBigOldFile.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/lemon/LemonBigOldFile'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'lemon' => 'lemon@tencent.com' }
  s.source           = { :git => 'https://github.com/lemon/LemonBigOldFile.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform = :osx
  s.osx.deployment_target = "10.11"

  s.source_files = 'LemonBigOldFile/Classes/**/*'

  s.resources = ['LemonBigOldFile/Assets/**/*']
  
  s.dependency 'AFNetworking', '3.2.1'
  s.dependency "QMCoreFunction"
  s.dependency "Masonry", '1.1.0'
  s.dependency "QMUICommon"

  s.public_header_files = 'LemonBigOldFile/Classes/Controller/McBigFileWndController.h'
  s.dependency 'LemonFileManager'
  # s.frameworks = 'Cocoa'
  # s.dependency 'AFNetworking', '~> 2.3'
end

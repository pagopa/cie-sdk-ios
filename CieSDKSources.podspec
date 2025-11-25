#
# Be sure to run `pod lib lint cie-sdk-ios.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CieSDK'
  s.version          = '0.1.15'
  s.summary          = 'A native SDK for reading the Italian EIC (CIE).'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  A native SDK for reading the Italian Electronic Identity Card (CIE).
                       DESC

  s.homepage         = 'https://github.com/pagopa/cie-sdk-ios'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'PagoPA S.p.A.' => 'ioapptech@pagopa.it' }
  s.source           = { :git => 'https://git@github.com/pagopa/cie-sdk-ios.git', tag: s.version }
 
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.prepare_command = './.build.sh'

  s.ios.vendored_frameworks = ".archives/CieSDK.xcframework"

end

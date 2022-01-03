#
# Be sure to run `pod lib lint BikeBLE.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BikeBLE'
  s.version          = '1.0.1'
  s.summary          = 'A short description of BikeBLE.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/LucaDonetti/BLE'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'luca.donetti@akka.eu' => 'luca.donetti@akka.eu' }
  s.source           = { :git => 'https://github.com/LucaDonetti/BLE.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.1'

  s.source_files = 'Classes/**/*'
  
  s.frameworks = 'Foundation'
  
  s.dependency 'Bluejay'
  s.dependency 'XCGLogger', '~> 6.1.0'
  s.dependency 'PromiseKit', '~> 6.8.3'
  s.dependency 'ZIPFoundation', '~> 0.9.9'
end

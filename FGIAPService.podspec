#
# Be sure to run `pod lib lint FGIAPService.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FGIAPService'
  s.version          = '0.5.0'
  s.summary          = 'IAP helper for Apple in app purchases.'
  s.description      = <<-DESC
                            FGIAPService is a simple wrapper for Apple in app purchases..

                            Features
                              - Simple interface
                       DESC
  s.homepage         = 'https://github.com/FoneG/FGIAPService'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '15757127193@163.com' => '15757127193@163.com' }
  s.source           = { :git => 'https://github.com/FoneG/FGIAPService.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'FGIAPService/Classes/**/*'
  s.framework  = 'StoreKit'
end

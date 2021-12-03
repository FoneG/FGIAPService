Pod::Spec.new do |s|
  s.name = "FGIAPService"
  s.version = "0.4.0"
  s.summary = "IAP helper for Apple in app purchases."
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"15757127193@163.com"=>"15757127193@163.com"}
  s.homepage = "https://github.com/FoneG/FGIAPService"
  s.description = "FGIAPService is a simple wrapper for Apple in app purchases..\n\nFeatures\n  - Simple interface"
  s.frameworks = "StoreKit"
  s.source = { :path => '.' }

  s.ios.deployment_target    = '9.0'
  s.ios.vendored_framework   = 'ios/FGIAPService.embeddedframework/FGIAPService.framework'
end

#
# Be sure to run `pod lib lint Aurum.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Aurum'
  s.version          = '0.1.0'
  s.summary          = 'A simple ribrary for StoreKit with verifying receipt on server.'
  s.description      = <<-DESC
                       Aurum is a simple library for StoreKit.
                       It design for using server receipt verification.
                       DESC
  s.homepage         = 'https://github.com/mihyaeru21/Aurum'
  s.license          = 'MIT'
  s.author           = { 'Mihyaeru' => 'mihyaeru21@gmail.com' }
  s.source           = { :git => 'https://github.com/mihyaeru21/Aurum.git', :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'Aurum' => ['Pod/Assets/*.png']
  }

  s.frameworks = 'StoreKit'
end

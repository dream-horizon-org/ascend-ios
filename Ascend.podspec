# Ascend.podspec
# CocoaPods podspec for ascend-ios
# This allows CocoaPods to use the same source files as SPM
#
# DISTRIBUTION:
# - For clients: Use Git URL (see line 17)
# - For local dev: Override in Podfile with :path => '../ascend-ios'
#
# Usage in Podfile:
#   pod 'Ascend', :git => 'https://github.com/your-org/ascend-ios.git', :tag => '1.0.0'
#   # OR for local development:
#   pod 'Ascend', :path => '../ascend-ios'

Pod::Spec.new do |s|
  s.name             = 'Ascend'
  s.version          = '1.0.0'
  s.summary          = 'Ascend iOS SDK'
  s.description      = 'iOS SDK for Ascend experiments and feature flags'
  s.homepage         = 'https://github.com/dream11/ascend-ios'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Ascend Team' => 'support@dream11.com' }
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  
  # Git distribution (for external clients)
  # UPDATE THIS URL with your actual repository!
  s.source           = { :git => 'https://github.com/dream11/ascend-ios', :tag => s.version }
  
  # Point to source files (same as SPM uses)
  s.source_files     = 'Sources/**/*.swift'
  
  s.frameworks = 'Foundation', 'UIKit', 'SystemConfiguration', 'CoreLocation'
  
  # Exclude tests
  s.exclude_files = 'Sources/**/*Tests.swift', '**/Tests/**'
end

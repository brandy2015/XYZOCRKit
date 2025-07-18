Pod::Spec.new do |s|
  s.name         = 'XYZOCRKit'
  s.version      = '0.1.0'
  s.summary      = 'A lightweight, extensible OCR toolkit for iOS in Swift.'
  s.homepage     = 'https://github.com/你的GitHub账户/XYZOCRKit'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'YourName' => 'your@email.com' }
  s.source       = { :git => 'https://github.com/你的GitHub账户/XYZOCRKit.git', :tag => s.version.to_s }
  s.platform     = :ios, '12.0'
  s.swift_version = '5.0'
  s.source_files = 'XYZOCRKit/Classes/**/*'
  s.requires_arc = true
  s.frameworks   = 'Foundation', 'UIKit'
  # s.dependency   'RxSwift', '~> 6.0'   # 如需要依赖可解开
end

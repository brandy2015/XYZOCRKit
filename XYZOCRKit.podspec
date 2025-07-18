Pod::Spec.new do |s|
  s.name         = "XYZOCRKit"
  s.version      = "0.1.0"
  s.summary      = "A lightweight OCR toolkit for iOS with RxSwift integration."
  s.description  = <<-DESC
    XYZOCRKit 是一个基于 RxSwift 的轻量级 OCR 文字识别工具包，
    支持主流本地与云端 OCR 能力，内置跳转、数据存储、响应式数据流等常用功能扩展。
  DESC
  s.homepage     = "https://github.com/brandy2015/XYZOCRKit"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Brando" => "zhangqianbrandy2012@gmail.com" }
  s.source       = { :git => "https://github.com/brandy2015/XYZOCRKit.git", :tag => s.version.to_s }

  s.swift_version = "5.0"
  s.ios.deployment_target = "13.0"

  s.source_files = "XYZOCRKit/Classes/**/*"

  # 第三方依赖
  s.dependency 'SoHow'
  s.dependency 'XYZVCX'

  s.dependency 'Disk'
  s.dependency 'SwiftyJSON'
  s.dependency 'Alamofire'
  s.dependency 'SnapKit'
  s.dependency 'CryptoSwift'

  # 响应式开发
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'RxAlamofire'

  # OCR / 云服务
  # s.dependency 'AlibabacloudOcrApi20210707'    # 如需阿里云OCR可解开
  # s.dependency 'ocr-api-20210707'              # 如需自定义API可解开
  s.dependency 'AWSCore'
  s.dependency 'AWSTextract'
end

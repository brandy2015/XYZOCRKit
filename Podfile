 
platform :ios, '16.0'

target 'XYZOCRKit' do
  use_frameworks!

  # -----------------
  # 自己的库
  # -----------------
  pod 'SoHow'
  pod 'XYZVCX'                # 跳转功能

  # -----------------
  # 第三方依赖
  # -----------------
  pod 'Disk'
  pod 'SwiftyJSON'            # , '4.0' 可指定版本
  pod 'Alamofire'
  pod 'SnapKit'
  pod 'CryptoSwift'

  # -----------------
  # 响应式开发
  # -----------------
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxAlamofire'

  # -----------------
  # OCR / 云服务
  # -----------------
  # pod "AlibabacloudOcrApi20210707"
  # pod "ocr-api-20210707"

  # 亚马逊OCR
  pod 'AWSCore'
  pod 'AWSTextract'
end

post_install do |installer|
  # 获取主工程 DEVELOPMENT_TEAM
  dev_team = ""
  project = installer.aggregate_targets[0].user_project
  project.targets.each do |target|
    target.build_configurations.each do |config|
      if dev_team.empty? && !config.build_settings['DEVELOPMENT_TEAM'].nil?
        dev_team = config.build_settings['DEVELOPMENT_TEAM']
      end
    end
  end

  # 配置Pods工程的相关设置
  installer.pods_project.targets.each do |target|
    # 设置开发团队
    if target.respond_to?(:product_type) && target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
        config.build_settings['DEVELOPMENT_TEAM'] = dev_team
      end
    end

    # 统一最低部署版本
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end

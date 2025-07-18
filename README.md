# XYZOCRKit

轻量级、易扩展的 iOS OCR 工具库（私有 Pod）

---

## 简介

`XYZOCRKit` 提供 OCR（光学字符识别）相关的高效 API，专为 iOS 私有项目开发，支持 Swift 5，便于二次封装和团队协作。

---

## 安装

### 方式一：通过私有 Git 仓库

在你的 `Podfile` 添加：

```ruby
pod 'XYZOCRKit', :git => 'https://your.git.repo/XYZOCRKit.git', :tag => '0.1.0'

方式二：通过私有 podspec 仓库
	1.	首次添加私有 spec 源（仅需一次）：
source 'https://your.git.repo/iOSPodsSpecs.git'
source 'https://cdn.cocoapods.org/'source 'https://your.git.repo/iOSPodsSpecs.git'
source 'https://cdn.cocoapods.org/'


2.	在 Podfile 添加：
pod 'XYZOCRKit', '~> 0.1.0'

方式三：本地开发测试
pod 'XYZOCRKit', :path => '../XYZOCRKit'

快速开始
import XYZOCRKit

let image = UIImage(named: "test_sample.jpg")!
let result = XYZOCRKit.shared.recognizeText(in: image)
print(result.text)

防御性检测图片

if XYZOCRKit.shared.isValid(image: image) {
    // 可以安全识别
}

版本和维护
	•	当前版本：0.1.0
	•	仅限公司/团队内部使用，禁止外泄
	•	如需新增功能或修复 bug，请提 Pull Request 或联系维护人




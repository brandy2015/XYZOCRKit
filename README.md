[English](README_EN.md) | [中文](README.md)


# XYZOCRKit

轻量级、易扩展的 iOS OCR 工具库（开源 Pod）

---

## 简介

XYZOCRKit 提供 OCR（光学字符识别）相关的高效 API，专为 iOS 应用开发，支持 Swift 5，便于二次封装和团队协作。

---

## 特性

- 🚀 高效本地图片转文字识别
- 🛡 防御性图片安全检测
- 🛠 简洁 API，易于集成与扩展
- 📦 支持 CocoaPods 公共源一键集成

--- 
### 支持的平台

已集成的第三方 OCR 库：

1. **OCR_Tencent**（腾讯云 OCR）
2. **OCR_HuaWei**（华为云 OCR）
3. **OCR_Google**（Google Vision OCR）
4. **OCR_Face++旷世**（Face++ 旷视 OCR）
5. **OCR_Baidu**（百度 OCR）
6. **OCR_AWS**（Amazon AWS Textract/Comprehend 等 OCR）
7. **OCR_AliBaBailian_阿里百炼**（阿里云百炼 OCR）
8. **OCR_Alibaba阿里云**（阿里云标准 OCR）
9. **OCR_科大讯飞**（科大讯飞 OCR）

---

 
## 安装

在你的 Podfile 添加：

    pod 'XYZOCRKit' 

然后运行：

    pod install

如需本地开发或测试：

    pod 'XYZOCRKit', :path => '../XYZOCRKit'

---

## 快速开始

    import XYZOCRKit

    let image = UIImage(named: "test_sample.jpg")!
    let result = XYZOCRKit.shared.recognizeText(in: image)
    print(result.text)

---

## 防御性检测图片

    if XYZOCRKit.shared.isValid(image: image) {
        // 可以安全识别
    }

---

## API 说明

- XYZOCRKit.shared.recognizeText(in image: UIImage) -> OCRResult  
  图片转文本，返回识别结果结构体

- XYZOCRKit.shared.isValid(image: UIImage) -> Bool  
  检查图片是否可识别/有效

### OCRResult 结构

    public struct OCRResult {
        public let text: String      // 识别到的全部文本
        public let lines: [String]   // 按行分割的文本数组
    }

---

## 兼容性

- iOS 13.0+
- Swift 5.0+
- Xcode 13/14/15/16

---

## 版本和维护

- 当前版本：0.1.0
- 欢迎 Issue/PR 与功能建议！

---

## 许可证

MIT

---

欢迎贡献和反馈，开源社区共建！
 


 
# XYZOCRKit

A lightweight and extensible iOS OCR toolkit (Open Source Pod)

---

## Introduction

XYZOCRKit provides efficient APIs for Optical Character Recognition (OCR), designed for iOS app development.  
It is built with Swift 5 and is easy for both individual and team integration or secondary development.

---

## Features

- 🚀 High-performance local image-to-text recognition
- 🛡 Defensive image safety validation
- 🛠 Simple API, easy to integrate and extend
- 📦 One-line integration with the public CocoaPods repo

---
### Supported Platforms

Integrated third-party OCR providers:

1. **OCR_Tencent** (Tencent Cloud OCR)
2. **OCR_HuaWei** (Huawei Cloud OCR)
3. **OCR_Google** (Google Vision OCR)
4. **OCR_Face++** (Face++ Megvii OCR)
5. **OCR_Baidu** (Baidu OCR)
6. **OCR_AWS** (Amazon AWS Textract/Comprehend OCR)
7. **OCR_AliBaBailian** (Alibaba Bailian OCR)
8. **OCR_Alibaba** (Alibaba Cloud Standard OCR)
9. **OCR_Iflytek** (iFLYTEK OCR)

---

## Installation

Add the following to your Podfile:

    pod 'XYZOCRKit' 

Then run:

    pod install

For local development or debugging:

    pod 'XYZOCRKit', :path => '../XYZOCRKit'

---
### SPM (Swift Package Manager)

Supports integration via Swift Package Manager (Xcode 11+).

**Steps:**
1. In Xcode, go to `File > Add Packages...`
2. Enter repository URL:

        https://github.com/brandy/XYZOCRKit.git

3. Select version or branch and click “Add Package”
4. In your code, simply `import XYZOCRKit`

---

## Quick Start

    import XYZOCRKit

    let image = UIImage(named: "test_sample.jpg")!
    let result = XYZOCRKit.shared.recognizeText(in: image)
    print(result.text)

---

## Defensive Image Validation

    if XYZOCRKit.shared.isValid(image: image) {
        // Safe for recognition
    }

---

## API Reference

- XYZOCRKit.shared.recognizeText(in image: UIImage) -> OCRResult  
  Converts image to text, returning a structured result.

- XYZOCRKit.shared.isValid(image: UIImage) -> Bool  
  Checks if the image is valid/recognizable.

### OCRResult Structure

    public struct OCRResult {
        public let text: String      // All recognized text
        public let lines: [String]   // Array of text, line by line
    }

---

## Compatibility

- iOS 13.0+
- Swift 5.0+
- Xcode 13/14/15/16

---

## Version & Maintenance

- Current version: 0.1.0
- Issues/PRs and feature suggestions are welcome!

---

## License

MIT

---

Contributions and feedback are welcome. Let’s build a stronger open-source community together!
 

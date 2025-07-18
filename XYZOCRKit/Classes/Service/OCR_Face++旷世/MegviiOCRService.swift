//
//  MegviiOCRService.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/17.
//

import Foundation
import UIKit
import RxSwift
//https://console.faceplusplus.com.cn/documents/23729623
class MegviiOCRService {
    // MARK: - 配置（强烈建议改成 Info.plist 或 base64 加密后解密）
    private static let apiKeyBase64 = " "
    private static let apiSecretBase64 = " "

    private static var apiKey: String {
        guard let d = Data(base64Encoded: apiKeyBase64),
              let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }
    private static var apiSecret: String {
        guard let d = Data(base64Encoded: apiSecretBase64),
              let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }
    
    /// Megvii 通用文字识别 API
    private let ocrURL = URL(string: "https://api-cn.faceplusplus.com/imagepp/v2/generalocr")!

    /// 通用文字识别（RecognizeText）
    func recognizeText(image: UIImage) -> Observable<[String: Any]> {
        
        
        
        return Observable.create { observer in
            guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                observer.onError(OCRServiceError.invalidImage)
                return Disposables.create()
            }

            let boundary = "Boundary-\(UUID().uuidString)"
            var request = URLRequest(url: self.ocrURL)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()
            // 添加 api_key
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"api_key\"\r\n\r\n")
            body.append("\(Self.apiKey)\r\n")
            // 添加 api_secret
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"api_secret\"\r\n\r\n")
            body.append("\(Self.apiSecret)\r\n")
            // 添加 image_file
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"image_file\"; filename=\"ocr.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
            // 结束符
            body.append("--\(boundary)--\r\n")

            request.httpBody = body

            // 网络请求
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let err = error {
                    observer.onError(OCRServiceError.network(err))
                    return
                }
                guard let data = data else {
                    observer.onError(OCRServiceError.noData)
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let errorMsg = json["error_message"] as? String {
                            observer.onError(OCRServiceError.serverError(errorMsg))
                        } else {
                            // 自动拼接所有 "value" 字段（按每个 textline 换行）
                            if let result = json["result"] as? [String: Any],
                               let regions = result["regions"] as? [[String: Any]] {
                                var lines: [String] = []
                                for region in regions {
                                    if let linesArray = region["lines"] as? [[String: Any]] {
                                        for line in linesArray {
                                            if let words = line["words"] as? [[String: Any]] {
                                                var lineStr = ""
                                                for word in words {
                                                    if let value = word["value"] as? String {
                                                        lineStr += value
                                                    }
                                                }
                                                lines.append(lineStr)
                                            }
                                        }
                                    }
                                }
                                var newJson = json
                                newJson["recognized_text"] = lines.joined(separator: "\n")
                                observer.onNext(newJson)
                                observer.onCompleted()
                            } else {
                                // 如果结构不符合预期，仍返回原json
                                observer.onNext(json)
                                observer.onCompleted()
                            }
                        }
                    } else {
                        observer.onError(OCRServiceError.invalidResponse)
                    }
                } catch {
                    observer.onError(error)
                }
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
    } 
}

extension Data {
    mutating func append(_ string: String) {
        if let d = string.data(using: .utf8) {
            self.append(d)
        }
    }
}

 

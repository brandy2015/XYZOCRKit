//
//  GoogleOCRService.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/17.
//


import Foundation
import UIKit
import RxSwift


//需要打开结算账号
class GoogleOCRService {
    // 你的 Google Cloud Vision API KEY
    private static let apiKey = " "//"YOUR_GOOGLE_VISION_API_KEY"
    private let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)")!

    func recognizeText(image: UIImage?) -> Observable<[String: Any]> {
        guard let image = image else {
            return Observable.error(NSError(domain: "图片为空", code: -100))
        }
        return Observable.create { observer in
            guard let base64String = image.toBase64() else {
                observer.onError(NSError(domain: "图片转Base64失败", code: -1))
                return Disposables.create()
            }

            // 构造 Google Vision 请求体
            let bodyDict: [String: Any] = [
                "requests": [
                    [
                        "image": [ "content": base64String ],
                        "features": [ [ "type": "TEXT_DETECTION", "maxResults": 1 ] ]
                    ]
                ]
            ]
            let bodyData = try! JSONSerialization.data(withJSONObject: bodyDict, options: [])

            var request = URLRequest(url: self.url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse {
                    print("GoogleOCR HTTP status: \(httpResponse.statusCode)")
                }
                if let error = error {
                    observer.onError(error)
                    return
                }
                guard let data = data else {
                    observer.onError(NSError(domain: "无数据", code: -2))
                    return
                }
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        observer.onError(NSError(domain: "返回格式异常", code: -3))
                        return
                    }
                    
                    print("json",json)
                    observer.onNext(json)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }
}

 
extension GoogleOCRService {
    static func extractFullText(from ocrResult: Any) -> String {
        guard let dict = ocrResult as? [String: Any],
              let responses = dict["responses"] as? [[String: Any]],
              let first = responses.first,
              let textAnnotations = first["textAnnotations"] as? [[String: Any]],
              let firstAnno = textAnnotations.first,
              let desc = firstAnno["description"] as? String
        else { return "" }
        return desc
    }
}

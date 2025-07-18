import Foundation
import UIKit
import RxSwift

class AliyunOCRService {
    private static let appKey = ""
    private static let AppCode = ""
    private static let appSecret = ""
    private let url = URL(string: "https://tysbgpu.market.alicloudapi.com/api/predict/ocr_general")!
    
    func recognizeText(image: UIImage?) -> Observable<[String: Any]> {
        guard let image = image else {
               return Observable.error(NSError(domain: "图片为空", code: -100))
           }
        return Observable.create { observer in
            guard let base64String = image.toBase64() else {
                observer.onError(NSError(domain: "图片转Base64失败", code: -1))
                return Disposables.create()
            }
            let bodyDict: [String: Any] = [
                "image": base64String,
                "configure": [
                    "min_size": 16,
                    "output_prob": true,
                    "output_keypoints": false,
                    "skip_detection": false,
                    "dir_assure": false,
                    "language": "sx"
                ]
            ]
            let bodyData = try! JSONSerialization.data(withJSONObject: bodyDict, options: [])
            if let bodyStr = String(data: bodyData, encoding: .utf8) {
                print("Request Body JSON:\n\(bodyStr)")
            }
            
            var request = URLRequest(url: self.url)
            request.httpMethod = "POST"
            request.setValue("APPCODE \(Self.AppCode)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                self.handleNetworkResponse(data: data, response: response, error: error, observer: observer)
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }
    
    private func handleNetworkResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        observer: AnyObserver<[String: Any]>
    ) {
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP status code: \(httpResponse.statusCode)")
            print("HTTP headers: \(httpResponse.allHeaderFields)")
        }
        if let error = error {
            print("Network request error: \(error.localizedDescription)")
            observer.onError(error)
            return
        }
        guard let data = data else {
            print("No data received from server.")
            observer.onError(NSError(domain: "无数据", code: -2))
            return
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("Server response string: \(responseString)")
        } else {
            print("Unable to convert server response data to string.")
        }
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("JSON parsing error: response is not a dictionary")
                observer.onError(NSError(domain: "返回格式异常", code: -3))
                return
            }
            
            // 服务器正常返回，包含 ret 字段
            if let ret = json["ret"] as? [[String: Any]], let success = json["success"] as? Bool, success {
                let result: [String: Any] = [
                    "request_id": json["request_id"] as? String ?? "",
                    "ret": ret,
                    "success": true
                ]
                observer.onNext(result)
                observer.onCompleted()
                return
            } else {
                // 非正常返回，带错误信息
                let msg = (json["msg"] as? String) ?? "服务器返回格式错误"
                print("Server returned error: \(msg)")
                observer.onError(NSError(domain: msg, code: -4))
            }
        } catch {
            if let responseString = String(data: data, encoding: .utf8) {
                print("JSON parsing error: \(error.localizedDescription), response: \(responseString)")
            } else {
                print("JSON parsing error: \(error.localizedDescription), unable to convert response data to string.")
            }
            observer.onError(error)
        }
    }
}

extension UIImage {
    func toBase64() -> String? {
        guard let jpegData = self.jpegData(compressionQuality: 0.85) else { return nil }
        return jpegData.base64EncodedString()
    }
}

extension AliyunOCRService {
    /// 从OCR结果中提取所有word内容为字符串数组。兼容返回直接是数组或嵌套字典的情况。
    static func extractWords(from ocrResult: Any) -> [String] {
        if let array = ocrResult as? [[String: Any]] {
            return array.compactMap { $0["word"] as? String }
        }
        if let dict = ocrResult as? [String: Any] {
            if let ret = dict["ret"] as? [[String: Any]] {
                return ret.compactMap { $0["word"] as? String }
            }
            if let textBlocks = dict["textBlocks"] as? [[String: Any]] {
                return textBlocks.compactMap { $0["word"] as? String }
            }
        }
        return []
    }

    /// 提取所有识别内容拼成完整文本（每行一个）。兼容不同格式。
    static func extractFullText(from ocrResult: Any) -> String {
        print("ocrResult",ocrResult)
        return extractWords(from: ocrResult).joined(separator: "\n")
    }
}

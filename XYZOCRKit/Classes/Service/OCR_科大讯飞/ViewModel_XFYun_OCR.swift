import Foundation
import RxSwift
import RxCocoa
import UIKit
import CommonCrypto
//有具体的位置
// MARK: - 讯飞OCR ViewModel
class ViewModel_XFYun_OCR {
    // 输入
    let imageInput = BehaviorRelay<UIImage?>(value: nil)
    let trigger = PublishRelay<Void>()
    
    // 输出
    let result: Driver<String?>
    let error: Driver<String?>
    let isLoading: Driver<Bool>
    
    private let resultSubject = PublishSubject<String?>()
    private let errorSubject = PublishSubject<String?>()
    private let loading = BehaviorRelay<Bool>(value: false)
    private let disposeBag = DisposeBag()
    
    // 配置，建议 Info.plist 或 Base64 混淆存储
    private static let appIDBase64 = ""
    private  var appID: String {
        guard let d = Data(base64Encoded: Self.appIDBase64),
              let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }
    private static let apiKeyBase64 = ""
    private static let apiSecretBase64 = ""
    private let requestUrl = "https://api.xfyun.cn/v1/service/v1/ocr/general"

    private var apiKey: String {
        guard let d = Data(base64Encoded: Self.apiKeyBase64),
              let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }
    private var apiSecret: String {
        guard let d = Data(base64Encoded: Self.apiSecretBase64),
              let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }
    
    // MARK: - 初始化
    init() {
        self.result = resultSubject.asDriver(onErrorJustReturn: nil)
        self.error = errorSubject.asDriver(onErrorJustReturn: "未知错误")
        self.isLoading = loading.asDriver()
        
        trigger
            .withLatestFrom(imageInput)
            .flatMapLatest { [weak self] image -> Observable<Result<String, OCRServiceError>> in
                guard let self = self else { return .empty() }
                self.loading.accept(true)
                if let image = image {
                    return self.recognizeFromImage(image)
                } else {
                    return .just(.failure(.invalidImage))
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                self?.loading.accept(false)
                switch result {
                case .success(let text):
                    self?.resultSubject.onNext(text)
                    self?.errorSubject.onNext(nil)
                case .failure(let error):
                    self?.resultSubject.onNext(nil)
                    self?.errorSubject.onNext(error.localizedDescription)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - 生成 GMT 日期字符串
    private func gmtDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.string(from: Date())
    }
    
    // MARK: - HMAC-SHA256 base64 签名函数
    private func hmacSHA256Base64(string: String, key: String) -> String {
        let keyData = key.data(using: .utf8)!
        let messageData = string.data(using: .utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyBytes in
            messageData.withUnsafeBytes { messageBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, keyData.count, messageBytes.baseAddress, messageData.count, &digest)
            }
        }
        return Data(digest).base64EncodedString()
    }
    
    // MARK: - 讯飞 企业 WebAPI 通用文字识别（URL 查询参数鉴权模式）
    private func recognizeFromImage(_ image: UIImage) -> Observable<Result<String, OCRServiceError>> {
        guard let imageData = image.jpegData(compressionQuality: 0.9) ?? image.pngData() else {
            return .just(.failure(.invalidImage))
        }
        let base64String = imageData.base64EncodedString()
        
        let host = "api.xf-yun.com"
        let urlPath = "/v1/private/sf8e6aca1" // 根据你实际 API 路径调整
        let date = gmtDateString()
        let signatureOrigin = "host: \(host)\ndate: \(date)\nPOST \(urlPath) HTTP/1.1"
        let signatureSha = hmacSHA256Base64(string: signatureOrigin, key: apiSecret)
        let authorizationOrigin = "api_key=\"\(apiKey)\", algorithm=\"hmac-sha256\", headers=\"host date request-line\", signature=\"\(signatureSha)\""
        let authorizationBase64 = Data(authorizationOrigin.utf8).base64EncodedString()
        
        let dateEncoded = date.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.xf-yun.com\(urlPath)?authorization=\(authorizationBase64)&host=\(host)&date=\(dateEncoded)"
        
        // ---- 讯飞OCR调试 ----
        print("---- 讯飞OCR调试 ----")
        print("apiKey: \(apiKey)")
        print("apiSecret: \(apiSecret)")
        print("date: \(date)")
        print("signatureOrigin: \(signatureOrigin)")
        print("signatureSha: \(signatureSha)")
        print("authorizationOrigin: \(authorizationOrigin)")
//        print("authorizationBase64: \(authorizationBase64)")
//        print("请求URL: \(urlString)")
        
        let jsonBody: [String: Any] = [
            "header": [
                "app_id": "\(appID)",
                "status": 3
            ],
            "parameter": [
                "sf8e6aca1": [
                    "category": "ch_en_public_cloud",
                    "result": [
                        "encoding": "utf8",
                        "compress": "raw",
                        "format": "json"
                    ]
                ]
            ],
            "payload": [
                "sf8e6aca1_data_1": [
                    "encoding": "jpg",
                    "status": 3,
                    "image": base64String
                ]
            ]
        ]
//        print("jsonBody预览: \(jsonBody)")
        guard let bodyData = try? JSONSerialization.data(withJSONObject: jsonBody, options: []) else {
            return .just(.failure(.invalidImage))
        }
        
        return Observable.create { observer in
            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = bodyData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    observer.onNext(.failure(.requestFailed(error.localizedDescription)))
                    observer.onCompleted()
                    return
                }
                guard let data = data else {
                    observer.onNext(.failure(.requestFailed("无返回数据 / No response data")))
                    observer.onCompleted()
                    return
                }
                if let dataStr = String(data: data, encoding: .utf8) {
//                    print("响应原始数据: \(dataStr)")
                }
                do {
                    if let text = Self.parseXFyunOCRResponse(data: data) {
                        print("🐒🐒🐒🐒🐒🐒🐒🐒\(text)")
                        observer.onNext(.success(text))
                    } else {
                        observer.onNext(.failure(.decodeFailed))
                    }
                } catch let err {
                    observer.onNext(.failure(.serverError(err.localizedDescription)))
                }
                observer.onCompleted()
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }
    
    // MARK: - 讯飞 WebAPI OCR 响应解析（企业API适配版）
    static func parseXFyunOCRResponse(data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        guard let header = obj["header"] as? [String: Any], let code = header["code"] as? Int, code == 0 else {
            return nil
        }
        guard let payload = obj["payload"] as? [String: Any],
              let result = payload["result"] as? [String: Any],
              let textJsonString = result["text"] as? String else {
            return nil
        }
        // Base64 解码优先
        var ocrObj: [String: Any]? = nil
        if let decodedData = Data(base64Encoded: textJsonString),
           let textObj = try? JSONSerialization.jsonObject(with: decodedData) as? [String: Any] {
            ocrObj = textObj
        } else if let textData = textJsonString.data(using: .utf8),
                  let textObj = try? JSONSerialization.jsonObject(with: textData) as? [String: Any] {
            ocrObj = textObj
        }
        guard let ocrJson = ocrObj else { return textJsonString }

        // 递归提取所有 pages→lines→words→content
        if let pages = ocrJson["pages"] as? [[String: Any]] {
            var allLines: [String] = []
            for page in pages {
                if let lines = page["lines"] as? [[String: Any]] {
                    for line in lines {
                        if let words = line["words"] as? [[String: Any]] {
                            let lineContent = words.compactMap { $0["content"] as? String }.joined()
                            if !lineContent.isEmpty {
                                allLines.append(lineContent)
                            }
                        }
                        // 若words为空，也补充 line["content"]
                        if let lineStr = line["content"] as? String, !lineStr.isEmpty {
                            allLines.append(lineStr)
                        }
                    }
                }
            }
            return allLines.joined(separator: "\n")
        }
        return textJsonString
    }
}

// MARK: - 字符串 MD5 扩展
extension String {
    var md5: String {
        guard let strData = self.data(using: .utf8) else { return "" }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        strData.withUnsafeBytes {
            _ = CC_MD5($0.baseAddress, CC_LONG(strData.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}


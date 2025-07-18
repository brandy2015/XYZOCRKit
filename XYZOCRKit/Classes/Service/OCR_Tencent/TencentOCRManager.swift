//
//  TencentOCRManager.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/17.
//

//https://cloud.tencent.com/document/product/866/34681

//https://cloud.tencent.com/document/product/866/33515
import UIKit
import CommonCrypto

class TencentOCRManager {
     
    // Base64 加密存储 SecretId 和 SecretKey
    private static let secretIdBase64 = " "
    private static let secretKeyBase64 = " "

    private static var secretId: String {
        guard let d = Data(base64Encoded: secretIdBase64),
              let s = String(data: d, encoding: .utf8) else { return "" }
         
        return s
    }
    private static var secretKey: String {
        guard let d = Data(base64Encoded: secretKeyBase64),
              let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }

    static func recognizeGeneralBasic(imageBase64: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let secretId = TencentOCRManager.secretId
        let secretKey = TencentOCRManager.secretKey 
        let endpoint = "ocr.tencentcloudapi.com"
        let timestamp = Int(Date().timeIntervalSince1970)
        let date = DateFormatter()
        date.dateFormat = "yyyy-MM-dd"
        
        let params: [String: Any] = [
            "ImageBase64": imageBase64
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: params)
        let payload = String(data: jsonData, encoding: .utf8)!
        
        // -- 构造 TC3 标准签名 begin --
        let algorithm = "TC3-HMAC-SHA256"
        let service = "ocr"
        let httpRequestMethod = "POST"
        let canonicalUri = "/"
        let canonicalQueryString = ""
        let canonicalHeaders = "content-type:application/json\nhost:ocr.tencentcloudapi.com\n"
        let signedHeaders = "content-type;host"
        let hashedRequestPayload = sha256Hex(payload.data(using: .utf8)!)
        let canonicalRequest = """
        \(httpRequestMethod)
        \(canonicalUri)
        \(canonicalQueryString)
        \(canonicalHeaders)
        \(signedHeaders)
        \(hashedRequestPayload)
        """

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let dateStr = dateFormatter.string(from: Date())
        let credentialScope = "\(dateStr)/\(service)/tc3_request"
        let hashedCanonicalRequest = sha256Hex(canonicalRequest.data(using: .utf8)!)
        let stringToSign = """
        \(algorithm)
        \(timestamp)
        \(credentialScope)
        \(hashedCanonicalRequest)
        """

        let secretDate = hmacSHA256Raw(key: "TC3" + secretKey, msg: dateStr)
        let secretService = hmacSHA256Raw(key: secretDate, msg: service)
        let secretSigning = hmacSHA256Raw(key: secretService, msg: "tc3_request")
        let signature = hmacSHA256Hex(key: secretSigning, msg: stringToSign)
        let authorization = "\(algorithm) Credential=\(secretId)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        // -- 构造 TC3 标准签名 end --

        var request = URLRequest(url: URL(string: "https://\(endpoint)/")!)
        request.httpMethod = "POST"
        request.addValue(authorization, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("GeneralBasicOCR", forHTTPHeaderField: "X-TC-Action")
        request.addValue("2018-11-19", forHTTPHeaderField: "X-TC-Version")
        request.addValue("ap-beijing", forHTTPHeaderField: "X-TC-Region")
        request.addValue(String(timestamp), forHTTPHeaderField: "X-TC-Timestamp")
        request.httpBody = payload.data(using: .utf8)
         
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("🔴 网络错误:", error.localizedDescription)
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse {
                print("📶 HTTP 状态码:", http.statusCode)
                print("📋 响应 Headers:", http.allHeaderFields)
            }
            guard let data = data else {
                print("🟠 警告: 返回 data 为 nil")
                completion(.failure(NSError(domain: "TencentOCR", code: -1, userInfo: [NSLocalizedDescriptionKey: "返回 data 为 nil"])))
                return
            }
            let text = String(data: data, encoding: .utf8) ?? "<二进制数据>"
            print("📥 返回内容:", text)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let resp = json["Response"] as? [String: Any] {
                    if let err = resp["Error"] as? [String: Any],
                       let code = err["Code"] as? String,
                       let msg = err["Message"] as? String {
                        print("⚠️ OCR 返回错误 Code=\(code), Message=\(msg)")
                        completion(.failure(NSError(domain: "TencentOCR", code: -1, userInfo: [NSLocalizedDescriptionKey: "\(code): \(msg)"])))
                        return
                    }
                    if let items = resp["TextDetections"] as? [[String: Any]] {
                        let words = items.compactMap { $0["DetectedText"] as? String }
                        completion(.success(words))
                        return
                    }
                }
            }
            print("⚠️ 解析失败，格式不正确")
            completion(.failure(NSError(domain: "TencentOCR", code: -1, userInfo: [NSLocalizedDescriptionKey: "Response 解析失败: \(text)"])))
        }.resume()
        
    }
    
 
    
}
func hmacSHA256(data: String, key: String) -> String {
    let keyData = key.data(using: .utf8)!
    let msgData = data.data(using: .utf8)!
    var result = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    keyData.withUnsafeBytes { keyBytes in
        msgData.withUnsafeBytes { msgBytes in
            CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                   keyBytes.baseAddress, keyData.count,
                   msgBytes.baseAddress, msgData.count,
                   &result)
        }
    }
    return Data(result).base64EncodedString()
}

// sha256Hex 工具函数
func sha256Hex(_ data: Data) -> String {
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
    }
    return hash.map { String(format: "%02x", $0) }.joined()
}
func hmacSHA256Raw(key: String, msg: String) -> Data {
    let keyData = key.data(using: .utf8)!
    let msgData = msg.data(using: .utf8)!
    var result = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    keyData.withUnsafeBytes { keyBytes in
        msgData.withUnsafeBytes { msgBytes in
            CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                   keyBytes.baseAddress, keyData.count,
                   msgBytes.baseAddress, msgData.count,
                   &result)
        }
    }
    return Data(result)
}
func hmacSHA256Raw(key: Data, msg: String) -> Data {
    let keyBytes = [UInt8](key)
    let msgBytes = [UInt8](msg.utf8)
    var result = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    keyBytes.withUnsafeBufferPointer { keyPtr in
        msgBytes.withUnsafeBufferPointer { msgPtr in
            CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                   keyPtr.baseAddress, keyBytes.count,
                   msgPtr.baseAddress, msgBytes.count,
                   &result)
        }
    }
    return Data(result)
}
func hmacSHA256Hex(key: Data, msg: String) -> String {
    let sig = hmacSHA256Raw(key: key, msg: msg)
    return sig.map { String(format: "%02x", $0) }.joined()
}

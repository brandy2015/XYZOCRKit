//
//  AWSSignerV4.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/17.
//


import Foundation
import CommonCrypto

class AWSSignerV4 {
    static func signRequest(request: inout URLRequest,
                           bodyData: Data,
                           accessKey: String,
                           secretKey: String,
                           region: String,
                           service: String) {
        // 生成日期
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let amzDate = dateFormatter.string(from: date)
        let dateStamp = String(amzDate.prefix(8))

        // AWS 推荐 Content-Type
        let contentType = "application/x-amz-json-1.1"
        let host = request.url!.host!
        let target = request.value(forHTTPHeaderField: "X-Amz-Target") ?? ""

        // 计算 payload 哈希 (小写 hex)
        let payloadHash = bodyData.sha256Hex().lowercased()

        // Canonical Headers 顺序必须完全一致，值必须完全一致
        let canonicalHeaders =
            "content-type:\(contentType)\n" +
            "host:\(host)\n" +
            "x-amz-content-sha256:\(payloadHash)\n" +
            "x-amz-date:\(amzDate)\n" +
            "x-amz-target:\(target)\n"

        let signedHeaders = "content-type;host;x-amz-content-sha256;x-amz-date;x-amz-target"

        // CanonicalRequest 拼接严格无空行
        let canonicalRequest = [
            request.httpMethod ?? "POST",
            "/", // AWS Textract endpoint 默认 path
            "", // query string
            canonicalHeaders,
            signedHeaders,
            payloadHash
        ].joined(separator: "\n")

        // String To Sign
        let credentialScope = "\(dateStamp)/\(region)/\(service)/aws4_request"
        let canonicalRequestHash = canonicalRequest.data(using: .utf8)!.sha256Hex()
        let stringToSign = [
            "AWS4-HMAC-SHA256",
            amzDate,
            credentialScope,
            canonicalRequestHash
        ].joined(separator: "\n")

        // 生成签名
        let signingKey = getSignatureKey(secretKey: secretKey, dateStamp: dateStamp, regionName: region, serviceName: service)
        let signature = stringToSign.data(using: .utf8)!.hmacSHA256(key: signingKey).hexEncodedString()

        // 填写 header（和签名顺序必须一致）
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(host, forHTTPHeaderField: "Host")
        request.setValue(payloadHash, forHTTPHeaderField: "X-Amz-Content-Sha256")
        request.setValue(amzDate, forHTTPHeaderField: "X-Amz-Date")
        request.setValue(target, forHTTPHeaderField: "X-Amz-Target")
        request.setValue("AWS4-HMAC-SHA256 Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)", forHTTPHeaderField: "Authorization")

//        // DEBUG PATCH: 打印参与签名的全部关键内容
//        print("=== [AWS V4 Debug] ===")
//        print("[accessKey]: \(accessKey)")
//        print("[secretKey]: \(secretKey)")
//        print("[region]: \(region)")
//        print("[service]: \(service)")
//        print("[X-Amz-Target]: \(target)")
//        print("[Content-Type]: \(contentType)")
//        print("[Host]: \(host)")
//        print("[PayloadHash]: \(payloadHash)")
//        print("[CanonicalHeaders]:\n\(canonicalHeaders)")
//        print("[SignedHeaders]: \(signedHeaders)")
//        print("[CanonicalRequest]:\n\(canonicalRequest)")
//        print("[CredentialScope]: \(credentialScope)")
//        print("[StringToSign]:\n\(stringToSign)")
//        print("[Signature]: \(signature)")
//        print("[BodyData]:\n\(String(data: bodyData, encoding: .utf8) ?? "(not UTF-8)")")
//        print("=== [END DEBUG] ===")
    }

    // HMAC 和 SHA256工具
    static func getSignatureKey(secretKey: String, dateStamp: String, regionName: String, serviceName: String) -> Data {
        let kDate = ("AWS4" + secretKey).data(using: .utf8)!.hmacSHA256(key: dateStamp)
        let kRegion = kDate.hmacSHA256(key: regionName)
        let kService = kRegion.hmacSHA256(key: serviceName)
        return kService.hmacSHA256(key: "aws4_request")
    }
}

extension Data {
    func sha256Hex() -> String {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash) }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    func hmacSHA256(key: String) -> Data {
        let keyData = key.data(using: .utf8)!
        var macData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        macData.withUnsafeMutableBytes { macBytes in
            self.withUnsafeBytes { msgBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyData.bytes, keyData.count, msgBytes.baseAddress, self.count, macBytes.baseAddress)
            }
        }
        return macData
    }
    func hmacSHA256(key: Data) -> Data {
        var macData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        macData.withUnsafeMutableBytes { macBytes in
            self.withUnsafeBytes { msgBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), key.bytes, key.count, msgBytes.baseAddress, self.count, macBytes.baseAddress)
            }
        }
        return macData
    }
    var bytes: UnsafeRawPointer { (self as NSData).bytes }
    func hexEncodedString() -> String {
        map { String(format: "%02x", $0) }.joined()
    }
}

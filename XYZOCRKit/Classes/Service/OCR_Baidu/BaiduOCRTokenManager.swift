//
//  BaiduOCRTokenManager.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/17.
//


import Foundation

class BaiduOCRTokenManager {
    static let shared = BaiduOCRTokenManager()
    private init() {}

    // Base64编码后的API Key和Secret Key
    private let apiKeyBase64 = " "
    private let secretKeyBase64 = " "

    private var apiKey: String {
        guard let data = Data(base64Encoded: apiKeyBase64),
              let key = String(data: data, encoding: .utf8) else { return "" }
        return key
    }
    private var secretKey: String {
        guard let data = Data(base64Encoded: secretKeyBase64),
              let key = String(data: data, encoding: .utf8) else { return "" }
        return key
    }
    
    
    private let tokenURL = "https://aip.baidubce.com/oauth/2.0/token"

    private var accessToken: String?
    private var expireDate: Date?

    /// 获取access_token
    func getAccessToken(completion: @escaping (String?) -> Void) {
        // 已获取且未过期，直接返回
        if let token = accessToken, let expire = expireDate, expire > Date() {
            completion(token)
            return
        }
        var components = URLComponents(string: tokenURL)!
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: apiKey),
            URLQueryItem(name: "client_secret", value: secretKey)
        ]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["access_token"] as? String,
                  let expiresIn = json["expires_in"] as? Double else {
                completion(nil)
                return
            }
            self.accessToken = token
            self.expireDate = Date().addingTimeInterval(expiresIn - 60)
            completion(token)
        }.resume()
    }
}

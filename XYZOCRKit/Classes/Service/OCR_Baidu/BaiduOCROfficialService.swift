//
//  BaiduOCROfficialService.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/17.
//

import UIKit

import Foundation

class BaiduOCROfficialService {
    static let shared = BaiduOCROfficialService()
    private init() {}

    // 官方接口，支持通用、含位置、手写等，替换path即可
    private let apiPath = "https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic"
    
    /// 识别图片（支持附加参数）
    func recognize(image: UIImage, options: [String: String]? = nil, completion: @escaping (Result<[String], Error>) -> Void) {
        // 必须先 JPEG 再严格 encode
        guard let imageBase64Raw = image.toBase64String(),
              let imageBase64 = imageBase64Raw.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            completion(.failure(NSError(domain: "BaiduOCR", code: -10, userInfo: [NSLocalizedDescriptionKey: "图片转码失败"])))
            return
        }
        BaiduOCRTokenManager.shared.getAccessToken { token in
            guard let token = token else {
                completion(.failure(NSError(domain: "BaiduOCR", code: -11, userInfo: [NSLocalizedDescriptionKey: "AccessToken获取失败"])))
                return
            }
            let urlStr = "\(self.apiPath)?access_token=\(token)"
            guard let url = URL(string: urlStr) else {
                completion(.failure(NSError(domain: "BaiduOCR", code: -12, userInfo: [NSLocalizedDescriptionKey: "URL构建失败"])))
                return
            }

            var params: [String: String] = ["image": imageBase64]
            if let options = options {
                for (k, v) in options { params[k] = v }
            }
            let paramString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = paramString.data(using: .utf8)

            URLSession.shared.dataTask(with: request) { data, _, error in
                if let err = error {
                    completion(.failure(err))
                    return
                }
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion(.failure(NSError(domain: "BaiduOCR", code: -13, userInfo: [NSLocalizedDescriptionKey: "响应解析失败"])))
                    return
                }
                if let errMsg = json["error_msg"] as? String {
                    completion(.failure(NSError(domain: "BaiduOCR", code: -14, userInfo: [NSLocalizedDescriptionKey: errMsg])))
                    return
                }
                guard let results = json["words_result"] as? [[String: Any]] else {
                    completion(.failure(NSError(domain: "BaiduOCR", code: -15, userInfo: [NSLocalizedDescriptionKey: "未返回words_result"])))
                    return
                }
                let lines = results.compactMap { $0["words"] as? String }
                completion(.success(lines))
            }.resume()
        }
    }
}

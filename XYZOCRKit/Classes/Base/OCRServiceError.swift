//
//  OCRServiceError.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/17.
//


import Foundation
/// 错误定义
enum OCRServiceError: Error {
    case invalidImage               // 图片无效
    case requestFailed(String)      // 网络请求失败
    case decodeFailed               // 解析失败
    case serverError(String)        // 服务端返回错误
    case network(Error)             // 原始网络错误
    case noData                     // 无返回数据
    case invalidResponse            // 返回结构无效
    case unknown                    // 其它未知错误
}
// MARK: - 错误信息本地化
extension OCRServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "图片无效或未选择图片"
        case .requestFailed(let msg):
            return "请求失败：" + msg
        case .decodeFailed:
            return "解析返回数据失败"
        case .serverError(let msg):
            return "服务端返回错误 / Server error: \(msg)"
        case .network(let error):
            return "网络错误: \(error.localizedDescription)"
        case .noData:
            return "无数据返回"
        case .invalidResponse:
            return "返回内容无效"
        case .unknown:
            return "未知错误"
        }
    }
}

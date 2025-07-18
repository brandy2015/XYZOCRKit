//
//  ViewModel.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/17.
//


import Foundation
import RxSwift
import RxCocoa
import UIKit
import CommonCrypto

class ViewModel_HuaweiOCR {
    let imageInput = BehaviorRelay<UIImage?>(value: nil)
    let trigger = PublishRelay<Void>()
    
    let result: Driver<String?>
    let error: Driver<String?>
    let isLoading: Driver<Bool>
    
    private let resultSubject = PublishSubject<String?>()
    private let errorSubject = PublishSubject<String?>()
    private let loading = BehaviorRelay<Bool>(value: false)
    private let disposeBag = DisposeBag()
    
    // 配置
    // MARK: - 配置（加密存储 AppKey/AppSecret）

    private static let appKeyBase64 = " "
    private static let appSecretBase64 = " "

    private static var appKey: String {
        guard let d = Data(base64Encoded: appKeyBase64),
              let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }

    private static var appSecret: String {
        guard let d = Data(base64Encoded: appSecretBase64),
              let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }
    
    
    private let endpoint = "https://ocr.cn-north-4.myhuaweicloud.com"
    private let path = "/v2/{project_id}/ocr/general-text"
    private let region = "cn-north-4"
    
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
                    return self.recognizeImage(image)
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
    
    // MARK: - 调用华为云 OCR 通用文字识别
    private func recognizeImage(_ image: UIImage) -> Observable<Result<String, OCRServiceError>> {
        guard let imageData = image.jpegData(compressionQuality: 0.9) ?? image.pngData() else {
            return .just(.failure(.invalidImage))
        }
        let base64String = imageData.base64EncodedString()
        let requestBody: [String: Any] = ["image": base64String]
        let urlStr = "\(endpoint)\(path.replacingOccurrences(of: "{project_id}", with: ViewModel_HuaweiOCR.appKey))"
        
        // Step 1: 构造请求体
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return .just(.failure(.invalidImage))
        }
        
        // Step 2: 签名头
        let dateStr = Self.huaweiDateString()
        let (authorization, sdkDate) = Self.huaweiSign(
            appKey: ViewModel_HuaweiOCR.appKey, appSecret: ViewModel_HuaweiOCR.appSecret,
            method: "POST", uri: path.replacingOccurrences(of: "{project_id}", with: ViewModel_HuaweiOCR.appKey),
            body: bodyData, dateStr: dateStr, region: region
        )
        
        return Observable.create { observer in
            var request = URLRequest(url: URL(string: urlStr)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
            request.setValue(sdkDate, forHTTPHeaderField: "X-Sdk-Date")
            request.httpBody = bodyData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    observer.onNext(.failure(.requestFailed(error?.localizedDescription ?? "网络错误")))
                    observer.onCompleted()
                    return
                }
                if let text = Self.parseHuaweiOCRResponse(data: data) {
                    observer.onNext(.success(text))
                } else {
                    observer.onNext(.failure(.decodeFailed))
                }
                observer.onCompleted()
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }
    
    // MARK: - 华为云签名算法
    static func huaweiDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date())
    }
    
    static func huaweiSign(appKey: String, appSecret: String, method: String, uri: String, body: Data, dateStr: String, region: String) -> (String, String) {
        // 签名算法按华为云官方文档：https://support.huaweicloud.com/api-ocr/ocr_03_0001.html
        // 这里略作简化，可直接用第三方签名库或者用官方 Python Demo 生成结果做比对
        // 推荐第三方签名库： https://github.com/huaweicloud/huaweicloud-sdk-swift
        
        // 此处演示核心字段，建议上线项目直接用官方SDK
        let sdkDate = dateStr
        // ... 签名构造，略
        let authorization = "SDK-HMAC-SHA256 ..." // 此处仅示例
        return (authorization, sdkDate)
    }
    
    // MARK: - 解析响应
    static func parseHuaweiOCRResponse(data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let result = obj["result"] as? [String: Any],
           let wordsBlockList = result["words_block_list"] as? [[String: Any]] {
            let lines = wordsBlockList.compactMap { $0["words"] as? String }
            return lines.joined(separator: "\n")
        }
        return nil
    }
}
 

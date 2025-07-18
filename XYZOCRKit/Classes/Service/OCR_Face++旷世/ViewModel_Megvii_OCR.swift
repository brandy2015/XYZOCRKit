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

class ViewModel_Megvii_OCR {
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

    private let ocrService = MegviiOCRService()

    init() {
        let activity = ActivityIndicator()
        self.isLoading = activity.asDriver()
        self.result = resultSubject.asDriver(onErrorJustReturn: nil)
        self.error = errorSubject.asDriver(onErrorJustReturn: "未知错误")

        trigger
            .withLatestFrom(imageInput)
//            .compactMap {
//                guard let img = $0?.resizedForMegviiOCR() else {
//                    // 这里也可以直接 errorSubject.onNext("图片像素太小或无效，请重新选择")
//                    return nil
//                }
//                return img
//            }
            .flatMap { [weak self] imgOpt -> Observable<UIImage> in
                guard let img = imgOpt?.resizedForMegviiOCR() else {
                    self?.errorSubject.onNext("图片像素太小或宽高低于16像素，请更换清晰图片")
                    return .empty()
                }
                return .just(img)
            }
            .do(onNext: { [weak self] _ in self?.loading.accept(true) })
            .flatMapLatest { [ocrService] image in
                ocrService.recognizeText(image: image)
                    .trackActivity(activity)
                    .catch { [weak self] err in
                        let errMsg = (err as? OCRServiceError)?.localizedDescription ?? err.localizedDescription
                        self?.errorSubject.onNext(errMsg)
                        return .empty()
                    }
            }
            .map { json -> String? in
                // 向下兼容 NSDictionary/NSArray 类型，防止类型导致 as? 失败
                let dict: [String: Any]
                if let d = json as? [String: Any] {
                    dict = d
                } else if let d = json as? NSDictionary {
                    dict = d as? [String: Any] ?? [:]
                } else {
                    return "未识别到有效文字"
                }
                // 兼容 text_info 返回结构
                if let textInfo = dict["text_info"] as? [[String: Any]] {
                    let lines = textInfo.compactMap { $0["line_content"] as? String }
                    return lines.isEmpty ? "未识别到有效文字" : lines.joined(separator: "\n")
                }
                // 兼容 error_message
                if let errorMsg = dict["error_message"] as? String, !errorMsg.isEmpty {
                    return "识别失败: \(errorMsg)"
                }
                // 兼容其它结构
                if let recognizedText = dict["recognized_text"] as? String, !recognizedText.isEmpty {
                    return recognizedText
                }
                return "未识别到有效文字"
            }
            .bind(to: resultSubject)
            .disposed(by: disposeBag)
    }
}

extension UIImage {
    /// 防御旷视API尺寸要求，超规格自动压缩，不合规则返回nil
    func resizedForMegviiOCR(maxPixel: CGFloat = 2048, minPixel: CGFloat = 16, maxFileSizeKB: Int = 500) -> UIImage? {
        let size = self.size
        guard size.width >= minPixel, size.height >= minPixel else { return nil }
        let scale = min(1, maxPixel / max(size.width, size.height))
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let scaled = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let img = scaled else { return nil }
        var quality: CGFloat = 0.95
        var data = img.jpegData(compressionQuality: quality)
        // 严格控制小于 maxFileSizeKB，默认 500KB
        while let d = data, d.count > maxFileSizeKB * 1024, quality > 0.15 {
            quality -= 0.05
            data = img.jpegData(compressionQuality: quality)
        }
        if let d = data, let final = UIImage(data: d) {
            return final
        }
        return img
    }
}

//
//  ViewModel.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/17.
//

import UIKit

import RxSwift
import RxCocoa

class ViewModel_GoogleOCR {
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
    private let ocrService = GoogleOCRService()

    init() {
        let activity = loading.asDriver()
        self.isLoading = activity

        self.result = resultSubject.asDriver(onErrorJustReturn: nil)
        self.error = errorSubject.asDriver(onErrorJustReturn: nil)

        trigger
            .withLatestFrom(imageInput)
            .filter { $0 != nil }
            .do(onNext: { _ in self.loading.accept(true) })
            .flatMapLatest { [unowned self] image in
                self.ocrService.recognizeText(image: image)
                    .map { GoogleOCRService.extractFullText(from: $0) }
                    .catch { [weak self] error in
                        self?.errorSubject.onNext(error.localizedDescription)
                        return Observable.just(nil)
                    }
            }
            .do(onNext: { _ in self.loading.accept(false) })
            .bind(to: resultSubject)
            .disposed(by: disposeBag)
    }
}

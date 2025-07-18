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
class ViewModel_AliyunOCR {
    
    let imageInput = BehaviorRelay<UIImage?>(value: nil)
    let trigger = PublishRelay<Void>()
    
    let result: Driver<String?>
    let detail: Driver<[String: Any]?>
    let error: Driver<String?>
    let isLoading: Driver<Bool>
    
    private let disposeBag = DisposeBag()
    
    init(service: AliyunOCRService = AliyunOCRService()) {
        // 1. 临时变量
        let resultSubject = PublishSubject<String?>()
        let detailSubject = PublishSubject<[String: Any]?>()
        let errorSubject = PublishSubject<String?>()
        let loading = BehaviorRelay<Bool>(value: false)
        
        // 2. 业务流
        trigger
            .withLatestFrom(imageInput)
            .compactMap { $0 }
            .do(onNext: { _ in loading.accept(true) })
            .flatMapLatest { image in
                service.recognizeText(image: image)
                    .catch { err in
                        errorSubject.onNext(err.localizedDescription)
                        return Observable.empty()
                    }
            }
            .subscribe(onNext: { result in
                loading.accept(false) 
                let content = AliyunOCRService.extractFullText(from: result)
                resultSubject.onNext(content)
                print("content",content)
            }, onError: { err in
                loading.accept(false)
                errorSubject.onNext(err.localizedDescription)
            })
            .disposed(by: disposeBag)
        
        // 3. 绑定到 Driver
        self.result = resultSubject.asDriver(onErrorJustReturn: nil)
        self.detail = detailSubject.asDriver(onErrorJustReturn: nil)
        self.error = errorSubject.asDriver(onErrorJustReturn: nil)
        self.isLoading = loading.asDriver()
    }
}

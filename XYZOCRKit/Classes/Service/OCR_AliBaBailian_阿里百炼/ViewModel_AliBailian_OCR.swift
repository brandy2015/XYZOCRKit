 
import Foundation
import RxSwift
import RxCocoa
import Alamofire



/// ViewModel —— 支持图片识别请求和响应
class ViewModel_AliBailian_OCR {

    // 输入
    let imageInput = BehaviorRelay<UIImage?>(value: nil)
    let urlInput = BehaviorRelay<String?>(value: nil)
    let trigger = PublishRelay<Void>()

    // 输出
    let result: Driver<String?>
    let error: Driver<String?>
    let isLoading: Driver<Bool>
    
    private let resultSubject = PublishSubject<String?>()
    private let errorSubject = PublishSubject<String?>()
    private let loading = BehaviorRelay<Bool>(value: false)
    private let disposeBag = DisposeBag()


    private var dashScopeAPIKey: String {
        let raw = ""
        return String(data: Data(base64Encoded: raw)!, encoding: .utf8)!
    }
    init() {
        // 主体业务绑定
        self.result = resultSubject.asDriver(onErrorJustReturn: nil)
        self.error = errorSubject.asDriver(onErrorJustReturn: "未知错误")
        self.isLoading = loading.asDriver()

        trigger
            .withLatestFrom(Observable.combineLatest(imageInput, urlInput))
            .flatMapLatest { [weak self] (image, urlStr) -> Observable<Result<String, OCRServiceError>> in
                guard let self = self else { return .empty() }
                self.loading.accept(true)
                if let url = urlStr, !url.isEmpty {
                    return self.recognizeFromURL(url)
                } else if let image = image {
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
    
    // MARK: - 图片 URL 识别
    private func recognizeFromURL(_ imageURL: String) -> Observable<Result<String, OCRServiceError>> {
        let url = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(dashScopeAPIKey)",
            "Content-Type": "application/json"
        ]
        let requestBody: [String: Any] = [
            "model": "qwen-vl-ocr-latest",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": imageURL,
                            "min_pixels": 3136,
                            "max_pixels": 6422528
                        ],
                        [
                            "type": "text",
                            "text": """
                                    请提取图片中所有文字
                                    """

                        ]
                    ]
                ]
            ]
        ]
        
        return Observable.create { observer in
            let req = AF.request(url, method: .post, parameters: requestBody, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .responseData { response in
                    
                    print("xxxx",response)
                    switch response.result {
                    case .success(let data):
                        if let text = ViewModel_AliBailian_OCR.parseAliOCRResponse(data: data) {
                            print("xxxx", text)
                            observer.onNext(.success(text))
                        } else {
                            observer.onNext(.failure(.decodeFailed))
                        }
                    case .failure(let error):
                        observer.onNext(.failure(.requestFailed(error.localizedDescription)))
                    }
                    observer.onCompleted()
                }
            return Disposables.create { req.cancel() }
        }
    }
    
    // MARK: - 本地图片识别（需先上传，未实现上传部分）
    private func recognizeFromImage(_ image: UIImage) -> Observable<Result<String, OCRServiceError>> {
        guard let imageData = image.jpegData(compressionQuality: 0.9) ?? image.pngData() else {
            return .just(.failure(.invalidImage))
        }
        let base64String = imageData.base64EncodedString()
        // 默认为jpg，可以根据实际判断Data类型
        let mimeType = imageData.starts(with: [0xFF, 0xD8]) ? "jpeg" : "png"
        let dataURLString = "data:image/\(mimeType);base64,\(base64String)"
        
        // 用Base64 Data URL方式直接塞到 image_url
        return recognizeFromURL(dataURLString)
    }
    
    // MARK: - 解析OCR JSON响应
    static func parseAliOCRResponse(data: Data) -> String? {
        guard
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = obj["choices"] as? [[String: Any]],
            let content = choices.first?["message"] as? [String: Any],
            let text = content["content"] as? String
        else {
            return nil
        }
        
        print("obj",obj)
        return text
    }
}


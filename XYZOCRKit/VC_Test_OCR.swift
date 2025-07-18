//
//  VC_Test_OCR.swift
//  XYZOCRKit
//
//  Created by 张子豪 on 2025/7/18.
//
 

import UIKit
import Combine
import RxSwift
import RxCocoa
import Alamofire

class VC_Test_OCR: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    
    private let disposeBag = DisposeBag()
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🚀 VC_Test_OCR loaded")
        
        setupResultLabelCopy()
        
    
        setupAWSTextractOCR()
        
        // 各平台 OCR 入口，可按需启用
                // SetAliBailian()
                // setupBaiduOCR()
                // setupTencentOCR()
                // setupHuaweiOCRBinding()
                // setupKDXFOCRBinding()
                // setupMegviiOCR()
                // SetAliyunOCR()
                // setupGoogleOCR()
//                setupAWSTextractOCR()
        
    }
 
    
    /// 支持 resultLabel 一键复制
       private func setupResultLabelCopy() {
           resultLabel.isUserInteractionEnabled = true
           let tap = UITapGestureRecognizer(target: self, action: #selector(handleResultLabelTap))
           resultLabel.addGestureRecognizer(tap)
       }
    
    
    // 点按 resultLabel 复制内容到剪贴板并弹窗反馈
    @objc private func handleResultLabelTap() {
        guard let text = resultLabel.text, !text.isEmpty else { return }
        UIPasteboard.general.string = text
        let alert = UIAlertController(title: nil, message: "已复制", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
    
     
    
    
    
    func SetAliBailian(){
        
        let viewModel = ViewModel_AliBailian_OCR()
        
        // 按钮点击 -> 打开相册，选择图片后自动触发OCR
        selectButton.rx.tap
            .do(onNext: { _ in print("👆 Select button tapped") })
            .flatMapLatest { [unowned self] in
                print("📸 Opening image picker")
                return self.showImagePicker()
            }
            .do(onNext: { [weak self] image in
                print("🖼 Image selected: \(image)")
                self?.imageView.image = image
                self?.resultLabel.text = "正在识别..."
                viewModel.imageInput.accept(image)
                viewModel.urlInput.accept(nil) // 只用image
                viewModel.trigger.accept(())
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // 绑定 OCR结果（只显示全部文字内容）
        viewModel.result
            .drive(onNext: { [weak self] result in
                if let result = result, !result.isEmpty {
                    self?.resultLabel.text = result
                } else {
                    self?.resultLabel.text = "未能识别到有效文字"
                }
            })
            .disposed(by: disposeBag)
        
        // 绑定错误
        viewModel.error
            .drive(onNext: { [weak self] err in
                if let err = err, !err.isEmpty {
                    self?.resultLabel.text = "识别失败: \(err)"
                }
            })
            .disposed(by: disposeBag)
        
        // 绑定加载中
        viewModel.isLoading
            .drive(onNext: { [weak self] loading in
                if loading {
                    self?.resultLabel.text = "识别中…"
                }
            })
            .disposed(by: disposeBag)
    }
    
    func SetAliyunOCR() {
        let viewModel = ViewModel_AliyunOCR()
        
        // 按钮点击 -> 打开相册，选择图片后自动触发OCR
        selectButton.rx.tap
            .do(onNext: { _ in print("👆 Select button tapped (AliyunOCR)") })
            .flatMapLatest { [unowned self] in
                print("📸 Opening image picker (AliyunOCR)")
                return self.showImagePicker()
            }
            .do(onNext: { [weak self] image in
                print("🖼 Image selected: \(image) (AliyunOCR)")
                
                self?.imageView.image = image
                self?.resultLabel.text = "正在识别..."
                viewModel.imageInput.accept(image)
                viewModel.trigger.accept(())
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // 绑定 OCR结果（只显示全部文字内容，自动提取 textBlocks 中的 word 字段）
        viewModel.result
            .drive(onNext: { [weak self] result in
                
                print("result",result)
                self?.resultLabel.text = result
            })
            .disposed(by: disposeBag)
        
        // 绑定错误
        viewModel.error
            .drive(onNext: { [weak self] err in
                if let err = err, !err.isEmpty {
                    self?.resultLabel.text = "识别失败: \(err)"
                }
            })
            .disposed(by: disposeBag)
        
        // 绑定加载中
        viewModel.isLoading
            .drive(onNext: { [weak self] loading in
                if loading {
                    self?.resultLabel.text = "识别中…"
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Image Picker
    private func showImagePicker() -> Observable<UIImage> {
        return Observable<UIImage>.create { [weak self] observer in
            guard let self = self else {
                print("⚠️ Self is nil in showImagePicker")
                observer.onCompleted()
                return Disposables.create()
            }

         
         
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false

            // 设置代理
            let delegateProxy = RxImagePickerDelegateProxy(picker: picker)
            objc_setAssociatedObject(picker, "RxImagePickerDelegateProxyKey", delegateProxy, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            // 监听选择结果
            let disposable = delegateProxy.didFinishPicking
                .subscribe(onNext: { image in
                    print("📥 Image received from picker",image)
                    observer.onNext(image)
                    observer.onCompleted()
                }, onError: { error in
                    print("⚠️ Error from image picker: \(error.localizedDescription)")
                    observer.onError(error)
                })

            // 显示 picker
            print("📲 Presenting image picker")
            self.present(picker, animated: true, completion: nil)

            return Disposables.create {
                print("🧹 Disposing image picker observable, dismissing picker")
                disposable.dispose()
                picker.dismiss(animated: true, completion: nil)
            }
        }
    }
     
}

// MARK: - 旷视Megvii OCR功能扩展
extension VC_Test_OCR {
    func setupMegviiOCR() {
        let viewModel_Megvii = ViewModel_Megvii_OCR()
        
        // 1. 按钮点击 → 调起图片选择器
        selectButton.rx.tap
            .flatMapLatest { [weak self] _ -> Observable<UIImage?> in
                guard let self = self else { return .empty() }
                return self.showImagePicker().map { $0 as UIImage? }
            }
            .bind(to: viewModel_Megvii.imageInput)
            .disposed(by: disposeBag)

        // 2. 图片选好后，自动触发识别
        viewModel_Megvii.imageInput
            .compactMap { $0 }
            .subscribe(onNext: { _ in
                viewModel_Megvii.trigger.accept(())
            })
            .disposed(by: disposeBag)

        // 3. 显示图片
        viewModel_Megvii.imageInput
            .compactMap { $0 }
            .bind(to: imageView.rx.image)
            .disposed(by: disposeBag)

        // 4. 识别结果绑定
        viewModel_Megvii.result
            .drive(onNext: { [weak self] result in
                if let result = result, !result.isEmpty {
                    self?.resultLabel.text = result
                } else {
                    self?.resultLabel.text = "未能识别到有效信息"
                }
            })
            .disposed(by: disposeBag)

        // 5. 错误提示
        viewModel_Megvii.error
            .drive(onNext: { [weak self] err in
                if let err = err, !err.isEmpty {
                    self?.resultLabel.text = "旷视OCR识别失败: \(err)"
                   
                }
            })
            .disposed(by: disposeBag)

        // 6. Loading 状态（如需添加 HUD/动画可在这里扩展）
        viewModel_Megvii.isLoading
            .drive(onNext: { [weak self] loading in
                if loading {
                    self?.resultLabel.text = "旷视识别中…"
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - 百度OCR功能扩展
extension VC_Test_OCR {
    /// 配置百度OCR逻辑
    func setupBaiduOCR() {
        selectButton.rx.tap
            .flatMapLatest { [weak self] _ -> Observable<UIImage> in
                guard let self = self else { return .empty() }
                print("👆 Select button tapped")
                return self.showImagePicker()
            }
            .observe(on: MainScheduler.instance)
            .flatMapLatest { [weak self] image -> Observable<(UIImage, [String])> in
                guard let self = self else { return .empty() }
                self.imageView.image = image
                self.resultLabel.text = "识别中…"
                return Observable.create { observer in
                    BaiduOCROfficialService.shared.recognize(image: image) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let words):
                                observer.onNext((image, words))
                                observer.onCompleted()
                            case .failure(let error):
                                observer.onError(error)
                            }
                        }
                    }
                    return Disposables.create()
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_, words) in
                guard let self = self else { return }
                if words.isEmpty {
                    self.resultLabel.text = "未识别到有效文字"
                } else {
                    self.resultLabel.text = words.joined(separator: "\n")
                }
            }, onError: { [weak self] error in
                self?.resultLabel.text = "识别失败: \(error.localizedDescription)"
            })
            .disposed(by: disposeBag)
    }
    
   
}


// MARK: - 腾讯OCR功能扩展
extension VC_Test_OCR {
    func setupTencentOCR() {
        selectButton.rx.tap
            .flatMapLatest { [weak self] _ -> Observable<UIImage> in
                guard let self = self else { return .empty() }
                print("👆 Select button tapped (TencentOCR)")
                return self.showImagePicker()
            }
            .observe(on: MainScheduler.instance)
            .flatMapLatest { [weak self] image -> Observable<[String]> in
                guard let self = self else { return .empty() }
                self.imageView.image = image
                self.resultLabel.text = "腾讯识别中…"
                return Observable.create { observer in
                    TencentOCRManager.recognizeGeneralBasic(imageBase64: image.jpegData(compressionQuality: 0.8)?.base64EncodedString() ?? "") { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let words):
                                observer.onNext(words)
                                observer.onCompleted()
                            case .failure(let error):
                                observer.onError(error)
                            }
                        }
                    }
                    return Disposables.create()
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] words in
                guard let self = self else { return }
                if words.isEmpty {
                    self.resultLabel.text = "未识别到有效文字"
                } else {
                    self.resultLabel.text = words.joined(separator: "\n")
                }
            }, onError: { [weak self] error in
                self?.resultLabel.text = "腾讯OCR识别失败: \(error.localizedDescription)"
            })
            .disposed(by: disposeBag)
    }
}


// MARK: - 华为OCR功能扩展
extension VC_Test_OCR {
    /// 配置华为OCR逻辑
 
    func setupHuaweiOCRBinding() {
        // 1. 按钮点击 → 调起图片选择器
        
        let viewModel = ViewModel_HuaweiOCR()
        selectButton.rx.tap
            .flatMapLatest { [weak self] _ -> Observable<UIImage?> in
                guard let self = self else { return .empty() }
                return self.showImagePicker().map { $0 as UIImage? }
            }
            .bind(to: viewModel.imageInput)
            .disposed(by: disposeBag)

        // 2. 图片选好后，自动触发识别
        viewModel.imageInput
            .compactMap { $0 }
            .subscribe(onNext: { [weak viewModel] _ in
                viewModel?.trigger.accept(())
            })
            .disposed(by: disposeBag)

        // 3. 显示图片
        viewModel.imageInput
            .compactMap { $0 }
            .bind(to: imageView.rx.image)
            .disposed(by: disposeBag)

        // 4. 识别结果绑定
        viewModel.result
            .drive(resultLabel.rx.text)
            .disposed(by: disposeBag)

        // 5. 错误提示
        viewModel.error
            .drive(onNext: { [weak self] err in
                if let err = err, !err.isEmpty {
                    self?.resultLabel.text = "华为OCR识别失败: \(err)"
                }
            })
            .disposed(by: disposeBag)

        // 6. Loading 状态
//        viewModel.isLoading
//            .drive(activityIndicator.rx.isAnimating)
//            .disposed(by: disposeBag)
        viewModel.isLoading
            .drive(onNext: { [weak self] loading in
                self?.resultLabel.text = loading ? "华为识别中…" : self?.resultLabel.text
            })
            .disposed(by: disposeBag)
    }
    
}



// MARK: - 科大讯飞OCR功能扩展
extension VC_Test_OCR {
    //科大讯飞
    
    func setupKDXFOCRBinding() {
        let viewModel = ViewModel_XFYun_OCR()
        
        // 1. 按钮点击 → 调起图片选择器
        selectButton.rx.tap
            .flatMapLatest { [weak self] _ -> Observable<UIImage?> in
                guard let self = self else { return .empty() }
                return self.showImagePicker().map { $0 as UIImage? }
            }
            .bind(to: viewModel.imageInput)
            .disposed(by: disposeBag)

        // 2. 图片选好后，自动触发识别
        viewModel.imageInput
            .compactMap { $0 }
            .subscribe(onNext: { _ in
                viewModel.trigger.accept(())
            })
            .disposed(by: disposeBag)

        // 3. 显示图片
        viewModel.imageInput
            .compactMap { $0 }
            .bind(to: imageView.rx.image)
            .disposed(by: disposeBag)

        // 4. 识别结果绑定
        viewModel.result
            .drive(onNext: { [weak self] result in
                if let result = result, !result.isEmpty {
                    self?.resultLabel.text = result
                } else {
                    self?.resultLabel.text = "未能识别到有效文字"
                }
            })
            .disposed(by: disposeBag)

        // 5. 错误提示
        viewModel.error
            .drive(onNext: { [weak self] err in
                if let err = err, !err.isEmpty {
                    self?.resultLabel.text = "讯飞OCR识别失败: \(err)"
                }
            })
            .disposed(by: disposeBag)

        // 6. Loading 状态
        viewModel.isLoading
            .drive(onNext: { [weak self] loading in
                if loading {
                    self?.resultLabel.text = "讯飞识别中…"
                }
            })
            .disposed(by: disposeBag)
    }
}



extension VC_Test_OCR {
    func setupGoogleOCR() {
        let viewModel = ViewModel_GoogleOCR()
        
        // 按钮点击 -> 打开相册，选图后自动触发Google OCR
        selectButton.rx.tap
            .do(onNext: { _ in print("👆 Select button tapped (Google OCR)") })
            .flatMapLatest { [unowned self] in
                print("📸 Opening image picker (Google OCR)")
                return self.showImagePicker()
            }
            .do(onNext: { [weak self] image in
                print("🖼 Image selected: \(image) (Google OCR)")
                self?.imageView.image = image
                self?.resultLabel.text = "识别中…"
                viewModel.imageInput.accept(image)
                viewModel.trigger.accept(())
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // 识别结果
        viewModel.result
            .drive(onNext: { [weak self] result in
                print("GoogleOCR Result:", result ?? "nil")
                if let result = result, !result.isEmpty {
                    self?.resultLabel.text = result
                } else {
                    self?.resultLabel.text = "未能识别到有效文字"
                }
            })
            .disposed(by: disposeBag)
        
        // 错误
        viewModel.error
            .drive(onNext: { [weak self] err in
                if let err = err, !err.isEmpty {
                    self?.resultLabel.text = "Google OCR 识别失败: \(err)"
                }
            })
            .disposed(by: disposeBag)
        
        // 加载中
        viewModel.isLoading
            .drive(onNext: { [weak self] loading in
                if loading {
                    self?.resultLabel.text = "Google 识别中…"
                }
            })
            .disposed(by: disposeBag)
    }
}

extension VC_Test_OCR {
    func setupAWSTextractOCR() {
        let viewModel = ViewModel_AWSTextractOCR()

        // 按钮点击 -> 打开相册，选图后自动触发AWS OCR
        selectButton.rx.tap
            .do(onNext: { _ in print("👆 Select button tapped (AWS Textract OCR)") })
            .flatMapLatest { [unowned self] in
                print("📸 Opening image picker (AWS Textract OCR)")
                return self.showImagePicker()
            }
            .do(onNext: { [weak self] image in
                print("🖼 Image selected: \(image) (AWS Textract OCR)")
                self?.imageView.image = image
                self?.resultLabel.text = "识别中…"
                viewModel.imageInput.accept(image)
                viewModel.trigger.accept(())
            })
            .subscribe()
            .disposed(by: disposeBag)

        // 识别结果绑定
        viewModel.result
            .drive(onNext: { [weak self] result in
                print("AWSTextractOCR Result:", result ?? "nil")
                if let result = result, !result.isEmpty {
                    self?.resultLabel.text = result
                } else {
                    self?.resultLabel.text = "未能识别到有效文字"
                }
            })
            .disposed(by: disposeBag)

        // 错误绑定
        viewModel.error
            .drive(onNext: { [weak self] err in
                if let err = err, !err.isEmpty {
                    self?.resultLabel.text = "AWS OCR 识别失败: \(err)"
                }
            })
            .disposed(by: disposeBag)

        // 加载中状态
        viewModel.isLoading
            .drive(onNext: { [weak self] loading in
                if loading {
                    self?.resultLabel.text = "AWS 识别中…"
                }
            })
            .disposed(by: disposeBag)
    }
}

//
//  RxImagePickerDelegateProxy.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/17.
//



import UIKit
import RxSwift
import RxCocoa

class RxImagePickerDelegateProxy: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let didFinishPicking = PublishSubject<UIImage>()
    private weak var picker: UIImagePickerController?

    init(picker: UIImagePickerController) {
        self.picker = picker
        super.init()
        self.picker?.delegate = self
        print("🔧 RxImagePickerDelegateProxy initialized and delegate set")
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("🚫 Image picker cancelled by user")
        picker.dismiss(animated: true, completion: nil)
        didFinishPicking.onError(NSError(domain: "UserCanceled", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户取消了选择"]))
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("📸 Image picker did finish picking media")
        picker.dismiss(animated: true, completion: nil)
        if let image = info[.originalImage] as? UIImage {
            print("🖼 Image successfully retrieved from picker info")
            didFinishPicking.onNext(image)
            didFinishPicking.onCompleted()
        } else {
            print("⚠️ Failed to retrieve image from picker info")
            didFinishPicking.onError(NSError(domain: "ImagePicker", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法获取图片"]))
        }
    }
}

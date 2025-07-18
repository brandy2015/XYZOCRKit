//
//  AWSTextractService.swift
//  XYZOCRAli
//
//  Created by 张子豪 on 2025/7/17.
//


import Foundation
import UIKit
import RxSwift
import CommonCrypto
import AWSCore
import AWSTextract

class AWSTextractService {
 
    static func SetUpAWSTextractService(){
        // Initialize AWS SDK with static credentials (AK/SK) to prevent crashes
        let credentialsProvider = AWSStaticCredentialsProvider(
            accessKey: "",
            secretKey: ""
        )
        let region: AWSRegionType = .APSoutheast1
        let configuration = AWSServiceConfiguration(region: region, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
    
    /// RxSwift识别方法（支持UIImage）
    /// 此方法仅依赖 AWS SDK，直接通过 AWSTextractDetectDocumentTextRequest 传递本地图片 Data，不再拼 JSON、不再用 Base64、不再用 AWSSignerV4，不再自己做 HTTP。
    func recognizeText(image: UIImage?) -> Observable<[String: Any]> {
        return Observable.create { observer in
            guard let image = image, let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("[AWSTextractService] 图片为空或无法获取图片数据")
                observer.onError(NSError(domain: "图片为空", code: -100))
                return Disposables.create()
            }
            print("[AWSTextractService] 获取图片数据成功，大小: \(imageData.count) bytes")
            
            let textract = AWSTextract.default()
            let request = AWSTextractDetectDocumentTextRequest()
            let document = AWSTextractDocument()
            document?.bytes = imageData
            request?.document = document
            
//            print("[AWSTextractService] 创建请求对象成功，准备调用 detectDocumentText")
            textract.detectDocumentText(request!) { response, error in
                
                if let error = error as NSError? {
                       print("[AWSTextractService] detectDocumentText error domain:", error.domain)
                       print("[AWSTextractService] detectDocumentText error code:", error.code)
                       print("[AWSTextractService] detectDocumentText error userInfo:", error.userInfo)
                   }
                
                
                if let error = error {
                    print("[AWSTextractService] detectDocumentText 返回错误: \(error.localizedDescription)")
                    observer.onError(error)
                    return
                }
                guard let response = response else {
                    print("[AWSTextractService] detectDocumentText 返回无结果")
                    observer.onError(NSError(domain: "无返回结果", code: -101))
                    return
                }
//                print("[AWSTextractService] detectDocumentText 返回成功，response: \( response.description())")
               
                // 将 AWSTextractDetectDocumentTextResponse 转换成字典，兼容 extractFullText 方法
                var resultDict = [String: Any]()
                if let blocks = response.blocks  {
                    print("[AWSTextractService] 解析 Blocks，数量: \(blocks.count)")
                    let blocksArray: [[String: Any]] = blocks.map { block in
                        var blockDict = [String: Any]()
                        // BlockType 转成字符串，确保 extractFullText 能正常识别
                        if let enumObj = block.blockType as? CustomStringConvertible {
                            blockDict["BlockType"] = enumObj.description
                        } else {
                            blockDict["BlockType"] = "\(block.blockType)"
                        }
                        blockDict["Text"] = block.text
                        blockDict["Id"] = block.identifier
                        blockDict["Confidence"] = block.confidence
                        // 可以根据需要添加更多字段
                        return blockDict
                    }
                    resultDict["Blocks"] = blocksArray
                }
                print("[AWSTextractService] 最终输出 resultDict: \(resultDict)")
                
                
                observer.onNext(resultDict)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}
  


extension AWSTextractService {
    /// 提取所有Block的Text字段，拼接为完整字符串，只保留第一次出现，自动去重
    static func extractAllText(from ocrResult: Any) -> String {
        guard let dict = ocrResult as? [String: Any],
              let blocks = dict["Blocks"] as? [[String: Any]] else { return "" }
        var seen = Set<String>()
        return blocks
            .compactMap { $0["Text"] as? String }
            .filter { seen.insert($0).inserted }
            .joined(separator: " ")
    }
} 

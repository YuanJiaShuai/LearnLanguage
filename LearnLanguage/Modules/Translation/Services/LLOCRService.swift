//
//  LLOCRService.swift
//  LearnLanguage
//
//  截图 OCR 识别服务（基于 Vision 框架，移植自 TranslateP/OCRService）
//

import Foundation
import Vision
import AppKit

final class LLOCRService {

    /// 识别图片中的文字
    /// - Parameters:
    ///   - image: 待识别的图片
    ///   - completion: 主线程回调，识别结果或 nil
    @available(macOS 13.0, *)
    static func recognizeText(from image: NSImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                if let error = error {
                    LLLogger.error("OCR 识别错误: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion(nil)
                    return
                }

                let strings = observations.compactMap { $0.topCandidates(1).first?.string }
                let result = strings.joined(separator: "\n")
                completion(result.isEmpty ? nil : result)
            }
        }

        // 高精度识别
        request.recognitionLevel = .accurate
        // 支持英文、简繁中文
        request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant"]
        request.automaticallyDetectsLanguage = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    LLLogger.error("OCR 处理错误: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }
}

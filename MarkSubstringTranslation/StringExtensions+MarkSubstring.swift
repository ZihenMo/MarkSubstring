//
//  StringExtensions+MarkSubstring.swift
//  MarkSubstringTranslation
//
//  Created by 墨子痕 on 2022/8/23.
// 将多语言转为html，高亮部分使用a标签标识

import Foundation
import YYText
import SwiftSoup

extension String {
    
    /// 获取富文本与高亮区域，由外部进行设置样式
    ///     约定以<a>highlightText</a>为标识
    /// - Parameter highlightRanges: 读写参数，高亮区域
    /// - Returns: 富文本
    func htmlToAttributedString(`get` highlightRanges: inout [NSRange]) -> NSMutableAttributedString? {
        /// 1. 整体转换成attributedString
        func convertToAttributedString() -> NSMutableAttributedString? {
            guard let data = data(using: .unicode) else { return nil }
            let attributedString = try? NSMutableAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            )
            return attributedString
        }
        
        /// 2. 获取高亮区
        /// 注意，约定标签a内容为高亮区，多个高亮区使用id标记中文序号
        func parseHighLightRanges(in targetString: String) -> [NSRange] {
            do {
                let doc = try SwiftSoup.parse(self)
                let hightTexts = try doc.select("a")
                    .sorted { $0.id().int ?? 0 < $1.id().int ?? 0 }
                    .map { try $0.text() }
                return hightTexts.compactMap { targetString.nsString.range(of: $0) }
            }
            catch {
                debugPrint("解析HTML出错:\(error)")
            }
            return []
        }
        
        guard let attributedString = convertToAttributedString() else { return nil }
        highlightRanges = parseHighLightRanges(in: attributedString.string)
        return attributedString
    }
}

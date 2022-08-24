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
    func htmlToAttributedString() -> (NSMutableAttributedString, [NSRange])? {
        /// 1. 整体转换成attributedString
        func convertToAttributedString() -> NSMutableAttributedString? {
            guard let data = replacingOccurrences(of: "\n", with: "<br/>").data(using: .utf8) else { return nil }
            let attributedString = try? NSMutableAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
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
        let highlightRanges = parseHighLightRanges(in: attributedString.string)
        return (attributedString, highlightRanges)
    }
    
    /// 单个高亮区便捷方法
    func singleMarkHTMLToAttributed() -> (NSMutableAttributedString, NSRange)? {
        guard let (attr, ranges) = htmlToAttributedString(),
              let range = ranges.first
        else { return nil }
        return (attr, range)
    }
}

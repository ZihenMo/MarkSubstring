//
//  Localize.swift
//  MarkSubstringTranslation
//
//  Created by 墨子痕 on 2022/8/23.
//

import Foundation

class Localize {
    static func currentLanguage() -> Language? {
        if let obj = UserDefaults.standard.object(forKey: "appLanguage") as? Data {
            let lang = Language.init(from: obj)
            return lang
        }
        return nil
    }
    
    static func setLangauge(_ lang: Language) {
        UserDefaults.standard.set(object: lang, forKey: "appLanguage")
        UserDefaults.standard.synchronize()
    }
}

enum Language: String, Codable, CaseIterable {
    case en
    case zh_Hans
    case zh_Hant
    
    var name: String {
        switch self {
        case .en:
            return "English"
        case .zh_Hans:
            return "中文简体"
        case .zh_Hant:
            return "中文繁体"
        }
    }
    
    var bundleName: String {
        return rawValue.components(separatedBy: "_").joined(separator: "-")
    }
}

extension String {
    func localize() -> String {
        if let path = Bundle.main.path(forResource: Localize.currentLanguage()?.bundleName ?? "", ofType: "lproj"),
            let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: self, value: nil, table: nil)
        }
        else if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
            let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: self, value: nil, table: nil)
        }
        return self
    }
}

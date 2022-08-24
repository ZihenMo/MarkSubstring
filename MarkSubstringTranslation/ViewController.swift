//
//  ViewController.swift
//  MarkSubstringTranslation
//
//  Created by 墨子痕 on 2022/8/23.
//

import UIKit
import Stevia
import YYText
import SwifterSwift


class ViewController: UIViewController {
    
    lazy var singleLabel = YYLabel()
    lazy var multableLabel = YYLabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        updateText()
    }
    
    func makeUI() {
        view.subviews([singleLabel, multableLabel])
        view.layout(
            100,
            singleLabel.centerHorizontally(),
            30,
            multableLabel.centerHorizontally()
        )
        
        let languageSwitcher = UIBarButtonItem(title: "切换语言", style: .plain, target: self, action: #selector(switchLanguage(_:)))
        navigationItem.rightBarButtonItem = languageSwitcher
    }
    
    func updateText() {
        func updateText1() {
            guard let (attributedString, range) = "text".localize().singleMarkHTMLToAttributed() else { return }
            attributedString.yy_color = .darkGray
            attributedString.yy_font = .systemFont(ofSize: 18)
            attributedString.yy_setTextHighlight(range, color: .red, backgroundColor: nil) { [weak self] _, _, _, _ in
                self?.showAlert(title: "用户指南", message: "详细内容")
            }
            attributedString.yy_setFont(.systemFont(ofSize: 18, weight: .bold), range: range)
            singleLabel.attributedText = attributedString
        }
        func updateText2() {
            guard let (attributedString, ranges) = "text2".localize().htmlToAttributedString() else { return }
            let tapAcltion1: YYTextAction = { [weak self] _, _, _, _ in
                self?.showAlert(title: "隐私协议", message: "详细内容")
            }
            let tapAcltion2: YYTextAction = { [weak self] _, _, _, _ in
                self?.showAlert(title: "免责声明协议", message: "详细内容")
            }
            let actions = [tapAcltion1, tapAcltion2]
            ranges.enumerated().forEach { (idx, range) in
                attributedString.yy_setTextHighlight(range, color: .red, backgroundColor: nil, tapAction: actions[idx])
            }
            multableLabel.attributedText = attributedString
        }
        updateText1()
        updateText2()
    }
    
    @objc func switchLanguage(_ sender: Any) {
        showLanguageActionSheet()
    }
    
    
    func showLanguageActionSheet() {
        let actionSheet = UIAlertController(title: "请选择语言", message: nil, preferredStyle: .actionSheet)
        Language.allCases.forEach { [weak self, weak actionSheet] language in
            actionSheet?.addAction(UIAlertAction(title: language.name, style: .default) { _ in
                Localize.setLangauge(language)
                self?.updateText()
            })
        }
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        actionSheet.show()
    }
}





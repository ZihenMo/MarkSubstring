# 标记高亮子串翻译的解决方案

**【问题背景】**

在新增西班牙语过程中，我发现了之前高亮子串处理方案的缺陷。如长串`"...可在【挖矿设置】进行设置"`中的子串`"挖矿设置"`可点击, 以前主要存在以下两种形式:

* 长串与子串都单独翻译，使用翻译的子串匹长串的`range`以进行高亮设置；
* 长串中使用`%@`占符位，子串单独翻译。

两种方案都有明显的缺陷：

* 多语言子串单独翻译与长句翻译存在差异（如语法顺序、大小写等问题）;
* 子串翻译时，翻译人员并不知晓其长串语境;
* 按长句成分翻译的子串可能被开发人员当作独立子串复用导致表达不准确；
* 每新增一门语言又得重新检查两个翻译串的匹配问题，简直爆炸。

对于这些问题，我原先的治标方案是：

* 使用`context`标记子串录属长串辅助翻译（`/* substring of [原串] */`);
* 具有特征`context`标记子串开发约定不进行复用;
* 匹配子串时忽略大小写
* 将所有父子串记录在表，因为西语都得检查一遍，下次其他语言...`囧`

**【思路方案】**

安卓使用类似`xml`标签来区分子串，而且还带有较多的样式设置，老实说刚看的时候我觉得有点难以区分哪个是需要翻译的内容，哪个是标记。似乎翻译人员比我想像中的更厉害。
于是经过一番讨论与调研后。决定采用`html`标记子串（照抄），使用时返回高亮`range`。（`range`需查翻译后去除标记的正确区域，而不是带标签的区域）

简单测试一番，发现`html`语法不严谨的好处：**长串可以不用任何标记，只需要标记子串**，同时`html`转`attributedString`有原生`Api`支持，`style`可以自动转换。

于是我们得到：

* 约定以`<a>`标签标记子串，翻译后将其转为`attributedString`, 同时返回标记的`range`
* 若有多个子串，则以属性`id`区分`<a id='1'>`。写代码时按中文顺序逻辑，返回的`range`数组会以属性序号进行排序
* 有了`attributedString`与`range`之后你是自由的

```
"text" = "查看<a>用户指南</a>";
"text" = "我已阅读并同意<a id='1'>隐私协议</a>与<a id='2'>免责声明</a>";
```

**【核心源码】**
依赖库
```
pod 'SwiftSoup'
```

```swift
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
```

**【食用示例】**

```swift
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
}```

**【后记】**

事实上，通过`html`几乎可以完整地设置富文本样式，这样通过参数传入`tapAction`就可以不用后续的代码样式设置。

```html
<p style='font-size:18px; font-weight:100; line-height:24px;'>请点击<a id='10' style='color:red; font-weight:500;'>用户协议</a>查看详细内容</p>
```

但是这里有一些缺陷：

* 对`html`的`style`语法有一定要求，不熟悉容易出错，校对麻烦
* `style`样式转换基本都是正确的，如`font-size:18px`对应`18`号字；但是`font-weight:500`却没有加粗。通常字重`400`标准，`500`加粗，而`501`却又是加粗的，可见有一定的偏差。
* 过多的标签内容对翻译不友好，容易出错

考虑到上述因素没有推荐使用，实际上`html`转换是支持的。

另一点就是序号为什么用`id`属性而不是`a1 a2`这种自定义标签呢？

* `id`是`html`正经血统，不会出错
* 经测试，`a1`这种特殊标签虽然解析不会出错，但需要添加属性（任意）才会被视为标签解析。另外，获取标签后续处理也较为不便。










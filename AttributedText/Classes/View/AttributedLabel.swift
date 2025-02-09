//
//  AttributedLabel.swift
//  AttributedText
//
//  Created by wave on 2019/6/25.
//

import UIKit

public class AttributedLabel: UILabel {

    /// model map
    public var modelMapper: ((String)->(TextModel?))?

    /// special text style
    public var linkAttributes: [NSAttributedString.Key : Any] = [:]
    
    /// click link
    public var clickLink: ((TextModel?)->())?
    
    /// insert attributed key
    private let kInputTextViewSpecialTextKeyAttributeName = "kInputTextViewSpecialTextKeyAttributeName"

    private lazy var textStorage = NSTextStorage()
    private lazy var layoutManager = NSLayoutManager()
    private lazy var textContainer = NSTextContainer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        configureLabel()
    }
    
    public override func draw(_ rect: CGRect) {
        textContainer.size = size
        let range = NSMakeRange(0, textStorage.length)
        layoutManager.drawGlyphs(forGlyphRange: range, at: .zero)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = size
    }
}

public extension AttributedLabel {
    
    func set(attributedString: NSAttributedString) {
        
        let resultAttr = NSMutableAttributedString(attributedString: attributedString)

        let matches = resultAttr.string.matchingStrings(regex: "#\\u200b.*?\\u200b")
        
        for content in matches {
            
            let range = (resultAttr.string as NSString).range(of: content)
            if let model = modelMapper?(content) {
                let attr = createAtt(model: model)
                resultAttr.replaceCharacters(in: range, with: attr)
            }
        }
        attributedText = resultAttr
        
        textStorage.setAttributedString(resultAttr)
        
        setNeedsDisplay()
    }
    
    /// 去掉标签格式后的文本结构
    func formatText(text: String) -> String {
        
        let resultAttr = NSMutableAttributedString(string: text)
        let matches = resultAttr.string.matchingStrings(regex: "#\\u200b.*?\\u200b")
        for content in matches {
            let range = (resultAttr.string as NSString).range(of: content)
            if let model = modelMapper?(content) {
                let attr = createAtt(model: model)
                resultAttr.replaceCharacters(in: range, with: attr)
            }
        }
        return resultAttr.string
    }
}

private extension AttributedLabel {
    
    func createAtt(model: TextModel) -> NSMutableAttributedString {
        
        let mutableAttrString = NSMutableAttributedString(string: "")
        
        /// image
        if let image = model.image {
            let attach = NSTextAttachment()
            attach.image = image
            attach.bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            let attachString = NSAttributedString(attachment: attach)
            mutableAttrString.insert(attachString, at: mutableAttrString.length)
        }
        
        /// text = symbol + text
        let text = "\(model.symbolStr ?? "")\(model.text)"
        let textMutableAttrString = NSMutableAttributedString(string: text)
        textMutableAttrString.addAttributes(linkAttributes, range: NSRange(location: 0, length: textMutableAttrString.length))
        mutableAttrString.insert(textMutableAttrString, at: mutableAttrString.length)
        
        /// space
        let spaceAttributedString = NSAttributedString(string: " ")
        //        mutableAttrString.insert(spaceAttributedString, at: 0)
        mutableAttrString.insert(spaceAttributedString, at: mutableAttrString.length)
        
        /// add special key
        mutableAttrString.addAttribute(NSAttributedString.Key(rawValue: kInputTextViewSpecialTextKeyAttributeName), value: model, range: NSRange(location: 0, length: mutableAttrString.length))
        
        return mutableAttrString
    }
}

private extension AttributedLabel {
    
    @objc func tapGestureAction(tapGesture: UITapGestureRecognizer) {
        
        let location = tapGesture.location(in: self)

        let index = layoutManager.glyphIndex(for: location, in: textContainer)
        guard let attributedText = self.attributedText else { return }
        
        var model: TextModel?
        
        attributedText.enumerateAttribute(NSAttributedString.Key(rawValue: kInputTextViewSpecialTextKeyAttributeName), in: NSMakeRange(0, attributedText.length), options: NSAttributedString.EnumerationOptions.reverse) { (attr, range, stop) in

            if let textModel = attr as? TextModel {
                
                let location = range.location
                let length = range.length
                if index > location && index < location + length {
                    
                    /// 点击效果
                    if let color = linkAttributes[.foregroundColor] as? UIColor {
                        var tempLinkAttributes = linkAttributes
                        tempLinkAttributes[.foregroundColor] = color.withAlphaComponent(0.5)
                        textStorage.addAttributes(tempLinkAttributes, range: range)
                        setNeedsDisplay()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                            self.textStorage.addAttributes(self.linkAttributes, range: range)
                            self.setNeedsDisplay()
                        })
                    }
                    
                    model = textModel
                    stop.pointee = true
                }
            }
        }
        
        clickLink?(model)
    }
}

private extension AttributedLabel {
    
    func configureLabel() {
        
        font = UIFont.systemFont(ofSize: 15)
        textColor = .black

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        linkAttributes = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor(red: 69, green: 144, blue: 229) ?? .black,
            .paragraphStyle: paragraphStyle,
        ]
        
        isUserInteractionEnabled = true
        numberOfLines = 0
        lineBreakMode = .byCharWrapping
        
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        
        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureAction(tapGesture:)))
        addGestureRecognizer(tapGesture)
    }
}

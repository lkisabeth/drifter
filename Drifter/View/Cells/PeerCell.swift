//
//  PeerCell.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/16/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import UIKit

class PeerCell: UICollectionViewCell {
    
    fileprivate let padding: CGFloat = 12.0
    
    lazy private var titleLabel: PaddingLabel = {
        let view = PaddingLabel()
        view.backgroundColor = UIColor.primaryColor
        view.textAlignment = .left
        view.layer.cornerRadius = view.bounds.height / 2
        view.font = .systemFont(ofSize: 17)
        view.textColor = .white
        self.contentView.addSubview(view)
        return view
    }()
    
    lazy private var detailLabel: PaddingLabel = {
        let view = PaddingLabel()
        view.backgroundColor = .clear
        view.textAlignment = .right
        view.layer.cornerRadius = view.bounds.height / 2
        view.font = .systemFont(ofSize: 17)
        view.textColor = .lightGray
        self.contentView.addSubview(view)
        return view
    }()
    
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }
    
    var detail: String? {
        get {
            return detailLabel.text
        }
        set {
            detailLabel.text = newValue
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let frame = contentView.bounds.inset(by: UIEdgeInsets(top: padding, left: padding, bottom: 0, right: padding))
        titleLabel.frame = frame
        detailLabel.frame = frame
    }
}

@IBDesignable class PaddingLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 5.0
    @IBInspectable var bottomInset: CGFloat = 5.0
    @IBInspectable var leftInset: CGFloat = 12.0
    @IBInspectable var rightInset: CGFloat = 12.0
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }
}





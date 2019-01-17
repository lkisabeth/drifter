//
//  RoundedPurpleButton.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/14/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import Foundation
import UIKit

class RoundedLightPurpleButton: UIButton {
    var highlightedColor = primaryButtonColor {
        didSet {
            if self.isHighlighted {
                backgroundColor = self.highlightedColor
            }
        }
    }
    
    var defaultColor = primaryButtonColor {
        didSet {
            if !isHighlighted {
                backgroundColor = defaultColor
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = highlightedColor
                
            } else {
                backgroundColor = defaultColor
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    func setup() {
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 2.0
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
    }
}

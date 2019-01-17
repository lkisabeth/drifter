//
//  PeerCell.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/16/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import UIKit

class PeerCell: UICollectionViewCell {
    @IBOutlet private var peerIdLabel: UILabel!
    @IBOutlet private var onlineStatusLabel: UILabel!
    
    @IBOutlet var deviceTypeImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let firstSubView: CALayer = layer.sublayers!.first!
        let secondSubView: CALayer = firstSubView.sublayers!.first!
        
        let cornerRadius: CGFloat = 20
        layer.cornerRadius = cornerRadius
        firstSubView.cornerRadius = cornerRadius
        firstSubView.masksToBounds = true
        secondSubView.cornerRadius = cornerRadius
        secondSubView.masksToBounds = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.masksToBounds = false
    }
    
    func configureWith(_ peerInfo: Dictionary<String, Any>) {
        if peerInfo["name"] != nil {
            let userDeviceName = peerInfo["name"] as! String
            peerIdLabel.text = userDeviceName
        }
        
        onlineStatusLabel.textColor = UIColor.vegaGreen
        onlineStatusLabel.text = "ONLINE"
        
        let devType: DeviceType = DeviceType(rawValue: peerInfo["type"] as! Int)!
        switch devType {
        case .undefined:
            deviceTypeImageView.image = nil
        case .android:
            deviceTypeImageView.image = UIImage(named: "android")
        case .ios:
            deviceTypeImageView.image = UIImage(named: "ios")
        }
    }
}

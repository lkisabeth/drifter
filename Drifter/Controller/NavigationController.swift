//
//  NavigationController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/18/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import UIKit

final class NavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = true
        navigationBar.tintColor = .primaryColor
        navigationBar.barTintColor = .white
        navigationBar.installBlurEffect()
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.primaryColor]
        if #available(iOS 11.0, *) {
            navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.primaryColor]
        }
        navigationBar.shadowImage = UIImage()
    }
}

extension UINavigationBar {
    func installBlurEffect() {
        isTranslucent = true
        setBackgroundImage(UIImage(), for: .default)
        let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        var blurFrame = bounds
        blurFrame.size.height += statusBarHeight
        blurFrame.origin.y -= statusBarHeight
        let blurView  = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurView.isUserInteractionEnabled = false
        blurView.frame = blurFrame
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurView)
        blurView.layer.zPosition = -1
    }
}

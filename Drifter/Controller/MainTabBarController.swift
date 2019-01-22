//
//  MainTabBarController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/21/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import UIKit
import SwipeableTabBarController

class MainTabBarController: SwipeableTabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        selectedIndex = 1
        selectedViewController = viewControllers![1]
        /// Set the animation type for swipe
        setSwipeAnimation(type: SwipeAnimationType.sideBySide)
        /// Set the animation type for tap
        setTapAnimation(type: SwipeAnimationType.sideBySide)
        
        /// Disable custom transition on tap.
        //        setTapTransitioning(transition: nil)
        
        /// Set swipe to only work when strictly horizontal.
        setDiagonalSwipe(enabled: true)
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Handle didSelect viewController method here
    }
}

//
//  WelcomeViewController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/9/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework

class WelcomeViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
        
        // Translucent white nav bar with purple font
        let navBar = navigationController?.navigationBar
        navBar?.barTintColor = UIColor.white
        navBar?.titleTextAttributes = [ NSAttributedString.Key.foregroundColor: UIColor.flatPurpleColorDark() ]
        navBar?.tintColor = UIColor.flatPurpleColorDark()
        navBar?.isTranslucent = true
        navBar?.setValue(true, forKey: "hidesShadow")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        logInButton.layer.masksToBounds = true
        logInButton.roundCorners(corners: [.topLeft,.bottomLeft], radius: 35)
        
        signUpButton.layer.masksToBounds = true
        signUpButton.roundCorners(corners: [.topRight,.bottomRight], radius: 35)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

extension UIButton
{
    func roundCorners(corners:UIRectCorner, radius: CGFloat)
    {
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius)).cgPath
        self.layer.mask = maskLayer
    }
}

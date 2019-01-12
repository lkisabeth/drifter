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
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PushPopAnimator(operation: operation)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar
        self.navigationController?.isNavigationBarHidden = true;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if user already logged in, bypass login/register
        if Auth.auth().currentUser != nil {
            performSegue(withIdentifier: "goToChatList", sender: self)
        }
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar for the next screen
        self.navigationController?.isNavigationBarHidden = false;
        // Hide the "Back" text from the back button for the next screen
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
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

class PushPopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let operation: UINavigationController.Operation
    
    init(operation: UINavigationController.Operation) {
        self.operation = operation
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let from = transitionContext.viewController(forKey: .from)!
        let to   = transitionContext.viewController(forKey: .to)!
        
        let rightTransform = CGAffineTransform(translationX: transitionContext.containerView.bounds.size.width, y: 0)
        if operation == .push {
            to.view.transform = rightTransform
            transitionContext.containerView.addSubview(to.view)
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                to.view.transform = .identity
            }, completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        } else if operation == .pop {
            to.view.transform = .identity
            transitionContext.containerView.insertSubview(to.view, belowSubview: from.view)
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                from.view.transform = rightTransform
            }, completion: { finished in
                from.view.transform = .identity
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
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

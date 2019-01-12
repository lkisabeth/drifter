//
//  LoginViewController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/9/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import SVProgressHUD

class LogInViewController: UIViewController {
    
    @IBOutlet var emailTextfield: UITextField!
    @IBOutlet var passwordTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextfield.setBottomBorder()
        passwordTextfield.setBottomBorder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func logInPressed(_ sender: AnyObject) {
        
        SVProgressHUD.show()
        
        Auth.auth().signIn(withEmail: emailTextfield.text!, password: passwordTextfield.text!) {
            (user, error) in
            
            if error != nil {
                print(error!)
            } else {
                print("Log in successful!")
                
                SVProgressHUD.dismiss()
                
                self.performSegue(withIdentifier: "goToChatList", sender: self)
            }
        }
    }

}

extension UITextField {
    func setBottomBorder() {
        self.borderStyle = .none
        self.layer.backgroundColor = UIColor.white.cgColor
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
}

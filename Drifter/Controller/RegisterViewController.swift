//
//  RegisterViewController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/9/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class RegisterViewController: UIViewController {
    
    @IBOutlet var firstNameTextfield: UITextField!
    @IBOutlet var lastNameTextfield: UITextField!
    @IBOutlet var birthdayTextfield: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstNameTextfield.setBottomBorder()
        lastNameTextfield.setBottomBorder()
        birthdayTextfield.setBottomBorder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func registerPressed(_ sender: AnyObject) {
        
        SVProgressHUD.show()
        
        /*Auth.auth().createUser(withEmail: emailTextfield.text!, password: lastNameTextfield.text!) {
            (user, error) in
            if error != nil {
                print(error!)
            } else {
                print("Registration Successful!")
                
                SVProgressHUD.dismiss()
                
                self.performSegue(withIdentifier: "goToChatList", sender: self)
            }
        }*/
    }
    
}

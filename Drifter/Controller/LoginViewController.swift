//
//  LoginViewController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/9/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import UIKit
import Firebase

class LogInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var emailTextfield: UITextField!
    @IBOutlet var passwordTextfield: UITextField!
    @IBOutlet var dismissButton: UIButton!
    
    var logInButton: RoundedLightPurpleButton!
    var activityView: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        emailTextfield.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        logInButton = RoundedLightPurpleButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        logInButton.setTitleColor(.white, for: .normal)
        logInButton.setTitle("Log In", for: .normal)
        logInButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.bold)
        logInButton.center = CGPoint(x: view.center.x, y: view.frame.height - logInButton.frame.height - 218)
        logInButton.highlightedColor = primaryButtonColor
        logInButton.defaultColor = primaryButtonColor
        logInButton.addTarget(self, action: #selector(handleSignIn), for: .touchUpInside)
        logInButton.alpha = 0.5
        
        view.addSubview(logInButton)
        setLogInButton(enabled: false)
        
        activityView = UIActivityIndicatorView(style: .white)
        activityView.color = .white
        activityView.frame = CGRect(x: 0, y: 0, width: 50.0, height: 50.0)
        activityView.center = logInButton.center
        
        view.addSubview(activityView)
        
        emailTextfield.delegate = self
        passwordTextfield.delegate = self
        emailTextfield.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        passwordTextfield.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        emailTextfield.resignFirstResponder()
        passwordTextfield.resignFirstResponder()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func handleDismissButton(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    /**
     Adjusts the center of the **logInButton** above the keyboard.
     - Parameter notification: Contains the keyboardFrame info.
     */
    
    @objc func keyboardWillAppear(notification: NSNotification){
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        logInButton.center = CGPoint(x: view.center.x,
                                        y: view.frame.height - keyboardFrame.height - 30.0 - logInButton.frame.height / 2)
        activityView.center = logInButton.center
    }
    
    /**
     Enables the logIn button if the **username**, **email**, and **password** fields are all non-empty.
     
     - Parameter target: The targeted **UITextField**.
     */
    
    @objc func textFieldChanged(_ target:UITextField) {
        let email = emailTextfield.text
        let password = passwordTextfield.text
        let formFilled = email != nil && email != "" && password != nil && password != ""
        setLogInButton(enabled: formFilled)
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Resigns the target textField and assigns the next textField in the form.
        
        switch textField {
        case emailTextfield:
            emailTextfield.resignFirstResponder()
            passwordTextfield.becomeFirstResponder()
            break
        case passwordTextfield:
            handleSignIn()
            break
        default:
            break
        }
        return true
    }
    
    /**
     Enables or Disables the **logInButton**.
     */
    
    func setLogInButton(enabled:Bool) {
        if enabled {
            logInButton.alpha = 1.0
            logInButton.isEnabled = true
        } else {
            logInButton.alpha = 0.5
            logInButton.isEnabled = false
        }
    }
    
    @objc func handleSignIn() {
        guard let email = emailTextfield.text else { return }
        guard let pass = passwordTextfield.text else { return }
        
        setLogInButton(enabled: false)
        logInButton.setTitle("", for: .normal)
        activityView.startAnimating()
        
        Auth.auth().signIn(withEmail: email, password: pass) { user, error in
            if error == nil && user != nil {
                if let storyboard = self.storyboard {
                    let vc = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as! UITabBarController
                    self.present(vc, animated: true, completion: nil)
                }
            } else {
                print("Error logging in: \(error!.localizedDescription)")
                self.resetForm()
            }
        }
    }
    
    func resetForm() {
        let alert = UIAlertController(title: "Error Logging In", message: "Please try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        setLogInButton(enabled: true)
        logInButton.setTitle("Log In", for: .normal)
        activityView.stopAnimating()
    }

}

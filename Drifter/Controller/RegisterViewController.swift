//
//  RegisterViewController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/9/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import Firebase
import TransitionButton
import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var backButton: UIButton!
    
    var signUpButton = TransitionButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil

        signUpButton.backgroundColor = UIColor.secondaryButtonColor
        signUpButton.setTitleColor(.white, for: .normal)
        signUpButton.setTitle("Sign Up", for: .normal)
        signUpButton.cornerRadius = 25
        signUpButton.spinnerColor = .white
        signUpButton.center = CGPoint(x: view.center.x, y: view.frame.height - signUpButton.frame.height - 218)
        signUpButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        signUpButton.alpha = 0.5
        
        view.addSubview(signUpButton)
        setsignUpButton(enabled: false)
        
        backButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
        
        usernameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        
        usernameField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        emailField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            // this is to prevent keyboard flickering
            self.usernameField.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    /**
     Adjusts the center of the **signUpButton** above the keyboard.
     - Parameter notification: Contains the keyboardFrame info.
     */
    
    @objc func keyboardWillAppear(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        signUpButton.center = CGPoint(x: view.center.x,
                                      y: view.frame.height - keyboardFrame.height - 30.0 - signUpButton.frame.height / 2)
    }
    
    /**
     Enables the continue button if the **username**, **email**, and **password** fields are all non-empty.
     
     - Parameter target: The targeted **UITextField**.
     */
    
    @objc func textFieldChanged(_ target: UITextField) {
        let username = usernameField.text
        let email = emailField.text
        let password = passwordField.text
        let formFilled = username != nil && username != "" && email != nil && email != "" && password != nil && password != ""
        setsignUpButton(enabled: formFilled)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameField:
            usernameField.resignFirstResponder()
            emailField.becomeFirstResponder()
            break
        case emailField:
            emailField.resignFirstResponder()
            passwordField.becomeFirstResponder()
            break
        case passwordField:
            handleSignUp()
            break
        default:
            break
        }
        return true
    }
    
    @objc func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func setsignUpButton(enabled: Bool) {
        if enabled {
            signUpButton.alpha = 1.0
            signUpButton.isEnabled = true
        } else {
            signUpButton.alpha = 0.5
            signUpButton.isEnabled = false
        }
    }
    
    @objc func handleSignUp() {
        guard let username = usernameField.text else { return }
        guard let email = emailField.text else { return }
        guard let pass = passwordField.text else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        signUpButton.startAnimation()
        
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        
        backgroundQueue.async {
            Auth.auth().createUser(withEmail: email, password: pass) { _, error in
                if error != nil {
                    self.signUpButton.stopAnimation(animationStyle: .shake) {
                        print(error!)
                        self.resetForm()
                    }
                } else {
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = username
                    changeRequest?.commitChanges { error in
                        if error != nil {
                            print(error!)
                            self.resetForm()
                        } else {
                            self.signUpButton.stopAnimation(animationStyle: .expand) {
                                if let storyboard = self.storyboard {
                                    let vc = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as! UITabBarController
                                    self.present(vc, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func resetForm() {
        let alert = UIAlertController(title: "Error signing up", message: "Please try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        
        setsignUpButton(enabled: true)
    }
}

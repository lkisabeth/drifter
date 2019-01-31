//
//  LoginViewController.swift
//  Drifter
//
//  Created by Lucas Kisabeth on 1/9/19.
//  Copyright © 2019 Lucas Kisabeth. All rights reserved.
//

import Firebase
import TransitionButton
import UIKit

class LogInViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var emailTextfield: UITextField!
    @IBOutlet var passwordTextfield: UITextField!
    @IBOutlet var backButton: UIButton!
    
    let logInButton = TransitionButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil

        logInButton.backgroundColor = UIColor.primaryColor
        logInButton.setTitleColor(.white, for: .normal)
        logInButton.setTitle("Log In", for: .normal)
        logInButton.cornerRadius = 25
        logInButton.spinnerColor = .white
        logInButton.center = CGPoint(x: view.center.x, y: view.frame.height - logInButton.frame.height - 218)
        logInButton.addTarget(self, action: #selector(handleSignIn), for: .touchUpInside)
        logInButton.alpha = 0.5
        
        view.addSubview(logInButton)
        setLogInButton(enabled: false)
        
        backButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
        
        emailTextfield.delegate = self
        passwordTextfield.delegate = self
        
        emailTextfield.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        passwordTextfield.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { // Change `2.0` to the desired number of seconds.
            self.emailTextfield.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func keyboardWillAppear(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        logInButton.center = CGPoint(x: view.center.x,
                                     y: view.frame.height - keyboardFrame.height - 30.0 - logInButton.frame.height / 2)
    }
    
    @objc func textFieldChanged(_ target: UITextField) {
        let email = emailTextfield.text
        let password = passwordTextfield.text
        let formFilled = email != nil && email != "" && password != nil && password != ""
        setLogInButton(enabled: formFilled)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
    
    @objc func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func setLogInButton(enabled: Bool) {
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
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        logInButton.startAnimation()
        
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        
        backgroundQueue.async {
            Auth.auth().signIn(withEmail: email, password: pass) { user, error in
                if error == nil, user != nil {
                    self.logInButton.stopAnimation(animationStyle: .expand) {
                        if let storyboard = self.storyboard {
                            let vc = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as! UITabBarController
                            self.present(vc, animated: true, completion: nil)
                        }
                    }
                } else {
                    self.logInButton.stopAnimation(animationStyle: .shake) {
                        print("Error logging in: \(error!.localizedDescription)")
                        self.resetForm()
                    }
                }
            }
        }
    }
    
    func resetForm() {
        let alert = UIAlertController(title: "Error Logging In", message: "Please try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        
        setLogInButton(enabled: true)
    }
}

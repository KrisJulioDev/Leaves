//
//  SigninViewController.swift
//  7Leaves Card
//
//  Created by Jason McCoy on 1/30/17.
//  Copyright © 2016 Jason McCoy. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import TwitterKit
import KYDrawerController
import GoogleSignIn

class SigninViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {

    var usersRef: FIRDatabaseReference!
    var currentUserRef: FIRDatabaseReference!
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var showorhideButton: UIButton!
    @IBOutlet weak var emailError: UILabel!
    @IBOutlet weak var passwordError: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var superViewtoCenterDistance: NSLayoutConstraint!
    @IBOutlet weak var socialSignin: UIView!
    @IBOutlet weak var signinButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        usersRef = FIRDatabase.database().reference(withPath: "users")
        
        // Show view button on right view of password textfiled
        password.rightView = showorhideButton
        password.rightViewMode = UITextFieldViewMode.whileEditing
        
        // Google Sign in
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        // Hide Keyboard when tapped around
        self.hideKeyboardWhenTappedAround()
        
        self.signinButton.layer.borderColor = UIColor.white.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Keyboard Notification
        //NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                if user.isEmailVerified || (FBSDKAccessToken.current() != nil) || (Twitter.sharedInstance().sessionStore.session() != nil) {
                    
                    //Push User into firebase schema
                    self.pushUsertoFirebase(user: user)
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        email.underlined(color: UIColor.white, width: 1.0)
        password.underlined(color: UIColor.white, width: 1.0)
    }
    
    func pushUsertoFirebase(user: FIRUser) {
        currentUserRef = self.usersRef.child(user.uid)
        currentUserRef.observeSingleEvent(of: .value, with: { snapshot in
            if (!snapshot.hasChildren()) {
                let key = snapshot.key
                let index = key.index(key.startIndex, offsetBy: 8)
                if (FBSDKAccessToken.current() != nil) {
                    let profile = user.providerData[0]
                    let currentUser = [
                        "name": profile.displayName ?? "",
                        "email": profile.email ?? "",
                        "stampCount" : 0,
                        "redeemCount": 0,
                        "photoURL": "\(profile.photoURL!)",
                        "referralCode": key.substring(to: index).uppercased(),
                        "isReferralUsed": false,
                    ] as [String : Any]
                    self.currentUserRef.setValue(currentUser)
                } else if (Twitter.sharedInstance().sessionStore.session() != nil) {
                    let profile = user.providerData[0]
                    let currentUser = [
                        "name": profile.displayName ?? "",
                        "email": profile.email ?? "",
                        "stampCount" : 0,
                        "redeemCount": 0,
                        "referralCode": key.substring(to: index).uppercased(),
                        "isReferralUsed": false,
                        ] as [String : Any]
                    self.currentUserRef.setValue(currentUser)
                } else if ( GIDSignIn.sharedInstance().currentUser != nil) {
                    let profile = user.providerData[0]
                    let currentUser = [
                        "name": profile.displayName ?? "",
                        "email": profile.email ?? "",
                        "stampCount" : 0,
                        "redeemCount": 0,
                        "referralCode": key.substring(to: index).uppercased(),
                        "photoURL": "\(profile.photoURL!)",
                        "isReferralUsed": false,
                        ] as [String : Any]
                    self.currentUserRef.setValue(currentUser)
                } else {
                    let currentUser = [
                        "name": user.displayName!,
                        "email": user.email!,
                        "stampCount": 0,
                        "redeemCount": 0,
                        "referralCode": key.substring(to: index).uppercased(),
                        "isReferralUsed": false,
                    ] as [String : Any]
                    self.currentUserRef.setValue(currentUser)
                }
            }
        })
        DispatchQueue.main.async {
            // Code to include navigation drawer
            let mainViewController   = self.storyboard?.instantiateViewController(withIdentifier: "homeVC")
            let drawerViewController = self.storyboard?.instantiateViewController(withIdentifier: "drawerVC")
            let drawerController     = KYDrawerController(drawerDirection: .left, drawerWidth: (UIScreen.main.bounds.size.width) * 0.75)
            drawerController.mainViewController = mainViewController
            drawerController.drawerViewController = drawerViewController
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window?.rootViewController = drawerController
            //self.performSegue(withIdentifier: "homepage", sender: self)
        }
    }
    
    @IBAction func onShoworHidePassword(_ sender: UIButton) {
        if sender.tag == 1 {
            self.showorhideButton.setTitle("Hide", for: .normal)
            sender.tag = 2
            self.password.isSecureTextEntry = !self.password.isSecureTextEntry
        } else if sender.tag == 2 {
            self.showorhideButton.setTitle("Show", for: .normal)
            sender.tag = 1
            self.password.isSecureTextEntry = !self.password.isSecureTextEntry
        }
    }
    
    @IBAction func onSignin(_ sender: UIButton) {
        if emailValidation() && passwordValidation() {
            view.endEditing(true)
            self.activityIndicator.startAnimating()
            FIRAuth.auth()?.signIn(withEmail: email.text!, password: password.text!) { (user, error) in
                if error == nil {
                    if !(user?.isEmailVerified)! {
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                            self.simpleAlert(message: "Please verify your email before signing in.")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.simpleAlert(message: (error?.localizedDescription)!)
                    }
                }
            }
        }
    }
    
    @IBAction func onForgotPassword(_ sender: UIButton) {
        if emailValidation() {
            view.endEditing(true)
            self.activityIndicator.startAnimating()
            FIRAuth.auth()?.sendPasswordReset(withEmail: email.text!) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.simpleAlert(message: error.localizedDescription)
                    }
                } else {
                    self.activityIndicator.stopAnimating()
                    self.simpleAlert(message: "Please check your email to reset your password.")
                }
            }
        }
    }

    @IBAction func onTwitterLogin(_ sender: UIButton) {
        self.activityIndicator.startAnimating()
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func onGmailLogin( _ send: UIButton ) {
        self.activityIndicator.startAnimating()
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func onFBLogin(_ sender: FBSDKLoginButton) {
        self.activityIndicator.startAnimating()
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["public_profile", "email"/*, "user_friends"*/], from: self) { (result, error) -> Void in
            if(error != nil) {
                fbLoginManager.logOut()
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.simpleAlert(message: (error?.localizedDescription)!)
                }
            } else if (result?.isCancelled)! {
                fbLoginManager.logOut()
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
            } else {
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                    if error == nil {
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                            self.simpleAlert(message: (error?.localizedDescription)!)
                        }
                    }
                }
            }
        }
    }
    
    func emailValidation() -> Bool {
        if email.text == "" {
            email.underlined(color: UIColor.white, width: 1.0)
            emailError.isHidden = false
            return false
        }
        if !(email.text?.isValidEmail())! {
            email.underlined(color: UIColor.white, width: 1.0)
            emailError.isHidden = false
            return false
        }
        return true
    }
    
    func passwordValidation() -> Bool {
        if password.text == "" {
            password.underlined(color: UIColor.white, width: 1.0)
            passwordError.isHidden = false
            return false
        }
        return true
    }
    
    @IBAction func passwordEditing(_ sender: UITextField) {
        self.passwordError.isHidden = true
        self.password.underlined(color: UIColor.white, width: 1.0)
    }
    
    @IBAction func emailEditing(_ sender: UITextField) {
        emailError.isHidden = true
        email.underlined(color: UIColor.white, width: 1.0)
    }
    
    func hideErrorLabels() {
        email.underlined(color: UIColor.white, width: 1.0)
        password.underlined(color: UIColor.white, width: 1.0)
        emailError.isHidden = true
        passwordError.isHidden = true
    }
    
    /*
    // MARK: - AutoLayout Keyboard
    func keyboardWillShow(notification: NSNotification) {
        let keyboardSize = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double

        self.superViewtoCenterDistance.constant = -keyboardSize.height/4
        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
            self.socialSignin.alpha = 0
        })
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        self.superViewtoCenterDistance.constant = 0
        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
            self.socialSignin.alpha = 1
        })
    }
    */
    
    // Simple alerts with message and ok action
    func simpleAlert(message: String) {
        let alert = UIAlertController(title: "✉️", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        present(alert, animated: true, completion: nil)
    }
}


// MARK: Textfield Delegate
extension SigninViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField
        {
        case email:
            password.becomeFirstResponder()
            break
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}

extension SigninViewController {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            self.simpleAlert(message: error.localizedDescription)
        }
        
        guard let authentication = user.authentication else { return }
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                          accessToken: authentication.accessToken)
        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
            if let error = error {
                self.simpleAlert(message: error.localizedDescription)
            } else if let usr = user {
                self.pushUsertoFirebase(user: usr)
            }
        }
    }
}

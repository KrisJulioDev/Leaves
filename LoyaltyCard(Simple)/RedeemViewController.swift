//
//  RedeemViewController.swift
//  LoyaltyCard(Simple)
//
//  Created by Jason McCoy on 2/4/17.
//  Copyright © 2016 Jason McCoy. All rights reserved.
//

import UIKit
import Firebase

class RedeemViewController: UIViewController {

    @IBOutlet weak var redeemCode: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var currentUserRef: FIRDatabaseReference!
    var usersRef: FIRDatabaseReference!
    var selfCode: String!
    var isReferralUsed = true
    var isVerificationSuccess = false
    var userName: String!
    var photoURL: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        currentUserRef = FIRDatabase.database().reference(withPath: "users/\(FIRAuth.auth()!.currentUser!.uid)")
        usersRef = FIRDatabase.database().reference(withPath: "users")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentUserRef.observeSingleEvent(of: .value, with: { snapshot in
            let userData = snapshot.value as! Dictionary<String, AnyObject>
            self.selfCode = userData["referralCode"] as! String!
            self.isReferralUsed = userData["isReferralUsed"] as! Bool!
            self.userName = userData["name"] as! String!
            if let profileURL = userData["photoURL"] {
                self.photoURL = profileURL as? String
            }
        })
    }

    @IBAction func onClose(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func onVerify(_ sender: UIButton) {
        view.endEditing(true)
        self.activityIndicator.startAnimating()
        self.isReferralValid()
    }
    
    func isReferralValid() {
        if redeemCode.text == "" {
            self.activityIndicator.stopAnimating()
            self.simpleAlert(message: "Please enter a redeem code.")
        } else if (redeemCode.text?.characters.count)! < 8 || (redeemCode.text?.characters.count)! > 8{
            self.activityIndicator.stopAnimating()
            self.simpleAlert(message: "We don't recognize this redeem code.")
        } else if selfCode == redeemCode.text! {
            self.activityIndicator.stopAnimating()
            self.simpleAlert(message: "You cannot use your own referral code.")
        } else if isReferralUsed {
            self.activityIndicator.stopAnimating()
            self.simpleAlert(message: "You have exceeded the redeem limit.")
        } else {
            self.isCodeAvailableInFirebase()
        }
    }
    
    func isCodeAvailableInFirebase() {
        let query = usersRef.queryOrdered(byChild: "referralCode").queryEqual(toValue: self.redeemCode.text!)
        query.observeSingleEvent(of: .value) { (data: FIRDataSnapshot) in
            if data.childrenCount == 1 {
                self.activityIndicator.stopAnimating()
                self.isVerificationSuccess = true
                ViewController.sharedInstance.isReferralUsed = true
                self.currentUserRef.child("isReferralUsed").setValue(true)
                for item in data.children {
                    let item = item as! FIRDataSnapshot
                    self.currentUserRef.child("referralID").setValue(item.key)
                    self.addIntoTeam(ownerId: item.key)
                }
                self.simpleAlert(message: "Congrats! You got one free stamp")
            } else {
                self.activityIndicator.stopAnimating()
                self.simpleAlert(message: "Invalid Code")
            }
        }
        /*
        usersRef.queryOrdered(byChild: "referralCode").queryEqual(toValue: self.redeemCode.text!).observe(.childAdded, with: { snapshot in
            print("inside snapshot")
            if (snapshot.value as? NSDictionary) != nil {
                if snapshot.exists() {
                    self.activityIndicator.stopAnimating()
                    self.isVerificationSuccess = true
                    ViewController.sharedInstance.isReferralUsed = true
                    self.currentUserRef.child("isReferralUsed").setValue(true)
                    self.currentUserRef.child("referralID").setValue(snapshot.key)
                    self.addIntoTeam(ownerId: snapshot.key)
                    self.simpleAlert(message: "Congrats! You got one free stamp")
                } else {
                    self.activityIndicator.stopAnimating()
                    self.simpleAlert(message: "Invalid Code")
                }
            } else {
                self.activityIndicator.stopAnimating()
                self.simpleAlert(message: "Invalid Code")
            }
        })
         */
    }
    
    func addIntoTeam(ownerId: String) {
        let ownerRef = FIRDatabase.database().reference(withPath: "users/\(ownerId)")
        let data = [
            "name": self.userName!,
            "isFreeStampGiven": false
        ] as [String : Any]
        ownerRef.child("teams/\(FIRAuth.auth()!.currentUser!.uid)").setValue(data)
        if (self.photoURL != nil) {
            ownerRef.child("teams/\(FIRAuth.auth()!.currentUser!.uid)").child("photoURL").setValue(self.photoURL!)
        }
    }
    
    func simpleAlert(message: String) {
        let alert = UIAlertController(title: "✉️", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            alert.dismiss(animated: true, completion: nil)
            if self.isVerificationSuccess {
                self.dismiss(animated: true, completion: nil)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
}

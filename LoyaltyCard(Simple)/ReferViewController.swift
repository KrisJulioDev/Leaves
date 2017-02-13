//
//  ReferViewController.swift
//  LoyaltyCard(Simple)
//
//  Created by Jason McCoy on 2/4/17.
//  Copyright © 2016 Jason McCoy. All rights reserved.
//

import UIKit
import Firebase

class ReferViewController: UIViewController {

    var message:String!
    var appLink:NSURL!
    
    @IBOutlet weak var referralCode: UITextView!
    var currentUserRef: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentUserRef = FIRDatabase.database().reference(withPath: "users/\(FIRAuth.auth()!.currentUser!.uid)")
        self.appLink = NSURL(string: "https://jf27z.app.goo.gl/Tbeh")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentUserRef.observeSingleEvent(of: .value, with: { snapshot in
            let userData = snapshot.value as! Dictionary<String, AnyObject>
            self.referralCode.text = userData["referralCode"] as! String!
            self.message = "Download 7Leaves Card App, go to Redeem Code & enter \(self.referralCode.text!) to get a FREE stamp. Get it here: "
        })
    }
    
    @IBAction func onClose(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onRefer(_ sender: UIButton) {
        let activityVC = UIActivityViewController(activityItems: [self.message, self.appLink!], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
        activityVC.completionWithItemsHandler = { activity, success, items, error in
            
            if activity == UIActivityType.postToFacebook {
                print("facebook")
            }
        }
    }
}

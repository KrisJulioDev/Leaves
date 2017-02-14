//
//  ReferViewController.swift
//  LoyaltyCard(Simple)
//
//  Created by Jason McCoy on 2/4/17.
//  Copyright © 2016 Jason McCoy. All rights reserved.
//

import UIKit
import Firebase
import Alamofire
import SwiftyJSON

class ReferViewController: UIViewController {

    var message:String!
    var appLink:NSURL!
    
    @IBOutlet weak var referralCode: UITextView!
    var currentUserRef: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let postURL = "https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=AIzaSyAzvEyYL3f-KV72HhbsEcpm2Ex3gqyw_I8"
        let firebaseDomain  = "https://jf27z.app.goo.gl"
        let domain = "com.jasonmccoy.a7leavescardx"
        
        let param = ["longDynamicLink": "\(firebaseDomain)/?link=http://7leavescafe.com/app_share_code?redeem_code=\(self.referralCode.text!)/method/link&apn=\(domain)&amv=31&al=7leaves://redeem_code/\((self.referralCode.text!))"]
        
        Alamofire.request(postURL, method: .post, parameters: param, encoding: JSONEncoding.default, headers: [:]).responseString { response in
            
            if let data = response.data {
                let responseString = JSON(data: data)
                let rS = responseString["shortLink"].string ?? "invalid link"
                debugPrint(rS)
            }
        }

        
        
//        http://7leavescafe.com/app_share_code?redeem_code=4ED81BDE
        
        currentUserRef = FIRDatabase.database().reference(withPath: "users/\(FIRAuth.auth()!.currentUser!.uid)")
        //self.appLink = NSURL(string: "https://jf27z.app.goo.gl/Tbeh")
        self.appLink = NSURL(string: "http://7leavescafe.com/app_share_code?redeem_code=\(self.referralCode.text!)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentUserRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.value is NSNull { return }
 
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

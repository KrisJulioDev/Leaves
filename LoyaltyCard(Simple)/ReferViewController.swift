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
    var deeplink:String?
    
    @IBOutlet weak var referralCode: UITextView!
    var currentUserRef: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        currentUserRef = FIRDatabase.database().reference(withPath: "users/\(FIRAuth.auth()!.currentUser!.uid)")
        self.appLink = NSURL(string: "http://7leavescafe.com/app_share_code?redeem_code=\(self.referralCode.text!)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentUserRef.observeSingleEvent(of: .value, with: { snapshot in
            let userData = snapshot.value as! Dictionary<String, AnyObject>
            self.referralCode.text = userData["referralCode"] as! String!
            self.message = "Download 7Leaves Card App, go to Redeem Code & enter \(self.referralCode.text!) to get a FREE stamp. Get it here: "
            
            self.requestForDeeplink()
        })
    }
    
    func requestForDeeplink() {
        let postURL = "https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=AIzaSyAzvEyYL3f-KV72HhbsEcpm2Ex3gqyw_I8"
        let firebaseDomain  = "https://jf27z.app.goo.gl"
        let code = self.referralCode.text ?? ""
        
        let parameters = ["longDynamicLink": "\(firebaseDomain)/?link=http://7leavescafe.com/app_share_code=\(code)&apn=com.jasonmccoy.a7leavescardx&isi=1187702945&ibi=com.JasonMcCoy.7LeavesCard&al=7leaves://app_share_code=\(code)&st=Get+free+stamp&sd=Get+a+free+stamp+when+using+this+code!&si=https://firebasestorage.googleapis.com/v0/b/leaves-cafe.appspot.com/o/selectedStar%25402x.png?alt%3Dmedia%26token%3D61ffb2ee-a866-40ba-a1a2-57fa9cc2c852"
        ]
        
        Alamofire.request(postURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:])
            .responseString(completionHandler: {
                response in
                
                if let data = response.data {
                    let responseString = JSON(data: data)
                    let dL = responseString["shortLink"].string ?? "invalid link"
                    self.deeplink = dL
                    debugPrint(self.deeplink ?? "")
                }
            })
        
    }
    
    @IBAction func onClose(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onRefer(_ sender: UIButton) {
        
        var activityItems = [Any]()
        activityItems.append(self.message)
        
        if self.deeplink == nil {
            activityItems.append(self.appLink!)
        } else {
            activityItems.append(self.deeplink ?? "")
        }
        
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
        activityVC.completionWithItemsHandler = { activity, success, items, error in
            
            if activity == UIActivityType.postToFacebook {
                print("facebook")
            }
        }
    }
}

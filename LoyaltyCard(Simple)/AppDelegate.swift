//
//  AppDelegate.swift
//  7Leaves Card
//
//  Created by Jason McCoy on 12/17/16.
//  Copyright © 2016 Jason McCoy. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Fabric
import TwitterCore
import TwitterKit
import CoreData
import CoreLocation
import IQKeyboardManagerSwift
import KYDrawerController
import Firebase
import GoogleSignIn
import FBSDKLoginKit
import FirebaseDynamicLinks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        
        // Use Firebase library to configure APIs
        FIROptions.default().deepLinkURLScheme = "7leaves"
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
        RemoteConfig().initialize()
        
        let _ = RCValues.sharedInstance
        Twitter.sharedInstance().start(withConsumerKey: "I4pH4vNNFfRcfiAhCH6xDa3p1", consumerSecret: "H7KogpW7Gnalc7MtHxfCxjJ7fXXvZfUkT690Ns8oygbgETMwHD")
        Fabric.with([Twitter.self])
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // if uninstalled logout the user
        let userDefaults = UserDefaults.standard
        let isSignedIn = userDefaults.bool(forKey: "isSignedIn")
        let loginVC = storyboard.instantiateViewController(withIdentifier: "SigninViewController") as! SigninViewController
        let signupVC = storyboard.instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        
        
        if !isSignedIn {
            do {
                try FIRAuth.auth()?.signOut()
            }catch {
                
            }
            self.window?.rootViewController = signupVC
        } else if FIRAuth.auth()!.currentUser != nil {
            
            self.checkUserAgainstDatabase(completion: {
                success, error in
                
                if success == true {
                    
                    // Code to include navigation drawer
                    let mainViewController   = storyboard.instantiateViewController(withIdentifier: "homeVC")
                    let drawerViewController = storyboard.instantiateViewController(withIdentifier: "drawerVC")
                    let drawerController     = KYDrawerController(drawerDirection: .left, drawerWidth: (UIScreen.main.bounds.size.width) * 0.75)
                    drawerController.mainViewController = mainViewController
                    drawerController.drawerViewController = drawerViewController
                    self.window?.rootViewController = drawerController
                    
                } else {
                    self.forceLogout()
                }
                
            })
            
        } else {
            self.window?.rootViewController = loginVC
        }
 
        
        
        IQKeyboardManager.sharedManager().enable = true
        
        // init google signin
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        
        // Facebook
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func checkUserAgainstDatabase(completion: @escaping (_ success: Bool, _ error: NSError?) -> Void) {
        guard let currentUser = FIRAuth.auth()?.currentUser else { return }
        
        let usersRef = FIRDatabase.database().reference(withPath: "users")
        let currentUserRef = usersRef.child(currentUser.uid)
        currentUserRef.observe(.value, with: {
            snapshot in
            
            if snapshot.value is NSNull {
                completion(false, nil)
            } else {
                completion(true, nil)
            }
            
        })
    }
    
    
    // Facebook Delegate
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
       
        let dynamicLink = FIRDynamicLinks.dynamicLinks()?.dynamicLink(fromCustomSchemeURL: url)
        if let dynamicLink = dynamicLink {
            // Handle the deep link. For example, show the deep-linked content or
            // apply a promotional offer to the user's account.
            // ...
            return true
        }
 
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url as URL!, sourceApplication: sourceApplication, annotation: annotation) || GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                     annotation: [:])
                || FBSDKApplicationDelegate.sharedInstance().application(application, open: url, options: options)
    }
    
    func forceLogout() {
        if FIRAuth.auth()!.currentUser != nil {
            UserDefaultsManager.saveDefaults(latteStamps: 0, redeemCount: 0)
        }
        do {
            
            GIDSignIn.sharedInstance().signOut()
            
            let store = Twitter.sharedInstance().sessionStore
            
            if let userID = store.session()?.userID {
                store.logOutUserID(userID)
            }
            
            FBSDKLoginManager().logOut()
            try FIRAuth.auth()!.signOut()
            
            
        } catch _ as NSError {
            
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "SigninViewController") as? SigninViewController {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window?.rootViewController = viewController
        }
    }
    
}/*
 func handleEvent(forRegion region: CLRegion!) {
 if isUserValidForStamp() {
 let userDefaults = UserDefaults.standard
 userDefaults.set(true, forKey: "stampRedeem")
 userDefaults.setValue(Date(), forKey: "lastRedeemDate")
 // Show an alert if application is active
 if UIApplication.shared.applicationState == .active {
 let message = note(fromRegionIdentifier: region.identifier)
 window?.rootViewController?.showAlert(withTitle: nil, message: message)
 }
 
 // Increase stamp count
 ViewController.sharedInstance.latteStamps += 1;
 ViewController.sharedInstance.updateUIOfMine()
 UserDefaultsManager.saveDefaults(latteStamps: ViewController.sharedInstance.latteStamps, redeemCount: ViewController.sharedInstance.redeemCount)
 if FIRAuth.auth()!.currentUser != nil {
 let userRef = FIRDatabase.database().reference(withPath: "users/\(FIRAuth.auth()!.currentUser!.uid)")
 userRef.child("/stampCount").setValue(ViewController.sharedInstance.latteStamps)
 }
 }
 }
 
 func note(fromRegionIdentifier identifier: String) -> String? {
 let geotifications = ViewController.sharedInstance.geotifications
 for each in geotifications {
 if each.identifier == identifier {
 return each.note
 }
 }
 return "Congrats! You got free Stamp"
 }
 
 func isUserValidForStamp() -> Bool {
 // show only once per day
 let userDefaults = UserDefaults.standard
 let onceCheck = userDefaults.bool(forKey: "stampRedeem")
 let startDate = RCValues.sharedInstance.string(forKey: .startDate).getDate()
 let endDate = RCValues.sharedInstance.string(forKey: .endDate).getDate()
 let dateCheck = Date().isBetweeen(date1: startDate, date2: endDate)
 if !onceCheck && dateCheck {
 return true
 } else {
 return false
 }
 }
 
 }*/

/*
 extension AppDelegate: CLLocationManagerDelegate {
 
 func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
 if region is CLCircularRegion {
 handleEvent(forRegion: region)
 }
 }
 
 func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
 if region is CLCircularRegion {
 handleEvent(forRegion: region)
 }
 }
 }
 */

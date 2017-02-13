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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    var window: UIWindow?
    let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        
        // Use Firebase library to configure APIs
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
        let _ = RCValues.sharedInstance
        Twitter.sharedInstance().start(withConsumerKey: "I4pH4vNNFfRcfiAhCH6xDa3p1", consumerSecret: "H7KogpW7Gnalc7MtHxfCxjJ7fXXvZfUkT690Ns8oygbgETMwHD")
        Fabric.with([Twitter.self])
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        locationManager.delegate = self
//        locationManager.requestAlwaysAuthorization()
        
        // [END register_for_notifications]
        
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
            // Code to include navigation drawer
            let mainViewController   = storyboard.instantiateViewController(withIdentifier: "homeVC")
            let drawerViewController = storyboard.instantiateViewController(withIdentifier: "drawerVC")
            let drawerController     = KYDrawerController(drawerDirection: .left, drawerWidth: (UIScreen.main.bounds.size.width) * 0.75)
            drawerController.mainViewController = mainViewController
            drawerController.drawerViewController = drawerViewController
            self.window?.rootViewController = drawerController
        } else {
            self.window?.rootViewController = loginVC
        }
        
        IQKeyboardManager.sharedManager().enable = true
        
        // init google signin
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        // Facebook
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // Facebook Delegate
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url as URL!, sourceApplication: sourceApplication, annotation: annotation) || GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url,
                                                        sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                        annotation: [:])
    }
    
}

//MARK: Google Signin Delegate
extension AppDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        if let error = error {
            // ...
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                          accessToken: authentication.accessToken)
        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
            // ...
            if let error = error {
                // ...
                return
            }
        }
        
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!,
                withError error: NSError!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}
    /*
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

//
//  RemoteConfig.swift
//  LoyaltyCard(Simple)
//
//  Created by Kris Julio on 2/14/17.
//
//

import UIKit
import Firebase

class RemoteConfig: NSObject {
    var remoteConfig: FIRRemoteConfig?
    let keys = ["update_01",
                "update_02",
                "update_03",
                "update_04",
                "update_05",
                "update_06",
                "update_07",
                "update_08",
                "update_09",
                "update_10"]
    
    func initialize() {
        remoteConfig = FIRRemoteConfig.remoteConfig()
        let remoteConfigSettings = FIRRemoteConfigSettings(developerModeEnabled: true)
        remoteConfig?.configSettings = remoteConfigSettings!
        
        remoteConfig?.setDefaultsFromPlistFileName("RemoteConfigDefaults")
        
        let expirationDuration = 43200
        remoteConfig?.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { (status, error) -> Void in
            if status == .success {
                print("Config fetched!")
                self.remoteConfig?.activateFetched()
                self.saveVerificationCodes()
                self.saveRedeemCode()
            } else {
                print("Config not fetched")
                print("Error \(error!.localizedDescription)")
            }
        }
    }
    
    func saveVerificationCodes() {
        for (index, key) in keys.enumerated() {
            if let stampCode = self.remoteConfig?[key].stringValue, stampCode != "" {
                let vCode = VerificationCode(code: stampCode, stamps: index + 1)
                verificationCodeArray.append(vCode)
            }
        }
        
        debugPrint(verificationCodeArray)
    }
    
    func saveRedeemCode() {
        if let rCode = self.remoteConfig?["update_redeem"].stringValue, rCode != "" {
            redeemQRCode = rCode
            debugPrint(redeemQRCode)
        }
    }
}

//
//  Utils.swift
//  7Leaves Card
//
//  Created by Jason McCoy on 12/17/16.
//  Copyright © 2016 Jason McCoy. All rights reserved.
//

import UIKit
import AVFoundation


var player: AVAudioPlayer!

class Utils: NSObject {
    
    // Playing sound when stamps are chosen
    public class func playSound() {
        let url = Bundle.main.url(forResource: "click2", withExtension: "mp3")!
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.prepareToPlay()
            player.play()
            print("playing....")
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    // Count days in interval of 2 days
    public class func daysBetweenDates(startDate: Date, endDate: Date) -> Int {
        
        let calendar = NSCalendar.current
        let components = calendar.dateComponents([Calendar.Component.day], from: startDate, to: endDate)
        
        return components.day!
    }
    
    //MARK: - checkAvailable
    // Check the availability of latteStamps to see if the time is more then 10 years. Then clear all 10.
    class func checkAvailable(latteStamps: inout Int) -> Bool {
        
        if latteStamps == 0 {
            UserDefaultsManager.cleanCntStamps()
            latteStamps = 0
        } else {
            let cDate = Date()
            if let sDate = UserDefaultsManager.getCntStamps() {
                
                let days = Utils.daysBetweenDates(startDate: sDate, endDate: cDate)
                if days > 3650 { // 10 years from now, all stamps will cleared.
                    UserDefaultsManager.cleanCntStamps()
                    UserDefaultsManager.saveStampsNumber(value: 0)
                    latteStamps = 0
                    return false
                }
            }else{
                UserDefaultsManager.saveCntStamps(value: cDate)
            }
        }
        return true
    }
    
    // Check latteStamps when button is tapped
    class func checkLatteStamps(latteStamps: inout Int) {
        
        if latteStamps == 0 {
            UserDefaultsManager.cleanCntStamps()
        } else {
            if let sDate =  UserDefaultsManager.getCntStamps() {
                print(sDate)
                let cDate = Date()
                
                print("=======Time Interval=========");
                print(Utils.daysBetweenDates(startDate: sDate , endDate: cDate))
            }else{
                let curDate = Date()
                UserDefaultsManager.saveCntStamps(value: curDate)
            }
        }
        print("stamps equals \(latteStamps)")
    }
    
}

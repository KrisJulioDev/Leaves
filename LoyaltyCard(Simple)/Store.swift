//
//  Store.swift
//  LoyaltyCard(Simple)
//
//  Created by Jason McCoy on 1/31/17.
//  Copyright © 2016 Jason McCoy. All rights reserved.
//

import Foundation
import ObjectMapper

class Store: Mappable {
    var lat: Double!
    var lan: Double!
    var note: String!
    var identifier: String!
    var radius: Double!
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        lat <- map["lat"]
        lan <- map["lan"]
        note <- map["note"]
        identifier <- map["identifier"]
        radius <- map["radius"]
    }
}

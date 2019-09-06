//
//  MotherLocation.swift
//  GeoHashingOnMapKit
//
//  Created by ogulcan keskin on 6.09.2019.
//  Copyright © 2019 ogulcan keskin. All rights reserved.
//

import Foundation


struct LocationDetail: Codable {
    let latitude: String
    let longitude: String
    let title: String
    let geo: String
    var distance: Double?
    
    var dictionary: [String: Any] {
        return [
            "latitude": latitude,
            "longitude": longitude,
            "title": title,
            "geo": geo
        ]
    }
    
    
}


extension LocationDetail {
    
    init?(dictionary: [String : Any]) {
        guard let latitude = dictionary["latitude"] as? String,
            let longitude = dictionary["longitude"] as? String,
            let title = dictionary["title"] as? String,
            let geo = dictionary["geo"] as? String
   
 
        else { return nil }
        
        self.init(latitude: latitude, longitude: longitude, title: title, geo: geo, distance: nil)
    }
}

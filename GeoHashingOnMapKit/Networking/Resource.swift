//
//  Request.swift
//  GeoHashingOnMapKit
//
//  Created by ogulcan keskin on 3.09.2019.
//  Copyright © 2019 ogulcan keskin. All rights reserved.
//

import Foundation

typealias JSONDictionary = [String: AnyObject]

public struct Request {
    let url: NSURL
    // payload
    // path
    // can be added.
}


protocol LocationService: Resource {
    func fetchLocations(result: @escaping (Result<[Episode], APIServiceError>) -> Void)
}

class LocationServiceImpl: LocationService {
    
    func fetchLocations(result: @escaping (Result<[Episode], APIServiceError>) -> Void) {
        call(request: Request(url: NSURL(string: "http://localhost:80/episodes.json")!), result: result)
    }
}




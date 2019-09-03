//
//  Request.swift
//  GeoHashingOnMapKit
//
//  Created by ogulcan keskin on 3.09.2019.
//  Copyright © 2019 ogulcan keskin. All rights reserved.
//

import Foundation

public enum APIServiceError: Error {
    case apiError
    case invalidEndpoint
    case invalidResponse
    case noData
    case decodeError
}

public protocol Resource {
    
}

public extension Resource {
    func call<T: Decodable>(request: Request, result: @escaping (Result<T, APIServiceError>) -> Void) {
        
        return ServiceCore.shared.fetchResources(url: request.url as URL, completion: result)

    }
    
    
}

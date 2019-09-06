//
//  ViewModel.swift
//  GeoHashingOnMapKit
//
//  Created by ogulcan keskin on 6.09.2019.
//  Copyright © 2019 ogulcan keskin. All rights reserved.
//

import Foundation
import GeoFire
import Firebase



protocol ViewModelReachable {
    
    func fetchLocations()
    func control(title: String) -> Bool
    func calculateGeoHash(coordinate: CLLocationCoordinate2D, distance: Double)
    var model: Bindable<[LocationDetail]> {get set}
    var control: Bindable<Bool> {get set}

}




class ViewModel: ViewModelReachable {
    var control: Bindable<Bool> = Bindable(false)
    
    func control(title: String) -> Bool {
        return inrangeArr.contains { $0.title == title
        }
    }
    
    private var inrangeArr: [LocationDetail] = [] {
        didSet {
            control.value = true
        }
    }
    let locationService = LocationServiceImpl()
    var model: Bindable<[LocationDetail]> = Bindable([])
    
    func fetchLocations() {
        Firestore.firestore().collection("locations").getDocuments { (snapshot, err) in
            if let error = err {
                print("Error getting documents: \(error)")
            } else {
                let model = snapshot!.documents.compactMap {
                    LocationDetail.init(dictionary: $0.data())
                }
                
                self.model.value = model
            }
        }
    }
    private func fetchLocationsWithWebService() {
        
        _ = locationService.fetchLocations() { result in
            switch result {
            case .success(let result):
                self.model.value = result
            //                self.createDatas(mother)
            case .failure(let err):
                print(err)
            }
            
        }
    }
    
    private func createDatas(_ arr: [LocationDetail]) {
        
        arr.forEach { Firestore.firestore().document("locations/location\($0.longitude)\($0.title)").setData($0.dictionary)
        }
        
    }
    
    private func returnGeoHash(latitude: String?, longitude: String?) -> String {
        let long: Double = longitude?.toDouble() ?? 0
        let lat: Double = latitude?.toDouble() ?? 0
        let temp = GFGeoHash(location: CLLocationCoordinate2D(latitude: lat, longitude: long))
        return temp?.geoHashValue ?? ""
    }
    
    
    
    func calculateGeoHash(coordinate: CLLocationCoordinate2D, distance: Double) {
        // ~1 mile of lat and lon in degrees
        
        let current = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let queries = GeoHashUtil.shared.getQueriesForDocumentsAround(center: Center(latitude: coordinate.latitude, longitude: coordinate.longitude), radius: distance * 1000)
        let ref = Firestore.firestore().collection("locations")
        
        let snaps = queries.map { location in
            return ref.whereField("geo", isGreaterThanOrEqualTo: location[0]).whereField("geo", isLessThanOrEqualTo: location[1])
            
        }
        
        snaps.forEach {
            $0.getDocuments(completion: { (snapshot, err) in
                if let error = err {
                    print("Error getting documents: \(error)")
                } else {
                    
                    let model = snapshot!.documents.compactMap { snap -> LocationDetail? in
                        guard var detail = LocationDetail(dictionary: snap.data()) else {return nil}
                        let to = CLLocation(latitude: detail.latitude.toDouble() ?? 0, longitude: detail.longitude.toDouble() ?? 0)
                        let distanceInMeters = current.distance(from: to)
                        let km = Measurement(value: distanceInMeters, unit: UnitLength.meters).converted(to: .kilometers)
                        detail.distance = km.value
                        guard distance >= km.value else {return nil}
                        return detail
                    }
                    self.inrangeArr = model
                    
                }
            })
        } 
        
        
        
    }
    
}

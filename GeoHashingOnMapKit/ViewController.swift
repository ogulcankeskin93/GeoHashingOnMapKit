//
//  ViewController.swift
//  GeoHashingOnMapKit
//
//  Created by ogulcan keskin on 3.09.2019.
//  Copyright © 2019 ogulcan keskin. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    var viewModel: ViewModelReachable! {
        didSet {
            viewModel.fetchLocations()
        }
    }
    
    private let locationManager = CLLocationManager()

    @IBOutlet public var mapView: MKMapView! {
        didSet {
            mapView.showsUserLocation = true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // pretend we have nice MVVM design
        initializeVM()
        
        locationManager.requestWhenInUseAuthorization()

    }
    
    fileprivate func initializeVM() {
        let vm = ViewModel()
        viewModel = vm
    }
}

extension ViewController: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print(userLocation.coordinate)
        centerMap(on: userLocation.coordinate)
    }
    
    private func centerMap(on coordinate: CLLocationCoordinate2D) {
        let regionRadius: CLLocationDistance = 3000
        let coordinateRegion = MKCoordinateRegion(center: coordinate,
                                                  latitudinalMeters: regionRadius,
                                                  longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
}


protocol ViewModelReachable {
    func fetchLocations()
}


struct Episode: Codable {
    let id: String
    let title: String
}

class ViewModel: ViewModelReachable {
    
    let locationService = LocationServiceImpl()
    
    func fetchLocations() {
        
        _ = locationService.fetchLocations() { result in
            switch result {
            case .success(let result):
                result.forEach{_ in
//                    print(index)
//                    print($0.id)
//                    print($0.title)
                }
            case .failure(let err):
                print(err)
            }
            
        }
    }
}

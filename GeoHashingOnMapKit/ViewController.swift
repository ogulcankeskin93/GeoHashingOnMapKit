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
            viewModel.model.bind { [weak self] _ in
                self?.addAnnotations()
            }
            
            viewModel.control.bind { [weak self] _ in
                self?.arrangeAnnotations()
            }
            
        }
    }
    
    private let locationManager = CLLocationManager()
    private let step: Float = 1
    private var sliderValue: Double!
    
    private var currentLocation: CLLocation? {
        didSet {
            viewModel.fetchLocations()
            viewModel.calculateGeoHash(coordinate: (currentLocation?.coordinate)!, distance: sliderValue)
            
        }
    }
    
    @IBOutlet public var mapView: MKMapView! {
        didSet {
            mapView.showsUserLocation = true
        }
    }
    @IBOutlet weak var slider: UISlider! {
        didSet {
            sliderValue = Double(slider.value)
            slider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
            
        }
    }
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            let value = round(slider.value / step) * step
            sliderValue = Double(value)
            distanceLabel.text = "\(value)"
            switch touchEvent.phase {
            case .ended:
                if let currentLocation = currentLocation {
                    viewModel.calculateGeoHash(coordinate: currentLocation.coordinate, distance: sliderValue)
                }
            default:
                break
            }
        }
    }
    @IBAction func distanceSlider(_ sender: UISlider) {
        
    }
    @IBOutlet weak var distanceLabel: UILabel!
    
    
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
        currentLocation = userLocation.location
        centerMap(on: userLocation.coordinate)
    }
    
    private func centerMap(on coordinate: CLLocationCoordinate2D) {
        let regionRadius: CLLocationDistance = 30000
        let coordinateRegion = MKCoordinateRegion(center: coordinate,
                                                  latitudinalMeters: regionRadius,
                                                  longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    private func addAnnotations() {
        //        if let annotions = mapView?.annotations, annotions.count > 1 {
        //            annotions.forEach {
        //                if $0 is MarkerMapViewModel {
        //                    mapView.removeAnnotation($0)
        //                }
        //            }
        //
        //        }
        for temp in viewModel.model.value {
            
            let long: Double = temp.longitude.toDouble() ?? 0
            let lat: Double = temp.latitude.toDouble() ?? 0
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let cll = CLLocation(latitude: lat, longitude: long)
            
            
            // distance
            let distanceInMeters = currentLocation!.distance(from: cll)
            let distance = Measurement(value: distanceInMeters, unit: UnitLength.meters).converted(to: .kilometers)
            
            let image = UIImage(named: "terrible")!
            
            let annotation = MarkerMapViewModel(coordinate: coordinate,
                                                name: temp.title,
                                                image: image, distance: "\(distance)")
            mapView.addAnnotation(annotation)
        }
    }
    
    public func mapView(_ mapView: MKMapView,
                        viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let viewModel = annotation as? MarkerMapViewModel else {
            return nil
        }
        
        let identifier = "marker"
        let annotationView: MKAnnotationView
        if let existingView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            annotationView = existingView
        } else {
            annotationView = MKAnnotationView(annotation: viewModel,
                                              reuseIdentifier: identifier)
        }
        annotationView.image = viewModel.image
        annotationView.canShowCallout = true
        return annotationView
    }
    
    func arrangeAnnotations() {
        
        if let annotions = mapView?.annotations, annotions.count > 1 {
            annotions.forEach {
                if let model = $0 as? MarkerMapViewModel {
                    if viewModel.control(title: model.name) {
                        if model.inRange ?? false {
                            
                        } else {
                            model.inRange = true
                            mapView.removeAnnotation($0)
                            mapView.addAnnotation(model)
                        }
                        
                    } else {
                        if model.inRange ?? false {
                            model.inRange = false
                            mapView.removeAnnotation($0)
                            mapView.addAnnotation(model)
                        }
                    }
                }
            }
        }
    }
}


extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
}

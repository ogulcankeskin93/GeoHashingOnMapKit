//
//  ViewController.swift
//  GeoHashingOnMapKit
//
//  Created by ogulcan keskin on 3.09.2019.
//  Copyright © 2019 ogulcan keskin. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import GeoFire

class ViewController: UIViewController {
    
    var viewModel: ViewModelReachable! {
        didSet {
            viewModel.model.bind { _ in
                self.addAnnotations()
            }
            
        }
    }
    
    private let locationManager = CLLocationManager()
    private let step: Float = 1
    private var sliderValue: Double! {
        didSet {
            if let currentLocation = currentLocation {

            }
        }
    }
    
    private var currentLocation: CLLocation? {
        didSet {
            viewModel.fetchLocations()
            viewModel.calculateGeoHash(latitude: (currentLocation?.coordinate.latitude)!, longitude: (currentLocation?.coordinate.longitude)!, distance: sliderValue)

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
                viewModel.calculateGeoHash(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, distance: sliderValue)
                }
                addAnnotations()
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
        if let annotions = mapView?.annotations, annotions.count > 1 {
            annotions.forEach {
                if $0 is MarkerMapViewModel {
                    mapView.removeAnnotation($0)
                }
            }
            
        }
        for temp in viewModel.model.value {
            
            let long: Double = temp.detail.longitude?.toDouble() ?? 0
            let lat: Double = temp.detail.latitude?.toDouble() ?? 0
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let cll = CLLocation(latitude: lat, longitude: long)
            
            
            // distance
            let distanceInMeters = currentLocation!.distance(from: cll)
            let distance = Measurement(value: distanceInMeters, unit: UnitLength.meters).converted(to: .kilometers)
            
            let image: UIImage
            if viewModel.control(test: temp) {
                image = UIImage(named: "great")!
            } else {
                image = UIImage(named: "terrible")!
            }
            let annotation = MarkerMapViewModel(coordinate: coordinate,
                                                name: temp.detail.title ?? "",
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
    
    
}

protocol ViewModelReachable {
    
    func fetchLocations()
    func control(test: MotherLocation) -> Bool
    func calculateGeoHash(latitude: Double, longitude: Double, distance: Double)
    var model: Bindable<[MotherLocation]> {get set}
    
}


struct LocationDetail: Codable {
    let latitude: String?
    let longitude: String?
    let title: String?
}

struct MotherLocation {
    let detail: LocationDetail
    let geo: String
    
    var dictionary: [String: Any] {
        return [
            "latitude": detail.latitude ?? "",
            "longitude": detail.longitude ?? "",
            "title": detail.title ?? "",
            "geo": geo
        ]
    }
}
extension MotherLocation {
        
        init?(dictionary: [String : Any]) {
            guard let latitude = dictionary["latitude"] as? String,
                let longitude = dictionary["longitude"] as? String,
                let title = dictionary["title"] as? String,
                let geo = dictionary["geo"] as? String

                else { return nil }
            
            let detail = LocationDetail(latitude: latitude, longitude: longitude, title: title)
            self.init(detail: detail, geo: geo)
        }
}

class ViewModel: ViewModelReachable {
    func control(test: MotherLocation) -> Bool {
        return inrangeArr.contains { $0.detail.title == test.detail.title
        }
    }
    
    
    private var lesserGeopoint: GeoPoint!
    private var greaterGeopoint: GeoPoint!
    private var inrangeArr: [MotherLocation] = []
    let locationService = LocationServiceImpl()
    var model: Bindable<[MotherLocation]> = Bindable([])
    
    func fetchLocations() {
        
        _ = locationService.fetchLocations() { result in
            switch result {
            case .success(let result):
                let mother = result.map {
                    MotherLocation(detail: $0, geo: self.returnGeoHash(latitude: $0.latitude, longitude: $0.longitude))
                }
                print("bittititititi")
                self.model.value = mother
            case .failure(let err):
                print(err)
            }
            
        }
    }
    
    func createDatas(_ arr: [MotherLocation]) {

        arr.forEach {
            Firestore.firestore().document("locations/location\($0.detail.longitude!)").setData($0.dictionary)
        }
        
    }
    
    func returnGeoHash(latitude: String?, longitude: String?) -> String {
        let long: Double = longitude?.toDouble() ?? 0
        let lat: Double = latitude?.toDouble() ?? 0
        let temp = GFGeoHash(location: CLLocationCoordinate2D(latitude: lat, longitude: long))
        return temp?.geoHashValue ?? ""
    }
    

    
    func calculateGeoHash(latitude: Double, longitude: Double, distance: Double) {
        // ~1 mile of lat and lon in degrees
        
        inrangeArr.removeAll()
        
        
        let queries = GeoHashUtil.shared.getQueriesForDocumentsAround(center: Center(latitude: latitude, longitude: longitude), radius: distance * 1000)
        let ref = Firestore.firestore().collection("locations")

        let snaps = queries.map { location in
            return ref.whereField("geo", isGreaterThanOrEqualTo: location[0]).whereField("geo", isLessThanOrEqualTo: location[1])
            
         }
        
        snaps.forEach {
            $0.getDocuments(completion: { (snapshot, err) in
                if let error = err {
                    print("Error getting documents: \(error)")
                } else {
                    for document in snapshot!.documents {
                        self.inrangeArr.append(MotherLocation(dictionary: document.data())!)
                        print("\(document.documentID) => \(document.data())")
                    }
                }
            })
        }
        
        
        
//
//        let lat = 0.0144927536231884
//        let lon = 0.0181818181818182
//
//        let lowerLat = latitude - (lat * distance)
//        let lowerLon = longitude - (lon * distance)
//
//        let greaterLat = latitude + (lat * distance)
//        let greaterLon = longitude + (lon * distance)
//
//        let lesserGeopoint = GeoPoint(latitude: lowerLat, longitude: lowerLon)
//        let greaterGeopoint = GeoPoint(latitude: greaterLat, longitude: greaterLon)
//
//        let docRef = Firestore.firestore().collection("locations")
//        let query = docRef.whereField("geo", isGreaterThan: lesserGeopoint).whereField("geo", isLessThan: greaterGeopoint)
//
//        query.getDocuments { snapshot, error in
//            if let error = error {
//                print("Error getting documents: \(error)")
//            } else {
//                self.inrangeArr.removeAll()
//                for document in snapshot!.documents {
//                    self.inrangeArr.append(MotherLocation(dictionary: document.data())!)
//                    print("\(document.documentID) => \(document.data())")
//                }
//            }
//        }
        
    }
    
}

extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
}

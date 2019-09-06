
import UIKit
import MapKit

public class MarkerMapViewModel: NSObject {
    
    // MARK: - Properties
    public let coordinate: CLLocationCoordinate2D
    public let name: String
    public var image: UIImage
    public let distance: String
    public var inRange: Bool? {
        didSet {
            if inRange! {
                image = UIImage(named: "great")!
            } else {
                image = UIImage(named: "terrible")!
            }
        }
    }
    // MARK: - Object Lifecycle
    public init(coordinate: CLLocationCoordinate2D,
                name: String,
                image: UIImage,
                distance: String) {
        self.coordinate = coordinate
        self.name = name
        self.image = image
        self.distance = distance
    }
    
    
}

// MARK: - MKAnnotation
extension MarkerMapViewModel: MKAnnotation {
    
    public var title: String? {
        return name
    }
    
    public var subtitle: String? {
        return distance
    }
    
}

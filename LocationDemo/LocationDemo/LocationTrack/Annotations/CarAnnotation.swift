//
//  CarAnnotation.swift
//  LocationDemo
//
//  Created by Denis Selivanov on 10/24/23.
//

import Foundation
import CoreLocation
import MapKit

final class CarAnnotation: NSObject, MKAnnotation {
    let title: String?
    dynamic var coordinate: CLLocationCoordinate2D {
        didSet {
            oldCoordinates = oldValue
        }
    }
    dynamic var oldCoordinates = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    dynamic var rotationAnge: CLLocationDegrees
    init(title: String, coordinate: CLLocationCoordinate2D, rotationAnge: CLLocationDegrees) {
        self.title = title
        self.coordinate = coordinate
        self.rotationAnge = rotationAnge
    }
}

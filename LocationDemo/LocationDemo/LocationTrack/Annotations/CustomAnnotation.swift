//
//  CustomAnnotation.swift
//  LocationDemo
//
//  Created by Denis Selivanov on 10/26/23.
//

import Foundation
import MapKit

final class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

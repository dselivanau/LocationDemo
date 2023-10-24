//
//  UIKitLocationController.swift
//  LocationDemo
//
//  Created by Denis Selivanov on 10/23/23.
//

import UIKit
import MapKit

class UIKitLocationController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressPickerImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var startTripButton: UIButton!
    
    var carPosition: CarPosition?
    var carAnnotationView: MKAnnotationView!
    var carAnnotation: CarAnnotation!
//    var tripPolyline: MKPolyline!
//    var oldTripPolyline: MKPolyline!
//
    var carPositionTimer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        LocationManager.shared.startTrackLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        carPositionTimer.invalidate()
    }
    
    deinit {
        print("UIKit location deinited")
        LocationManager.shared.stopTrackLocation()
    }
    
    // setVisibleMapRect - отвечает за зум нашей карты отностительно построенного роута
    func configureTripRoute(setVisibleMapRect: Bool = false) {
        // Установим дефолтную точку старта и конечной цели из LocationMock в связи с невозожностью общаться через сервер
//        guard let carLatitude = setVisibleMapRect ? 54.14834073 : carPosition?.latitude, let carLongitude = setVisibleMapRect ? 19.40817968: carPosition?.longitude else { return }
        guard let carLatitude = carPosition?.latitude, let carLongitude = carPosition?.longitude else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.73471755, longitude: -122.45290792), addressDictionary: nil))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [unowned self] response, error in
            guard let response = response else { return }
            
            for route in response.routes {
                //Remove exist routes
                let overlays = self.mapView.overlays
                self.mapView.removeOverlays(overlays)
                //Insert to the map new route
                self.mapView.addOverlay(route.polyline)
                
                if setVisibleMapRect {
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30), animated: true)
                }
            }
        }
        
        if setVisibleMapRect {
            let basePoint = CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude)
            let angle = calculateBearingAngle(fromCoordinate: basePoint, toCoordinate: basePoint)
            carAnnotation = CarAnnotation(title: "", coordinate: CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude), rotationAnge: angle.toRadians())
            mapView.addAnnotation(carAnnotation)
        } else {
            let point1 = CLLocationCoordinate2D(latitude: carAnnotation.oldCoordinates.latitude, longitude: carAnnotation.oldCoordinates.longitude)
            let point2 = CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude)
            let angle = calculateBearingAngle(fromCoordinate: point1, toCoordinate: point2)

            guard let annotation = mapView.annotations.first else { return }
            if let customAnnotationView = mapView.view(for: annotation) {
                UIView.animate(withDuration: 1, delay: 0, options: [.curveLinear]) {
                    customAnnotationView.transform = CGAffineTransform(rotationAngle: angle.toRadians())
                }
            }
            UIView.animate(withDuration: 2.5, delay: 0, options: [.curveLinear]) { [weak self] in
                self?.carAnnotation.coordinate = CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude)
            }
        }
    }

    @IBAction func startTripAction(_ sender: Any) {
        addressPickerImage.isHidden = true
        startTripButton.isHidden = true
        addressLabel.isHidden = true
        carPosition = CarPosition(latitude: LocationManager.shared.latitude, longitude: LocationManager.shared.longitude)
        configureTripRoute(setVisibleMapRect: true)
        carPositionTimer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(updateCarPosition), userInfo: nil, repeats: true)
    }
    
    @objc
    private func updateCarPosition() {
        carPosition?.latitude = LocationManager.shared.latitude
        carPosition?.longitude = LocationManager.shared.longitude
        configureTripRoute()
    }
    
    func calculateBearingAngle(fromCoordinate startCoordinate: CLLocationCoordinate2D, toCoordinate endCoordinate: CLLocationCoordinate2D) -> CLLocationDegrees {
        let lat1 = startCoordinate.latitude.toRadians()
        let lon1 = startCoordinate.longitude.toRadians()
        let lat2 = endCoordinate.latitude.toRadians()
        let lon2 = endCoordinate.longitude.toRadians()

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        let bearingRadians = atan2(y, x)
        let bearingDegrees = bearingRadians.toDegrees()

        return (bearingDegrees + 360.0).truncatingRemainder(dividingBy: 360.0)
    }
}

extension UIKitLocationController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .systemBlue
        renderer.lineWidth = 2
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "annotation")
                
        if annotation is CarAnnotation {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(describing: CarAnnotation.self))
            annotationView?.image = UIImage(resource: .car)
            annotationView?.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            carAnnotationView = annotationView
            return annotationView
        } else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        //Triggered before the map camera will change
        addressLabel.text = ""
        startTripButton.isEnabled = false
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //Triggered when the map camera changed did stop
        let location = mapView.camera.centerCoordinate
        LocationManager.shared.geocodeLocation(lattitude: location.latitude, longitude: location.longitude) { [weak self] value in
            self?.addressLabel.text = value ?? ""
            self?.startTripButton.isEnabled = value != nil
        }
    }
}

class CarAnnotation: NSObject, MKAnnotation {
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

struct CarPosition {
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
}

extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }

    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}

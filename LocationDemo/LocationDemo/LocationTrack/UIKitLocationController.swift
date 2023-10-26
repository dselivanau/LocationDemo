//
//  UIKitLocationController.swift
//  LocationDemo
//
//  Created by Denis Selivanov on 10/23/23.
//

import UIKit
import MapKit

enum TrackType {
    case foreground
    case region
}

final class UIKitLocationController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressPickerImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var startTripButton: UIButton!
    @IBOutlet weak var startRegionTrackButton: UIButton!
    
    var carPosition: AnnotationPosition?
    var carAnnotationView: MKAnnotationView!
    var carAnnotation: CarAnnotation!
//    var dogAnnotation: MKAnnotationView!
    var carPositionTimer = Timer()
    var currentRoute: MKOverlay?
    var trackType: TrackType = .foreground

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        LocationManager.shared.startTrackForegroundLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        carPositionTimer.invalidate()
    }
    
    deinit {
        print("UIKit location deinited")
        LocationManager.shared.stopTrackForegroundLocation()
    }
    
    // setVisibleMapRect - отвечает за зум нашей карты отностительно построенного роута
    private func configureTripRoute(setVisibleMapRect: Bool = false) {
        guard let carLatitude = carPosition?.latitude, let carLongitude = carPosition?.longitude else { return }
        
        // Создаем реквест по которому будем вычислять роут
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.73471755, longitude: -122.45290792), addressDictionary: nil))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        // Высчитывает всю информарцию роута по начальным и конечным координатам
        directions.calculate { [weak self] response, error in
            
            guard let self = self, let response = response else { return }
            
            for route in response.routes {
                // Удаляем существующий маршрут
                if let route = currentRoute {
                    mapView.removeOverlay(route)
                }
                
                // Накладываем новый сгенерированный маршрут на карту
                mapView.addOverlay(route.polyline)
                currentRoute = route.polyline
                
                // Если это первый рендер карты - делаем автоматический зум относительно нашего роута с отступом в 30 поинтов от краев экрана, мы хотим это сделать единожды
                // чтобы исключить зум при каждом пересчете маршрута
                if setVisibleMapRect {
                    mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30), animated: true)
                }
            }
        }
        
        if setVisibleMapRect {
            let basePoint = CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude)
            let angle = calculateBearingAngle(fromCoordinate: basePoint, toCoordinate: basePoint)
            carAnnotation = CarAnnotation(title: "", coordinate: CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude), rotationAnge: angle.toRadians())
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: 37.73471755, longitude: -122.45290792)
            // Добавляем аннотацию
            mapView.addAnnotation(annotation)
            // Добавляем аннотацию машины
            mapView.addAnnotation(carAnnotation)
            if trackType == .region {
                let regionCenter = CLLocationCoordinate2D(latitude: 37.33453849, longitude: -122.03695223)
                let regionRadius: CLLocationDistance = 150
                let regionCircle = MKCircle(center: regionCenter, radius: regionRadius)
                // Добавляем overlay для отрисовки региона
                mapView.addOverlay(regionCircle)
            }
        } else {
            let point1 = CLLocationCoordinate2D(latitude: carAnnotation.oldCoordinates.latitude, longitude: carAnnotation.oldCoordinates.longitude)
            let point2 = CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude)
            let angle = calculateBearingAngle(fromCoordinate: point1, toCoordinate: point2)

            // При каждой итерации таймера нам нужно анимировать движение машины по направлению маршрута
            // Находим аннотацию машины в коллекции аннотаций
            guard let annotation = mapView.annotations.first(where: { $0 is CarAnnotation }) else { return }
            // Находим соответстующую вью для аннотации машины, которую в дальнешем мы сможем анимировать
            if let customAnnotationView = mapView.view(for: annotation) {
                // Анимируем угол поворота относительно направления движения
                // Рекомендую поставить это значение в разы меньше(по моим наблюдениям для движения автомобиля отлично подходят значения от 1 до 2), иначе поворот угла выглядет
                // не естественным из-за плавности и большой длительности
                UIView.animate(withDuration: 1, delay: 0, options: [.curveLinear]) {
                    customAnnotationView.transform = CGAffineTransform(rotationAngle: angle.toRadians())
                }
            }
            // Анимируем движение между 2 координатами
            // Длительность анимации равна периодичности таймера, чтобы движение ощущалось плавным и постоянным
            UIView.animate(withDuration: 2.5, delay: 0, options: [.curveLinear]) { [weak self] in
                self?.carAnnotation.coordinate = CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude)
            }
            // Тип анимации для всего что связано с автомобилем рекомендую curveLinear для исключения дерганного поведения и постоянных ускорений/замедлений что, как по мне,
            // выглядит довольно не естественно
        }
    }

    @IBAction func startTripAction(_ sender: Any) {
        startTrack(.foreground)
    }
    
    @IBAction func startRegionTrackAction(_ sender: Any) {
        startTrack(.region)
        LocationManager.shared.startMonitorRegionLocation()
    }
    
    private func startTrack(_ trackType: TrackType) {
        self.trackType = trackType
        addressPickerImage.isHidden = true
        startTripButton.isHidden = true
        startRegionTrackButton.isHidden = true
        addressLabel.isHidden = true
        carPosition = AnnotationPosition(latitude: LocationManager.shared.latitude, longitude: LocationManager.shared.longitude)
        configureTripRoute(setVisibleMapRect: true)
        carPositionTimer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(updateCarPosition), userInfo: nil, repeats: true)
    }
    
    @objc
    private func updateCarPosition() {
        if carPosition?.latitude == LocationManager.shared.latitude && carPosition?.longitude == LocationManager.shared.longitude {
            return
        }
        carPosition?.latitude = LocationManager.shared.latitude
        carPosition?.longitude = LocationManager.shared.longitude
        configureTripRoute()
    }
    
    // Вычисляем угол на который нужно повернуть машину между 2 точками по пути движения
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
    
    // Определяем внешний вид добавленных overlay
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // Отрисовка круга для мониторинга региона
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.3)
            circleRenderer.strokeColor = UIColor.blue
            circleRenderer.lineWidth = 1
            return circleRenderer
        }
        
        // Соответсует нашей линии роута
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .systemBlue
        renderer.lineWidth = 2
        return renderer
    }
    
    // Отрисовываем аннотации в зависимости от их типа
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        // Устанавливаем стандартную вью для всех аннотаций
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "annotation")
        
        // Если есть кастомные аннотации - можем их найти и закастомизировать
        if annotation is CarAnnotation {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(describing: CarAnnotation.self))
            annotationView?.image = UIImage(resource: .car)
            annotationView?.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            carAnnotationView = annotationView
            return annotationView
        } else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "annotation")
            annotationView?.image = UIImage(resource: .dog1)
            annotationView?.layer.cornerRadius = (annotationView?.frame.height ?? 25) / 2
            annotationView?.layer.masksToBounds = true
            return annotationView
        }
    }
    
    // Делегат отрабатывает когда карта начинает менять свое положение
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        addressLabel.text = ""
        startTripButton.isEnabled = false
    }
    
    // Делегат отрабатывает когда камера карты останавливается
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let location = mapView.camera.centerCoordinate
        LocationManager.shared.geocodeLocation(lattitude: location.latitude, longitude: location.longitude) { [weak self] value in
            self?.addressLabel.text = value ?? ""
            self?.startTripButton.isEnabled = value != nil
        }
    }
}

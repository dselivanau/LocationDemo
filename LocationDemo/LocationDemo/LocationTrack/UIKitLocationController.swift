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
    
    var carPosition: AnnotationPosition?
    var carAnnotationView: MKAnnotationView!
    var carAnnotation: CarAnnotation!
    var carPositionTimer = Timer()
    var currentRoute: MKOverlay?
    var trackType: TrackType = .foreground
    var destination: CLLocationCoordinate2D?
    lazy var sheetController: SheetViewController = {
        let vc = SheetViewController()
        vc.sheetDelegate = self
        return vc
    }()
    
    var sheetPresentation: UISheetPresentationController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navVC = UINavigationController(rootViewController: sheetController)
        navVC.isModalInPresentation =  true
        if let sheet = navVC.sheetPresentationController {
            sheetPresentation = sheet
            sheet.preferredCornerRadius = 40
            sheet.prefersGrabberVisible = true
            changeSheetDetents(multipleSize: 0.3)
            sheet.largestUndimmedDetentIdentifier = .some(UISheetPresentationController.Detent.Identifier("test"))
        }
        navigationController?.present(navVC, animated: true)
        
        mapView.delegate = self
//        LocationManager.shared.startTrackForegroundLocation()
        mapView.showsUserTrackingButton = true
        
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: LocationManager.shared.latitude, longitude: LocationManager.shared.longitude), span: MKCoordinateSpan.init(latitudeDelta: 0.1, longitudeDelta: 0.1))
        mapView.setRegion(region, animated: true)
        
        // Если вы хотите отслежить себя на карте - можно оперировать пропертей которая закоменчена ниже
        // Однако если аннотация MKUserLocation переопределена и скрыта - изменение этого свойства ничего не даст
//        mapView.showsUserLocation = true
    }
    
    private func changeSheetDetents(multipleSize: CGFloat) {
        sheetPresentation.animateChanges {
            sheetPresentation.detents = [.custom(identifier: .some(UISheetPresentationController.Detent.Identifier("test")), resolver: { context in
                multipleSize * context.maximumDetentValue
            })]
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        carPositionTimer.invalidate()
        sheetController.dismiss(animated: true)
    }
    
    deinit {
        print("UIKit location deinited")
        LocationManager.shared.stopTrackForegroundLocation()
    }
    
    private func configureTripDetails(carLatitude: CLLocationDegrees, carLongitude: CLLocationDegrees, setVisibleMapRect: Bool = false) {
        let directions = configureDirectionByRequest(carLatitude: carLatitude, carLongitude: carLongitude)
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
                sheetController.averageTime.text = route.expectedTravelTime.asString(style: .abbreviated)
                
                // Если это первый рендер карты - делаем автоматический зум относительно нашего роута с отступом в 30 поинтов от краев экрана, мы хотим это сделать единожды
                // чтобы исключить зум при каждом пересчете маршрута
                if setVisibleMapRect {
                    mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 30, left: 30, bottom: sheetPresentation.presentedViewController.view.frame.height, right: 30), animated: true)
                }
            }
        }
    }
    
    // setVisibleMapRect - отвечает за зум нашей карты отностительно построенного роута
    private func configureTripRoute(setVisibleMapRect: Bool = false) {
        guard let carLatitude = carPosition?.latitude, let carLongitude = carPosition?.longitude else { return }
        
        configureTripDetails(carLatitude: carLatitude, carLongitude: carLongitude, setVisibleMapRect: setVisibleMapRect)
        
        if setVisibleMapRect {
            let basePoint = CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude)
            let angle = calculateBearingAngle(fromCoordinate: basePoint, toCoordinate: basePoint)
            carAnnotation = CarAnnotation(title: "", coordinate: CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude), rotationAnge: angle.toRadians())
            // Добавляем аннотацию
            mapView.addAnnotation(DogAnnotation(coordinate: CLLocationCoordinate2D(latitude: destination?.latitude ?? 0, longitude: destination?.longitude ?? 0)))
            // Добавляем аннотацию машины
            mapView.addAnnotation(carAnnotation)
            // Добавляем кастомную аннотацию для демонстрации простых глифов
            mapView.addAnnotation(CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: 37.53471755, longitude: -122.35290792)))
            if trackType == .region {
                let regionCenter = CLLocationCoordinate2D(latitude: 37.33453849, longitude: -122.03695223)
                let regionRadius: CLLocationDistance = LocationManager.shared.regionRadiusToTriggerLocationUpdate
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
                // не естественным из-за плавности и большой/малой длительности
                UIView.animate(withDuration: 1, delay: 0, options: [.curveLinear]) {
                    customAnnotationView.transform = CGAffineTransform(rotationAngle: angle.toRadians())
                }
            }
            // Анимируем движение между 2 координатами
            // Длительность анимации равна периодичности таймера, чтобы движение ощущалось плавным и постоянным
            UIView.animate(withDuration: 2.5, delay: 0, options: [.curveLinear]) {
                self.carAnnotation.coordinate = CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude)
            }
            // Тип анимации для всего что связано с автомобилем рекомендую curveLinear для исключения дерганного поведения и постоянных ускорений/замедлений что, как по мне,
            // выглядит довольно не естественно
        }
    }
    
    private func startTrack(_ trackType: TrackType) {
        mapView.removeAnnotations(mapView.annotations)
        self.trackType = trackType
        addressPickerImage.isHidden = true
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
    
    func configureDirectionByRequest(carLatitude: CLLocationDegrees, carLongitude: CLLocationDegrees) -> MKDirections {
        // Создаем реквест по которому будем вычислять роут
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destination?.latitude ?? 0, longitude: destination?.longitude ?? 0), addressDictionary: nil))
        request.transportType = .automobile
        
        return MKDirections(request: request)
    }
    
    func calculateTime() {
        let directions = configureDirectionByRequest(carLatitude: LocationManager.shared.latitude, carLongitude: LocationManager.shared.longitude)
        directions.calculate { [weak self] response, error in
            
            guard let self = self, let response = response else { return }
            
            for route in response.routes {
                sheetController.averageTime.text = route.expectedTravelTime.asString(style: .abbreviated)
            }
        }
    }
}

extension UIKitLocationController: SheetViewControllerDelegate {
    func hideDetails() {
        LocationManager.shared.stopTrackForegroundLocation()
        addressPickerImage.isHidden = false
        destination = nil
        currentRoute = nil
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        sheetController.startTrackStackView.isHidden = true
        sheetController.hideDetailsButton.isHidden = true
        carPositionTimer.invalidate()
        mapView.userTrackingMode = .none
    }
    
    func startTrack() {
        LocationManager.shared.startTrackForegroundLocation()
        startTrack(.foreground)
    }
    
    func startRegionTrack() {
        LocationManager.shared.startMonitorRegionLocation()
        startTrack(.region)
    }
    
    func calculateRoute() {
        mapView.removeAnnotations(mapView.annotations)
        carPosition = AnnotationPosition(latitude: LocationManager.shared.latitude, longitude: LocationManager.shared.longitude)
        configureTripRoute(setVisibleMapRect: true)
        sheetController.startTrackStackView.isHidden = false
        sheetController.hideDetailsButton.isHidden = false
        addressPickerImage.isHidden = true
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
        // Данный тип аннотации отвечает за текущее расположения девайса
        // Если мы включаем автоматическое следование карты за изменением положения устройства - эта аннотация будет появлятся автоматически
        // Если вы хотите включить следование карты без отображения аннотации текущего положения - можно аннотацию переопределить и скрыть ее видимость, например
        guard !(annotation is MKUserLocation) else {
            let userAnnotation = MKUserLocationView()
            userAnnotation.isHidden = true
            return userAnnotation
        }
        
        // Устанавливаем стандартную вью для всех аннотаций
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "annotation")
        
        // Если есть кастомные аннотации - можем их найти и закастомизировать
        switch annotation {
        case is CarAnnotation:
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(describing: CarAnnotation.self))
            annotationView?.image = UIImage(resource: .car)
            annotationView?.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            carAnnotationView = annotationView
            return annotationView
        case is CustomAnnotation:
            let customAnnotation = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: String(describing: CustomAnnotation.self))
            customAnnotation.glyphImage = UIImage(systemName: "dog")
            customAnnotation.selectedGlyphImage = UIImage(systemName: "tree")
            return customAnnotation
        case is DogAnnotation:
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(describing: DogAnnotation.self))
            annotationView?.image = UIImage(resource: .dog1)
            annotationView?.layer.cornerRadius = (annotationView?.frame.height ?? 25) / 2
            annotationView?.layer.masksToBounds = true
            return annotationView
        default:
            return annotationView
        }
    }
    
    // Делегат отрабатывает когда карта начинает менять свое положение
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if mapView.userTrackingMode == .none {
            if !carPositionTimer.isValid {
                sheetController.destinationAddress.text = ""
                sheetController.averageTime.text = ""
            }
            
            changeSheetDetents(multipleSize: 0.015)
        }
    }
    
    // Делегат отрабатывает когда камера карты останавливается
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let location = mapView.camera.centerCoordinate
        if !addressPickerImage.isHidden {
            destination = location
        }
        LocationManager.shared.geocodeLocation(lattitude: location.latitude, longitude: location.longitude) { [weak self] value in
            guard let self else { return }
            if !self.carPositionTimer.isValid {
                self.sheetController.destinationAddress.text = value ?? ""
            }
            if mapView.userTrackingMode == .none {
                self.changeSheetDetents(multipleSize: 0.3)
            }
            self.calculateTime()
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Selected view \(view)")
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        print("Selected annotation \(annotation)")
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("Deselected view \(view)")
    }
    
    func mapView(_ mapView: MKMapView, didDeselect annotation: MKAnnotation) {
        print("Deselected annotation \(annotation)")
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        print("Did changed track mode")
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("Location user did update from delegate")
    }
    
}



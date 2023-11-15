//
//  LocationManager.swift
//  LocationDemo
//
//  Created by Denis Selivanov on 10/23/23.
//

import Foundation
import CoreLocation
import UIKit

final class LocationManager: NSObject {
    static let shared = LocationManager()
        
    private let locationManager = CLLocationManager()
    // Минимальный пройденный путь от предыдущей точки при котором сервис будет обновлять текущую локацию
    let regionRadiusToTriggerLocationUpdate = CLLocationDistance(150)
    private let driverLocationRegionKey = "car_location"

    // Дефолтные значения начальных координат пользователя для демо
    private(set) var latitude = 37.33521504
    private(set) var longitude = -122.03254905
    private let geocoder = CLGeocoder()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        //Важный момент если мы хотим продолжать отслеживать локацию при сворачивании приложения
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appTerminated),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }
    
    func checkMonitor() {
        //
    }
    
    func startTrackForegroundLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopTrackForegroundLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    private func stopLocationTrack() {
        stopTrackForegroundLocation()
    }
    
    func geocodeLocation(lattitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: lattitude, longitude: longitude)
        return geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            guard let placemark = placemarks?.first else { completion(""); return }
            completion(placemark.name)
        })
    }
    
    @objc
    private func appTerminated() {
        startMonitorRegionLocation()
    }
    
    func startMonitorRegionLocation() {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            // Трэк регионов не доступен на устройстве
            print("Geofencing is not supported on this device")
            return
        }
        
        guard locationManager.authorizationStatus == .authorizedAlways else {
            // Недостаточно пермишенов. Трэк региона доступен только для Always пермишена
            print("Wrong location permissions. To share you location in background, please, turn on \"Always\" access")
            return
        }
        locationManager.startUpdatingLocation()
        // Минимальное значение в метрах, при которых треггерятся методы отслеживания регионов
        locationManager.distanceFilter = regionRadiusToTriggerLocationUpdate
        let activeGeofenceRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 37.33453849, longitude: -122.03695223),
                                                    radius: regionRadiusToTriggerLocationUpdate,
                                                    identifier: driverLocationRegionKey)
        
        // Позволять отслежить вход в наблюдаемый регион
        activeGeofenceRegion.notifyOnEntry = true
        // Позволять отслежить выход из наблюдаемого региона
        activeGeofenceRegion.notifyOnExit = true
        locationManager.startMonitoring(for: activeGeofenceRegion)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            print("Not determined")
        case .restricted:
            print("Restricted")
        case .denied:
            print("User selected option Don't Allow")
        case .authorizedAlways:
            print("Geofencing feature available")
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        default:
            print("default")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        
        print("Current device location from update delegate method: (\(latitude), \(longitude))")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sendNotification("Region track delegate", "Did enter region", 5)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        sendNotification("Region track delegate", "Did exit region", 5)
        // Если после прохождения наблюдаемого региона он больше не нужен - удалите его из коллекции регионов
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        guard let region = region else {
            print("The region could not be monitored, and the reason for the failure is not known.")
            return
        }
        
        print("There was a failure in monitoring the region with a identifier: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location: \(error.localizedDescription)")
    }
        
    private func sendNotification(_ title: String, _ body: String, _ interval: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "myNotification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

//
//  LocationManager.swift
//  LocationDemo
//
//  Created by Denis Selivanov on 10/23/23.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject {
    static let shared = LocationManager()
        
    private let locationManager = CLLocationManager()
//    private let regionRadiusToTriggerLocationUpdate = CLLocationDistance(300)
//    private let activeLocationMonitorKey = "activeLocationMonitor"
//    private let driverLocationRegionKey = "driver_location"
//    private let minuteDistanceBetweenStartEndTrip = 10

//    private var currentTripTimer = Timer()
    private(set) var latitude = 0.0
    private(set) var longitude = 0.0
    private let geocoder = CLGeocoder()
//    private var activeGeofenceRegion: CLRegion?
//    private var currentTrip: LocationMonitorModel?
//    var apnsTripAgreementId: String?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        //Важный момент если мы хотим продолжать отслеживать локацию при сворачивании приложения
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(appTerminated),
//                                               name: UIApplication.willTerminateNotification,
//                                               object: nil)
    }
    
    func startTrackLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopTrackLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func geocodeLocation(lattitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: lattitude, longitude: longitude)
        return geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            print(placemarks)
            guard let placemark = placemarks?.first else { completion(""); return }
            completion(placemark.name)
//            return placemark.name
//            for placemark in placemarks! {
//                
//                print("Name: \(placemark.name ?? "Empty")")
//                print("Country: \(placemark.country ?? "Empty")")
//                print("ISOcountryCode: \(placemark.isoCountryCode ?? "Empty")")
//                print("administrativeArea: \(placemark.administrativeArea ?? "Empty")")
//                print("subAdministrativeArea: \(placemark.subAdministrativeArea ?? "Empty")")
//                print("Locality: \(placemark.locality ?? "Empty")")
//                print("PostalCode: \(placemark.postalCode ?? "Empty")")
//                print("areaOfInterest: \(placemark.areasOfInterest ?? ["Empty"])")
//                print("Ocean: \(placemark.ocean ?? "Empty")")
//                
//                // Change the title and subtitle of pin.
//                self._pin.title = "\(placemark.country ?? "Empty")"
//                self._pin.subtitle = "\(placemark.name ?? "Empty")"
//            }
        })
    }
    
//    func startTrackCurrentPosition() {
//        locationManager.startUpdatingLocation()
//    }
//        
//    @objc
//    private func appTerminated() {
//        if currentTrip == nil { return }
//        startMonitorRegionLocation()
//    }
    
//    func checkActiveMonitor() {
//        currentTrip = UserDefaultManager.getCodableObject(key: activeLocationMonitorKey)
//        guard let currentTrip = currentTrip, isActiveLocationTrackValid(activeTrip: currentTrip) else { return }
//        
//        startMonitorForegroundLocation()
//    }
    
//    func prepareActiveAgreementToMonitor() {
//        guard let userId = UserSettings.shared.userId, let apnsTripAgreementId = apnsTripAgreementId else { return }
//        ApiNetworkManager.shared.api_GetSingleDayCarpoolAgreement(requesterId: userId, agreementId: apnsTripAgreementId, showLoader: false) { [unowned self] result in
//            switch result {
//            case .success(let trip):
//                guard userId == trip.participants?.first(where: { $0.driver ?? false })?.person?.id else {
//                    self.apnsTripAgreementId = nil
//                    return
//                }
//                self.startMonitorLocation(currentTrip: trip)
//            case .failure(_):
//                self.stopLocationTrack()
//            }
//        }
//    }
    
//    func startMonitorLocation(currentTrip: ClassCreateSingleDayAgreement) {
//        //To be sure if to become one more unexpected track request - existing track will be stopped
//        stopLocationTrack()
//        
//        guard let person = currentTrip.participants?.first,
//              let morningTrip = person.homeWorkTrip?.arrivalTimeWindow,
//              let morningStringStartDate = morningTrip.start,
//              let morningStringEndDate = morningTrip.end,
//              let morningStartDate = convertStringToDateWithinCurrentDay(date: morningStringStartDate)?.adding(minutes: -minuteDistanceBetweenStartEndTrip),
//              let morningEndDate = convertStringToDateWithinCurrentDay(date: morningStringEndDate),
//              let tripTypeIdentifier: AgreementTripType = Date().isBetween(morningStartDate, morningEndDate) ? .hw : .wh,
//              let expireDate = tripTypeIdentifier == .hw ? morningEndDate.adding(minutes: minuteDistanceBetweenStartEndTrip) : convertStringToDateWithinCurrentDay(date: person.workHomeTrip?.departureTimeWindow?.end ?? "")
//        else { return }
//                
//        guard let agreementId = currentTrip.id else { return }
//        let monitorModel = LocationMonitorModel(agreementId: agreementId, tripType: tripTypeIdentifier, expireDate: expireDate)
//        self.currentTrip = monitorModel
//        UserDefaultManager.setCodableObject(object: monitorModel, key: activeLocationMonitorKey)
//        startMonitorForegroundLocation()
//    }
    
//    private func convertStringToDateWithinCurrentDay(date: String) -> Date? {
//        return date.toDateWithinCurrentDay(dateFormat: "HH:mm:ss")
//    }
    
//    func startMonitorForegroundLocation() {
//        stopMonitorRegionLocation()
//        locationManager.startUpdatingLocation()
//        currentTripTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(foregroundLocationRequestTimer), userInfo: nil, repeats: true)
//        currentTripTimer.tolerance = 5
//    }
//    
//    @objc
//    private func foregroundLocationRequestTimer() {
//        sendCurrentLocationToServer()
//    }
//    
//    func startMonitorRegionLocation() {
//        stopMonitorForegroundLocation()
//        locationManager.showsBackgroundLocationIndicator = false
//        
//        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
//            UM.showMessageNew("Geofencing is not supported on this device")
//            return
//        }
//        
//        guard locationManager.authorizationStatus == .authorizedAlways else {
//            UM.showMessageNew("Wrong location permissions. To share you location in background, please, turn on \"Always\" access")
//            return
//        }
//        
//        //TODO: There is possible to get wrong accurancy of location because of range. Have to check with real tests
//        locationManager.distanceFilter = regionRadiusToTriggerLocationUpdate
//        prepareAndStartTrackRegion(latitude: latitude, longitude: longitude)
//    }
//    
//    private func prepareAndStartTrackRegion(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
//        let regionCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//        activeGeofenceRegion = CLCircularRegion(center: regionCoordinate,
//                                                radius: regionRadiusToTriggerLocationUpdate,
//                                                identifier: driverLocationRegionKey)
//        
//        activeGeofenceRegion?.notifyOnExit = true
//        guard let region = activeGeofenceRegion else { return }
//        locationManager.startMonitoring(for: region)
//    }
//    
//    func stopLocationTrack() {
//        locationManager.stopUpdatingLocation()
//        stopMonitorRegionLocation()
//        stopMonitorForegroundLocation()
//        currentTrip = nil
//        apnsTripAgreementId = nil
//        UserDefaultManager.removeCustomObject(key: activeLocationMonitorKey)
//    }
//    
//    private func stopMonitorRegionLocation() {
//        if let region = activeGeofenceRegion {
//            locationManager.stopMonitoring(for: region)
//            activeGeofenceRegion = nil
//        }
//    }
//    
//    private func stopMonitorForegroundLocation() {
//        currentTripTimer.invalidate()
//    }
//    
//    func sendCurrentLocationToServer() {
//        guard let activeTrip = currentTrip, let userId = UserSettings.shared.userId, isActiveLocationTrackValid(activeTrip: activeTrip) else {
//            stopLocationTrack()
//            return
//        }
//        
//        let urlParam: Parameters = [
//            "agreementId": activeTrip.agreementId,
//            "tripType": activeTrip.tripType.rawValue
//        ]
//        
//        var parame: Parameters = [:]
//        if self.latitude != 0.0 && self.longitude != 0.0 {
//            parame = [
//                "lat": self.latitude,
//                "lon": self.longitude
//            ]
//        }
//                
//        ApiNetworkManager.shared.api_POSTSendCurrentPosition(accountId: userId, urlParam: urlParam, param: parame, showLoader: false) { result in
//            switch result {
//            case .success(_):
//                print("Current location updated on the server")
//            case .failure(let error):
//                UM.showMessage(error.localizedDescription)
//            }
//        }
//    }
//    
//    private func isActiveLocationTrackValid(activeTrip: LocationMonitorModel) -> Bool {
//        guard UserSettings.shared.userId != nil,
//              activeTrip.expireDate.timeIntervalSinceReferenceDate > Date.now.timeIntervalSinceReferenceDate else { return false }
//        return true
//    }
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
        
        print("Current location from update delegate method: (\(latitude), \(longitude))")
    }
        
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
//        locationManager.stopMonitoring(for: region)
//        
//        guard let location = manager.location else {
//            stopLocationTrack()
//            return
//        }
//        
//        latitude = location.coordinate.latitude
//        longitude = location.coordinate.longitude
//        prepareAndStartTrackRegion(latitude: latitude, longitude: longitude)
//        
//        currentTrip = UserDefaultManager.getCodableObject(key: activeLocationMonitorKey)
//        sendCurrentLocationToServer()
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
}
//+54.14834073,+19.40817968 start
//+54.39860391,+18.66260182 destination

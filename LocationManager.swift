// LocationManager.swift
// Quản lý GPS và theo dõi vị trí người dùng

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var heading: CLHeading?
    @Published var isUpdatingLocation = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5  // Update mỗi 5 mét
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // Yêu cầu quyền truy cập location
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Bắt đầu theo dõi vị trí
    func startUpdating() {
        guard authorizationStatus == .authorizedWhenInUse || 
              authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        isUpdatingLocation = true
        print("📍 Started location updates")
    }
    
    // Dừng theo dõi
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        isUpdatingLocation = false
        print("📍 Stopped location updates")
    }
    
    // Tính khoảng cách đến điểm
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: target)
    }
    
    // Tính bearing (góc hướng) đến điểm
    func bearing(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let current = currentLocation else { return nil }
        
        let lat1 = current.coordinate.latitude * .pi / 180
        let lon1 = current.coordinate.longitude * .pi / 180
        let lat2 = coordinate.latitude * .pi / 180
        let lon2 = coordinate.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi
        
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("📍 Authorization: \(authorizationStatus.rawValue)")
        
        if authorizationStatus == .authorizedWhenInUse || 
           authorizationStatus == .authorizedAlways {
            startUpdating()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, 
                        didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        print("📍 Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("   Speed: \(location.speed * 3.6) km/h")
        print("   Accuracy: \(location.horizontalAccuracy)m")
    }
    
    func locationManager(_ manager: CLLocationManager, 
                        didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, 
                        didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
    }
}

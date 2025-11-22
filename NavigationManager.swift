// NavigationManager.swift
// Quản lý tính toán route và gửi instructions qua BLE

import Foundation
import MapKit
import CoreLocation
import Combine

class NavigationManager: ObservableObject {
    @Published var isNavigating = false
    @Published var currentStepIndex = 0
    @Published var steps: [RouteStep] = []
    @Published var nextInstruction: String = ""
    @Published var distanceToNextStep: CLLocationDistance = 0
    @Published var estimatedArrival: Date?
    
    private var route: MKRoute?
    private var updateTimer: Timer?
    private let locationManager: LocationManager
    private let bleManager: BLEManager
    
    private let stepProximityThreshold: CLLocationDistance = 30  // 30m trước step thì chuyển
    
    init(locationManager: LocationManager, bleManager: BLEManager) {
        self.locationManager = locationManager
        self.bleManager = bleManager
    }
    
    // Tính toán route từ vị trí hiện tại đến đích
    func calculateRoute(to destination: String) async throws {
        // Parse destination
        let destinationCoordinate = try await geocode(address: destination)
        
        guard let currentLocation = locationManager.currentLocation else {
            throw NSError(domain: "NavigationManager", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Không có vị trí hiện tại"])
        }
        
        // Create request
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(
            coordinate: currentLocation.coordinate
        ))
        request.destination = MKMapItem(placemark: MKPlacemark(
            coordinate: destinationCoordinate
        ))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        // Calculate
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw NSError(domain: "NavigationManager", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy đường đi"])
        }
        
        self.route = route
        parseSteps(from: route)
        
        print("🗺️ Route calculated:")
        print("   Distance: \(route.distance/1000) km")
        print("   Duration: \(route.expectedTravelTime/60) minutes")
        print("   Steps: \(steps.count)")
    }
    
    // Chuyển đổi địa chỉ sang tọa độ
    private func geocode(address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        
        guard let coordinate = placemarks.first?.location?.coordinate else {
            throw NSError(domain: "NavigationManager", code: 3,
                         userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy địa chỉ"])
        }
        
        return coordinate
    }
    
    // Parse route steps từ MapKit
    private func parseSteps(from route: MKRoute) {
        steps = route.steps.compactMap { step -> RouteStep? in
            // Bỏ qua step "Start" và các step không có chỉ dẫn
            guard !step.instructions.isEmpty,
                  step.instructions.lowercased() != "start" else {
                return nil
            }
            
            let direction = NavigationDirection.from(instruction: step.instructions)
            
            return RouteStep(
                instruction: step.instructions,
                distance: step.distance,
                location: step.polyline.coordinate,
                direction: direction
            )
        }
        
        currentStepIndex = 0
        updateNextInstruction()
    }
    
    // Bắt đầu navigation
    func startNavigation() {
        guard !steps.isEmpty else { return }
        
        isNavigating = true
        currentStepIndex = 0
        updateNextInstruction()
        
        // Update mỗi 2 giây
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateNavigation()
        }
        
        print("🚗 Navigation started")
    }
    
    // Dừng navigation
    func stopNavigation() {
        isNavigating = false
        updateTimer?.invalidate()
        updateTimer = nil
        currentStepIndex = 0
        steps.removeAll()
        print("🚗 Navigation stopped")
    }
    
    // Update navigation state và gửi qua BLE
    private func updateNavigation() {
        guard isNavigating,
              currentStepIndex < steps.count,
              let currentLocation = locationManager.currentLocation else {
            return
        }
        
        let currentStep = steps[currentStepIndex]
        
        // Tính khoảng cách đến step tiếp theo
        let stepLocation = CLLocation(
            latitude: currentStep.location.latitude,
            longitude: currentStep.location.longitude
        )
        distanceToNextStep = currentLocation.distance(from: stepLocation)
        
        // Nếu gần step tiếp theo, chuyển sang step sau
        if distanceToNextStep < stepProximityThreshold && currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
            updateNextInstruction()
            print("➡️ Moving to step \(currentStepIndex + 1)/\(steps.count)")
        }
        
        // Tạo navigation data
        let speed = max(0, currentLocation.speed * 3.6)  // m/s -> km/h
        let message = formatInstruction(step: currentStep)
        
        let navData = NavigationData(
            speed: UInt8(min(255, max(0, speed))),
            direction: currentStep.direction,
            message: message
        )
        
        // Gửi qua BLE
        bleManager.sendNavigationData(navData)
        
        // Kiểm tra đã đến đích chưa
        if currentStepIndex == steps.count - 1 && distanceToNextStep < 20 {
            print("🎯 Arrived at destination!")
            stopNavigation()
        }
    }
    
    // Format instruction với khoảng cách
    private func formatInstruction(step: RouteStep) -> String {
        if distanceToNextStep < 100 {
            return step.instruction
        } else if distanceToNextStep < 1000 {
            return "Sau \(Int(distanceToNextStep))m, \(step.instruction.lowercased())"
        } else {
            let km = String(format: "%.1f", distanceToNextStep / 1000)
            return "Sau \(km)km, \(step.instruction.lowercased())"
        }
    }
    
    // Update next instruction text cho UI
    private func updateNextInstruction() {
        guard currentStepIndex < steps.count else {
            nextInstruction = "Đã đến đích"
            return
        }
        
        let step = steps[currentStepIndex]
        nextInstruction = "\(step.direction.displayName)\n\(step.instruction)"
    }
}

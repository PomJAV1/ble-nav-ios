// NavigationData.swift
// Model dữ liệu navigation để gửi qua BLE

import Foundation
import CoreLocation

struct NavigationData {
    let speed: UInt8           // Tốc độ km/h (0-255)
    let direction: NavigationDirection
    let message: String        // Chỉ dẫn văn bản
    
    // Chuyển đổi sang byte array theo Sygic protocol
    func toByteArray() -> [UInt8] {
        var data = [UInt8]()
        
        // Byte 0: Message type (0x01 = navigation instruction)
        data.append(0x01)
        
        // Byte 1: Speed
        data.append(speed)
        
        // Byte 2: Direction icon
        data.append(direction.rawValue)
        
        // Convert message to UTF-8
        let messageBytes = [UInt8](message.utf8)
        
        // Byte 3: Message length
        data.append(UInt8(messageBytes.count))
        
        // Byte 4+: Message content
        data.append(contentsOf: messageBytes)
        
        return data
    }
    
    // Tạo từ location và instruction
    static func from(location: CLLocation, instruction: String, direction: NavigationDirection) -> NavigationData {
        // Chuyển m/s sang km/h
        let speedKmh = max(0, min(255, Int(location.speed * 3.6)))
        
        return NavigationData(
            speed: UInt8(speedKmh),
            direction: direction,
            message: instruction
        )
    }
}

// Model cho route step
struct RouteStep {
    let instruction: String
    let distance: CLLocationDistance  // meters
    let location: CLLocationCoordinate2D
    let direction: NavigationDirection
    
    var distanceText: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

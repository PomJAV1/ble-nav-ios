// NavigationDirection.swift
// Định nghĩa các hướng chỉ dẫn tương ứng với Font Awesome icons trên ESP32

import Foundation
import MapKit

enum NavigationDirection: UInt8 {
    case straight = 0
    case slightRight = 1
    case right = 2
    case sharpRight = 3
    case uTurnRight = 4
    case uTurnLeft = 5
    case sharpLeft = 6
    case left = 7
    case slightLeft = 8
    case keepRight = 9
    case keepLeft = 10
    case rampRight = 11
    case rampLeft = 12
    case forkRight = 13
    case forkLeft = 14
    case merge = 15
    
    // Chuyển đổi từ MapKit instructions sang direction code
    static func from(instruction: String) -> NavigationDirection {
        let lower = instruction.lowercased()
        
        // U-turn
        if lower.contains("u-turn") || lower.contains("u turn") {
            if lower.contains("right") {
                return .uTurnRight
            } else {
                return .uTurnLeft
            }
        }
        
        // Sharp turns
        if lower.contains("sharp") {
            if lower.contains("right") {
                return .sharpRight
            } else if lower.contains("left") {
                return .sharpLeft
            }
        }
        
        // Slight turns
        if lower.contains("slight") {
            if lower.contains("right") {
                return .slightRight
            } else if lower.contains("left") {
                return .slightLeft
            }
        }
        
        // Regular turns
        if lower.contains("turn") {
            if lower.contains("right") {
                return .right
            } else if lower.contains("left") {
                return .left
            }
        }
        
        // Ramps
        if lower.contains("ramp") {
            if lower.contains("right") {
                return .rampRight
            } else if lower.contains("left") {
                return .rampLeft
            }
        }
        
        // Forks
        if lower.contains("fork") {
            if lower.contains("right") {
                return .forkRight
            } else if lower.contains("left") {
                return .forkLeft
            }
        }
        
        // Keep
        if lower.contains("keep") {
            if lower.contains("right") {
                return .keepRight
            } else if lower.contains("left") {
                return .keepLeft
            }
        }
        
        // Merge
        if lower.contains("merge") {
            return .merge
        }
        
        // Default
        return .straight
    }
    
    // Lấy tên hiển thị
    var displayName: String {
        switch self {
        case .straight: return "Đi thẳng"
        case .slightRight: return "Rẽ nhẹ phải"
        case .right: return "Rẽ phải"
        case .sharpRight: return "Rẽ gắt phải"
        case .uTurnRight: return "Quay đầu phải"
        case .uTurnLeft: return "Quay đầu trái"
        case .sharpLeft: return "Rẽ gắt trái"
        case .left: return "Rẽ trái"
        case .slightLeft: return "Rẽ nhẹ trái"
        case .keepRight: return "Giữ phải"
        case .keepLeft: return "Giữ trái"
        case .rampRight: return "Rẽ dốc phải"
        case .rampLeft: return "Rẽ dốc trái"
        case .forkRight: return "Ngã ba phải"
        case .forkLeft: return "Ngã ba trái"
        case .merge: return "Nhập làn"
        }
    }
}

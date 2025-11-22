// BLEManager.swift
// Quản lý kết nối BLE và gửi dữ liệu đến ESP32

import Foundation
import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject {
    // UUIDs theo Sygic protocol
    private let serviceUUID = CBUUID(string: "FFE0")
    private let characteristicUUID = CBUUID(string: "FFE1")
    
    // CoreBluetooth objects
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [CBPeripheral] = []
    private var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    
    // Published properties cho UI
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var devices: [String] = []
    @Published var statusMessage = "Chưa kết nối"
    @Published var lastSentData: String = ""
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Scan thiết bị BLE
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            statusMessage = "Bluetooth chưa bật"
            return
        }
        
        discoveredPeripherals.removeAll()
        devices.removeAll()
        isScanning = true
        statusMessage = "Đang tìm kiếm..."
        
        // Scan với service UUID để nhanh hơn
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        // Tự động dừng sau 10 giây
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopScanning()
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        if !isConnected {
            statusMessage = "Tìm thấy \(devices.count) thiết bị"
        }
    }
    
    // Kết nối đến thiết bị theo tên
    func connect(deviceName: String) {
        guard let peripheral = discoveredPeripherals.first(where: { $0.name == deviceName }) else {
            statusMessage = "Không tìm thấy \(deviceName)"
            return
        }
        
        statusMessage = "Đang kết nối..."
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    // Ngắt kết nối
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // Gửi dữ liệu navigation
    func sendNavigationData(_ data: NavigationData) {
        guard let peripheral = connectedPeripheral,
              let characteristic = targetCharacteristic else {
            statusMessage = "Chưa kết nối"
            return
        }
        
        let bytes = data.toByteArray()
        let bleData = Data(bytes)
        
        peripheral.writeValue(
            bleData,
            for: characteristic,
            type: .withoutResponse  // Nhanh hơn, không chờ ACK
        )
        
        // Update UI
        lastSentData = "\(data.direction.displayName) - \(data.speed)km/h - \(data.message)"
        print("📤 Sent: \(bytes.map { String(format: "%02X", $0) }.joined(separator: " "))")
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth đã sẵn sàng"
        case .poweredOff:
            statusMessage = "Bluetooth đã tắt"
        case .unauthorized:
            statusMessage = "Chưa cấp quyền Bluetooth"
        case .unsupported:
            statusMessage = "Thiết bị không hỗ trợ BLE"
        default:
            statusMessage = "Bluetooth chưa sẵn sàng"
        }
    }
    
    func centralManager(_ central: CBCentralManager, 
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any], 
                       rssi RSSI: NSNumber) {
        // Chỉ thêm thiết bị có tên
        guard let name = peripheral.name, !name.isEmpty else { return }
        
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            devices.append(name)
            print("🔍 Found: \(name) (RSSI: \(RSSI))")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusMessage = "Đã kết nối \(peripheral.name ?? "unknown")"
        isConnected = true
        print("✅ Connected to \(peripheral.name ?? "unknown")")
        
        // Discover services
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, 
                       didDisconnectPeripheral peripheral: CBPeripheral, 
                       error: Error?) {
        statusMessage = "Đã ngắt kết nối"
        isConnected = false
        connectedPeripheral = nil
        targetCharacteristic = nil
        print("❌ Disconnected")
    }
    
    func centralManager(_ central: CBCentralManager,
                       didFailToConnect peripheral: CBPeripheral,
                       error: Error?) {
        statusMessage = "Kết nối thất bại"
        print("❌ Connection failed: \(error?.localizedDescription ?? "unknown")")
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services where service.uuid == serviceUUID {
            print("📡 Found service: \(service.uuid)")
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                   didDiscoverCharacteristicsFor service: CBService,
                   error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics where characteristic.uuid == characteristicUUID {
            targetCharacteristic = characteristic
            statusMessage = "Sẵn sàng gửi dữ liệu"
            print("✅ Found characteristic: \(characteristic.uuid)")
            print("   Properties: \(characteristic.properties)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                   didWriteValueFor characteristic: CBCharacteristic,
                   error: Error?) {
        if let error = error {
            print("❌ Write error: \(error.localizedDescription)")
        }
    }
}

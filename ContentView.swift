// ContentView.swift
// Main UI của app

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var navigationManager: NavigationManager
    
    @State private var destination = ""
    @State private var isCalculating = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    init() {
        let bleManager = BLEManager()
        let locationManager = LocationManager()
        let navigationManager = NavigationManager(
            locationManager: locationManager,
            bleManager: bleManager
        )
        
        _bleManager = StateObject(wrappedValue: bleManager)
        _locationManager = StateObject(wrappedValue: locationManager)
        _navigationManager = StateObject(wrappedValue: navigationManager)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // BLE Connection Section
                    bleConnectionSection
                    
                    Divider()
                    
                    // Location Section
                    locationSection
                    
                    Divider()
                    
                    // Navigation Section
                    navigationSection
                    
                    if navigationManager.isNavigating {
                        Divider()
                        navigationStatusSection
                    }
                }
                .padding()
            }
            .navigationTitle("BLE Navigation")
            .alert("Lỗi", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                locationManager.requestPermission()
            }
        }
    }
    
    // MARK: - BLE Connection Section
    private var bleConnectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BLE Connection")
                .font(.headline)
            
            Text(bleManager.statusMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: {
                    if bleManager.isScanning {
                        bleManager.stopScanning()
                    } else {
                        bleManager.startScanning()
                    }
                }) {
                    Label(
                        bleManager.isScanning ? "Dừng tìm kiếm" : "Tìm thiết bị",
                        systemImage: bleManager.isScanning ? "stop.circle" : "magnifyingglass"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(bleManager.isConnected)
                
                if bleManager.isConnected {
                    Button(action: { bleManager.disconnect() }) {
                        Label("Ngắt kết nối", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if !bleManager.devices.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Thiết bị tìm thấy:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(bleManager.devices, id: \.self) { device in
                        Button(action: { bleManager.connect(deviceName: device) }) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text(device)
                                Spacer()
                                if bleManager.isConnected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .disabled(bleManager.isConnected)
                    }
                }
            }
            
            if !bleManager.lastSentData.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dữ liệu đã gửi:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(bleManager.lastSentData)
                        .font(.caption)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GPS Location")
                .font(.headline)
            
            if let location = locationManager.currentLocation {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text(String(format: "%.6f, %.6f", 
                                  location.coordinate.latitude,
                                  location.coordinate.longitude))
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    HStack {
                        Image(systemName: "speedometer")
                        Text(String(format: "%.1f km/h", location.speed * 3.6))
                    }
                    .font(.subheadline)
                    
                    HStack {
                        Image(systemName: "scope")
                        Text(String(format: "Accuracy: ±%.0fm", location.horizontalAccuracy))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } else {
                Text("Đang chờ GPS...")
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                if locationManager.isUpdatingLocation {
                    locationManager.stopUpdating()
                } else {
                    locationManager.startUpdating()
                }
            }) {
                Label(
                    locationManager.isUpdatingLocation ? "Tắt GPS" : "Bật GPS",
                    systemImage: locationManager.isUpdatingLocation ? "location.fill" : "location"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Navigation Section
    private var navigationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Navigation")
                .font(.headline)
            
            TextField("Nhập địa chỉ đích (ví dụ: Tokyo Tower)", text: $destination)
                .textFieldStyle(.roundedBorder)
                .disabled(navigationManager.isNavigating)
            
            HStack {
                Button(action: calculateRoute) {
                    if isCalculating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Tính đường", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(destination.isEmpty || 
                         navigationManager.isNavigating ||
                         isCalculating ||
                         !bleManager.isConnected)
                
                if !navigationManager.steps.isEmpty && !navigationManager.isNavigating {
                    Button(action: { navigationManager.startNavigation() }) {
                        Label("Bắt đầu", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                
                if navigationManager.isNavigating {
                    Button(action: { navigationManager.stopNavigation() }) {
                        Label("Dừng", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            
            if !bleManager.isConnected {
                Text("⚠️ Cần kết nối BLE trước")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Navigation Status Section
    private var navigationStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Đang dẫn đường")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Bước \(navigationManager.currentStepIndex + 1) / \(navigationManager.steps.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(navigationManager.nextInstruction)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if navigationManager.distanceToNextStep > 0 {
                    HStack {
                        Image(systemName: "arrow.right")
                        Text(String(format: "Còn %.0fm", navigationManager.distanceToNextStep))
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            // Route steps preview
            if !navigationManager.steps.isEmpty {
                Divider()
                
                Text("Các bước tiếp theo:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(navigationManager.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(index == navigationManager.currentStepIndex ? Color.blue : Color.gray)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.instruction)
                                        .font(.subheadline)
                                    Text(step.distanceText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .opacity(index < navigationManager.currentStepIndex ? 0.5 : 1.0)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    private func calculateRoute() {
        guard !destination.isEmpty else { return }
        
        isCalculating = true
        
        Task {
            do {
                try await navigationManager.calculateRoute(to: destination)
                isCalculating = false
            } catch {
                errorMessage = "Không tìm thấy đường: \(error.localizedDescription)"
                showError = true
                isCalculating = false
            }
        }
    }
}

#Preview {
    ContentView()
}

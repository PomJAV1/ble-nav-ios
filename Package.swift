// swift-tools-version: 6.2
# Build iOS App với GitHub Actions - Hoàn toàn MIỄN PHÍ

## Tổng quan

GitHub Actions cung cấp macOS runner miễn phí:
- ✅ **2,000 phút/tháng** cho public repository (đủ dùng)
- ✅ **500 MB storage** cho artifacts
- ✅ Xcode đầy đủ, có thể build iOS app
- ✅ Không cần credit card

---

## BƯỚC 1: Chuẩn bị code

### 1.1. Tạo cấu trúc project Swift Package

Tạo file `Package.swift`:

```bash
cd c:\Espressif\frameworks\esp-idf-v5.4.2\examples\xiaozhi-esp32-main\docs\ios-ble-navigation-app
```

Tạo các file sau:

<function_calls>
<invoke name="create_file">
<parameter name="content">// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BLENavigationApp",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "BLENavigationApp",
            targets: ["BLENavigationApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BLENavigationApp",
            dependencies: [],
            path: "Sources"
        )
    ]
)


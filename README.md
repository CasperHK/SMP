# SMP – Swift Multiplatform Core

A cross-platform Swift App Framework that shares business logic between **iOS** and **Android** using Swift 6 strict concurrency, `Codable` data models, and the `Observation` framework.

---

## Architecture

```
SMP/
├── Package.swift                   ← SPM manifest (Swift 6.0 tools)
├── Sources/
│   ├── Shared/                     ← Pure Swift – zero platform APIs
│   │   ├── SMPError.swift
│   │   ├── Models/
│   │   │   └── APIModels.swift     ← Codable data models
│   │   ├── Network/
│   │   │   └── NetworkClient.swift ← async/await HTTP client
│   │   └── Auth/
│   │       └── AuthManager.swift   ← @Observable auth state machine
│   ├── iOSAdapter/
│   │   └── iOSPlatformAdapter.swift ← UIKit bootstrap & LocalizedError
│   └── AndroidAdapter/
│       ├── include/
│       │   └── smp_bridge.h        ← Public C-bridge header (JNI surface)
│       └── AndroidBridge.swift     ← @_cdecl C entry-points
├── android/
│   └── app/
│       ├── build.gradle.kts        ← Gradle config with Swift SDK plugin
│       └── src/main/kotlin/com/example/smp/
│           └── SMPBridge.kt        ← Kotlin JNI wrapper + coroutine helpers
└── Tests/
    └── SharedTests/
        └── SharedTests.swift       ← XCTest suite for Shared layer
```

---

## Core Technology Stack

| Concern | Technology |
|---|---|
| Asynchronous tasks | Swift 6 `async`/`await` + Strict Concurrency |
| Data models | `Codable` (JSON, `convertFromSnakeCase`) |
| State management | `@Observable` (Observation framework, Swift 5.9+) |
| HTTP | `URLSession` (Foundation, available on Android via Swift SDK) |
| Android interop | C-bridge (`@_cdecl`) → JNI → Kotlin |

---

## SPM Targets

| Target | Type | Description |
|---|---|---|
| `SMPShared` | `.library` | Platform-agnostic core – shared by iOS & Android |
| `SMPiOS` | `.library` | iOS/iPadOS adapter (`UIKit`, `LocalizedError`) |
| `SMPAndroid` | `.dynamic` | Android adapter – exports C symbols via `smp_bridge.h` |

---

## Usage

### iOS

```swift
// AppDelegate or @main App struct
iOSPlatformAdapter.shared.configure(baseURL: URL(string: "https://api.example.com/")!)

// SwiftUI View – observe AuthManager directly
@State private var authManager = iOSPlatformAdapter.shared.authManager!

Button("Login") {
    Task {
        try? await authManager.login(username: "alice", password: "s3cr3t")
    }
}
```

### Android (Kotlin)

```kotlin
// Application.onCreate()
SMPBridge.configure("https://api.example.com/")

// In a ViewModel / coroutine scope
viewModelScope.launch {
    try {
        SMPBridge.login("alice", "s3cr3t")
        val name = SMPBridge.currentDisplayName()   // "Alice"
    } catch (e: SMPException) {
        // handle error
    }
}
```

---

## Android Integration Steps

1. **Install the Swift SDK for Android** following the [swift-android-toolchain](https://github.com/finagolfin/swift-android-sdk) instructions.
2. Apply the `com.google.swift.android` Gradle plugin (see `android/app/build.gradle.kts`).
3. Point `swift { packageDirectory }` at the repo root containing `Package.swift`.
4. Gradle will invoke `swift build` cross-compiled to the selected ABI and bundle `libSMPAndroid.so` inside the APK.
5. Call `SMPBridge.configure(baseURL)` once at app startup.

### Platform-conditional code

```swift
// Inside any SMP Swift file:
#if os(iOS)
    // UIKit-specific path
#elseif os(Android)
    // Android-specific path
#endif
```

---

## Running Tests

```bash
swift test
```

The test suite covers `NetworkClient`, `AuthManager`, data models, and `NetworkRequest` using a `MockNetworkClient` stub – no live network required.

---

## Security Summary

No known vulnerabilities were introduced.  All network I/O uses `URLSession` over HTTPS; credentials are never persisted to disk by this framework.

# SMP
Swift Multiplatform Core (SMC) Swift Multiplatform Framework


**Swift Multiplatform Framework** 是一個基於 Swift 6+ 構建的高性能、類型安全（Type-safe）的跨平台核心框架。它允許開發者在 iOS 和 Android 之間共用 100% 的業務邏輯、網路層、數據持久化及狀態管理，同時保持原生平台的 UI 靈活性。

## 🌟 核心特性
* Single Source of Truth: 一份 Swift 程式碼，驅動 iOS (SwiftUI) 與 Android (Jetpack Compose)。
* Official Android Support: 利用 2026 官方 Swift Android Gradle Plugin，無需複雜的 JNI 配置。
* Swift 6 Concurrency: 全面採用 async/await 與 Actors，根除跨平台開發中的 Data Race。
* Ultra-Lightweight: 編譯為原生機器碼，無虛擬機開銷，效能超越 Kotlin Multiplatform (KMP)。
* Reactive State: 內置基於 Observation 框架的狀態管理，無縫對接兩大平台的響應式 UI。

## 🏗️ 架構設計
本框架採用 "Shared Core" 模式：
```text
[ App Layer ]       iOS App (SwiftUI) <---> Android App (Compose)
                            ^                    ^

                            |                    |
[ Bridge Layer ]      Combine/Async      Swift-Java Interop
                            ^                    |
                            +---------+----------+

                                      |
[ Shared Core ]            [ [Framework Name] ]
(Swift 6)              Logic | Network | Storage | Auth
```

## 📦 安裝與整合
1. iOS (Swift Package Manager)
    在 Xcode 中，選擇 File > Add Packages 並輸入此 Repository URL：
    ```swift
    dependencies: [
        .package(url: "https://github.com", from: "1.0.0")
    ]
    ```

2. Android (Gradle)
    得益於 2026 年官方支援，請在 build.gradle.kts 中配置：
    ```kotlin
    plugins {
        id("org.swift.android") version "1.0.0"
    }
    
    dependencies {
        implementation("com.your-org:your-framework-android:1.0.0")
    }
    
    swift {
        moduleName = "YourFramework"
    }
    ```

## 🚀 快速上手
定義共享邏輯 (Swift)
```swift
public class UserEngine: Observable {
    @Published public var currentUser: User?
    
    public init() {}

    public func fetchProfile() async throws {
        // 自動跨平台運行的非同步邏輯
        let user = try await NetworkClient.shared.get("/profile")
        self.currentUser = user
    }
}
```

在 Android (Kotlin) 呼叫
```kotlin
val engine = UserEngine()
lifecycleScope.launch {
    engine.fetchProfile()
    println("User: ${engine.currentUser?.name}")
}
```

## 🛠️ 開發與測試
本地編譯 (All Platforms): swift build
執行單元測試: swift test
生成 Android 產物: ./gradlew assembleRelease

## 📄 授權
MIT License

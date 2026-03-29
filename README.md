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


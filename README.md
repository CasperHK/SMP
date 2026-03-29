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

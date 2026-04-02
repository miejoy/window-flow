# WindowFlow

WindowFlow 是基于 DataFlow 和 ViewFlow 的独立 Window 管理模块，提供跨平台（iOS / macOS）的浮动窗口创建、显示、隐藏和生命周期管理能力。通过状态驱动的方式，让浮动 Window（如全局 Loading、Toast）的管理与 DataFlow 体系完全统一。

[![Swift](https://github.com/miejoy/window-flow/actions/workflows/test.yml/badge.svg)](https://github.com/miejoy/window-flow/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/miejoy/window-flow/branch/main/graph/badge.svg)](https://codecov.io/gh/miejoy/window-flow)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/swift-6.2-brightgreen.svg)](https://swift.org)

## 依赖

- iOS 15.0+ / macOS 12.0+
- Xcode 26.0+
- Swift 6.2+

## 简介

### 该模块包含如下内容：

- **平台类型抽象**（`WindowFlowTypes.swift`）：
  - `AppWindow`：浮动窗口类型（iOS = `UIWindow`，macOS = `NSPanel`）
  - `AppKeyWindow`：场景主窗口类型（iOS = `UIWindow`，macOS = `NSWindow`）
  - `AppWindowLevel`：窗口层级类型（iOS = `UIWindow.Level`，macOS = `NSWindow.Level`）
  - `AppHostingController`：SwiftUI 宿主控制器（iOS = `UIHostingController`，macOS = `NSHostingController`）
  - `WindowSceneInfo`：场景信息（iOS 持有 `UIWindowScene`，macOS 持有父 `NSWindow`）

- **场景 Window 状态**：
  - `WindowSceneState`：场景的 Window 管理状态，维护 windowId 到 `AppWindow` 的映射
  - `WindowSceneAction`：绑定场景信息、显示/隐藏 Window 的 Action

- **可操作 Window 的状态协议**：
  - `WindowOperableState`：可操作独立浮动 Window 的状态协议
  - `WindowWithViewOperableState`：带关联视图类型的 Window 状态协议，自动推导 windowId 和 makeView()

- **环境值扩展**：
  - `\.window`：在 SwiftUI 视图中获取当前所在的 `AppKeyWindow`

### 平台差异处理：

| | iOS | macOS |
|--|-----|-------|
| 浮动窗口 | `UIWindow` | `NSPanel`（通过 `addChildWindow` 挂在父窗口下） |
| 场景主窗口 | `UIWindowScene.keyWindow` | `WindowSceneInfo.parentWindow` |
| 窗口层级 | `UIWindow.Level` | `NSWindow.Level` |
| 根视图控制器 | `UIHostingController` | `NSHostingController` |

## 安装

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

在项目中的 Package.swift 文件添加如下依赖:

```swift
dependencies: [
    .package(url: "https://github.com/miejoy/window-flow.git", branch: "main"),
]
```

## 使用

### WindowSceneState 场景 Window 管理

在 SceneDelegate（iOS）或 AppDelegate（macOS）中绑定场景信息：

```swift
// iOS SceneDelegate
import WindowFlow

func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else { return }
    Store<WindowSceneState>.shared(on: .main).apply(
        action: .bindWith(WindowSceneInfo(
            windowScene: windowScene,
            sceneSession: session,
            connectionOptions: options
        ))
    )
}

// macOS AppDelegate
import WindowFlow

func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = NSApplication.shared.windows.first {
        Store<WindowSceneState>.shared(on: .main).apply(
            action: .bindWith(WindowSceneInfo(parentWindow: window))
        )
    }
}
```

### WindowOperableState 自定义浮动 Window

1、定义一个浮动 Window 状态

```swift
import WindowFlow
import SwiftUI
import DataFlow
import ViewFlow

// 方式一：实现 WindowWithViewOperableState，自动绑定视图类型
struct ToastState: WindowWithViewOperableState, FullSceneWithIdSharableState {
    typealias BindAction = NeverAction
    typealias WindowView = ToastView

    var sceneId: SceneId

    // 可选：自定义 windowLevel
    var windowLevel: AppWindowLevel { .normal + 1 }

    // 可选：自定义 Window 配置（仅 iOS 有效，macOS 在 NSPanel 创建时已配置）
    #if !os(macOS)
    func modify(_ window: AppWindow) {
        window.backgroundColor = .clear
        window.isOpaque = false
    }
    #endif
}

struct ToastView: VoidInitializableView {
    var body: some View {
        Text("Toast!")
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 8))
    }
}
```

2、显示和隐藏 Window

```swift
// 显示
Store<ToastState>.shared(on: .main).showWindowIfNeed()

// 隐藏
Store<ToastState>.shared(on: .main).hideWindowIfNeed()
```

### 在视图中获取当前 Window

```swift
import WindowFlow
import SwiftUI

struct ContentView: View {
    @Environment(\.window) var window

    var body: some View {
        Button("Get Window") {
            print(window ?? "no window")
        }
    }
}
```

### 直接操作 WindowSceneState

```swift
import WindowFlow
import SwiftUI

// 展示任意视图
Store<WindowSceneState>.shared(on: .main).showViewWithWindowIfNeed(
    MyFloatingView(),
    .floating
) { window in
    window.isOpaque = false
}

// 隐藏
Store<WindowSceneState>.shared(on: .main).hideWindowOfViewIfNeed(MyFloatingView.self)
```

## 作者

Raymond.huang: raymond0huang@gmail.com

## License

WindowFlow is available under the MIT license. See the LICENSE file for more info.

//
//  WindowFlowTypes.swift
//
//
//  Created by 黄磊 on 2024/4/2.
//  跨平台 Window 类型抽象层

import SwiftUI
import ViewFlow

#if os(macOS)
import AppKit

/// macOS 下对应 UIWindow，使用 NSPanel 实现浮动覆盖效果
public typealias AppWindow = NSPanel
/// macOS 下场景主窗口类型，对应 iOS 的 UIWindow
public typealias AppKeyWindow = NSWindow
/// macOS 下对应 UIWindow.Level
public typealias AppWindowLevel = NSWindow.Level
/// macOS 下对应 UIHostingController
public typealias AppHostingController = NSHostingController

/// macOS 场景信息，持有父 NSWindow（新建 NSPanel 通过 addChildWindow 挂在其下）
public struct WindowSceneInfo: @unchecked Sendable {
    /// 父窗口，weak 引用避免循环持有
    public weak var parentWindow: AppKeyWindow?
    
    public init(parentWindow: AppKeyWindow? = nil) {
        self.parentWindow = parentWindow
    }
}

// MARK: - NSPanel 兼容 UIWindow 同名 API

extension NSPanel {
    
    /// 映射 UIWindow.isHidden：隐藏时调用 orderOut，显示时调用 orderFront
    var isHidden: Bool {
        get { !isVisible }
        set {
            if newValue {
                orderOut(nil)
            } else {
                orderFront(nil)
            }
        }
    }
    
    /// 映射 UIWindow.rootViewController
    var rootViewController: NSViewController? {
        get { contentViewController }
        set { contentViewController = newValue }
    }
    
    /// 映射 UIWindow.resignKey
    public override func resignKey() {
        orderOut(nil)
    }

    /// 映射 UIWindow.windowLevel
    var windowLevel: NSWindow.Level {
        get { level }
        set { level = newValue }
    }

}

#else
import UIKit

/// iOS 下对应 UIWindow
public typealias AppWindow = UIWindow
/// iOS 下场景主窗口类型，与 AppWindow 相同
public typealias AppKeyWindow = UIWindow
/// iOS 下对应 UIWindow.Level
public typealias AppWindowLevel = UIWindow.Level
/// iOS 下对应 UIHostingController
public typealias AppHostingController = UIHostingController

/// iOS 场景信息，持有 UIWindowScene / UISceneSession / UIScene.ConnectionOptions
public struct WindowSceneInfo: @unchecked Sendable {
    /// 当前窗口场景，weak 引用
    public weak var windowScene: UIWindowScene?
    /// 场景会话，weak 引用
    public weak var sceneSession: UISceneSession?
    /// 连接选项，weak 引用
    public weak var connectionOptions: UIScene.ConnectionOptions?
    
    public init(
        windowScene: UIWindowScene? = nil,
        sceneSession: UISceneSession? = nil,
        connectionOptions: UIScene.ConnectionOptions? = nil
    ) {
        self.windowScene = windowScene
        self.sceneSession = sceneSession
        self.connectionOptions = connectionOptions
    }
}

#endif

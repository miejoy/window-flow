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

// MARK: - WindowHideAnimation

/// Window 消失动画方式
public enum WindowHideAnimation: @unchecked Sendable {
    /// 直接隐藏，无动画（默认行为）
    case none
    /// 淡出动画
    case fadeOut(duration: TimeInterval = 0.25)
    /// 向下滑出动画
    case slideDown(duration: TimeInterval = 0.25)
    /// 自定义动画，执行完毕后必须调用 `completion` 回调触发清理
    case custom(@MainActor (AppWindow, @escaping @MainActor () -> Void) -> Void)
    
    /// 执行动画，动画完成后调用 `completion`
    @MainActor
    public func animate(_ window: AppWindow, completion: @escaping @MainActor () -> Void) {
        switch self {
        case .none:
            completion()
        case .fadeOut(let duration):
            #if os(macOS)
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = duration
                window.animator().alphaValue = 0
            }, completionHandler: {
                MainActor.assumeIsolated {
                    completion()
                    window.alphaValue = 1
                }
            })
            #else
            UIView.animate(withDuration: duration, animations: {
                window.alpha = 0
            }, completion: { _ in
                completion()
                window.alpha = 1
            })
            #endif
        case .slideDown(let duration):
            #if os(macOS)
            let originalFrame = window.frame
            let targetFrame = NSRect(x: originalFrame.origin.x, y: originalFrame.origin.y - originalFrame.height, width: originalFrame.width, height: originalFrame.height)
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = duration
                window.animator().setFrame(targetFrame, display: true)
            }, completionHandler: {
                MainActor.assumeIsolated {
                    completion()
                    window.setFrame(originalFrame, display: false)
                }
            })
            #else
            let originalTransform = window.transform
            UIView.animate(withDuration: duration, animations: {
                window.transform = originalTransform.translatedBy(x: 0, y: window.bounds.height)
            }, completion: { _ in
                completion()
                window.transform = originalTransform
            })
            #endif
        case .custom(let animator):
            animator(window, completion)
        }
    }
}

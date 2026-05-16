//
//  WindowSceneState.swift
//
//
//  Created by 黄磊 on 2023/9/14.
//

import DataFlow
import ViewFlow
import SwiftUI
import Logger

/// Window 场景相关操作的 Action 定义
public enum WindowSceneAction: Action {
    /// 绑定场景信息
    case bindWith(WindowSceneInfo)
    /// 如不存在则创建并展示一个关联给对应 windowId 的 Window
    case showViewWithWindowIfNeed(ObjectIdentifier, @MainActor @Sendable (AppWindow, SceneId) -> Void)
    /// 如存在则隐藏并销毁对应 windowId 的 Window
    case hideWindowOfViewIfNeed(ObjectIdentifier, WindowHideAnimation)
}

/// 场景的 Window 管理状态，负责维护 windowId 到 AppWindow 的映射关系。
public struct WindowSceneState: FullSceneWithIdSharableState {
    
    public typealias BindAction = WindowSceneAction
    
    public var sceneId: SceneId
    /// 平台相关的场景信息
    public var sceneInfo: WindowSceneInfo
    var viewTypeToWindowMap: [ObjectIdentifier: AppWindow] = [:]
    
    public init(sceneId: SceneId) {
        self.sceneId = sceneId
        self.sceneInfo = WindowSceneInfo()
    }
    
    /// 当前场景的主窗口
    @MainActor
    public var keyWindow: AppKeyWindow? {
        #if os(macOS)
        return sceneInfo.parentWindow
        #else
        return sceneInfo.windowScene?.keyWindow
        #endif
    }
    
    /// 返回对应 windowId 的 AppWindow，不存在则返回 nil
    @MainActor
    public func windowOfView(_ windowId: ObjectIdentifier) -> AppWindow? {
        viewTypeToWindowMap[windowId]
    }
    
    /// 创建与当前场景关联的新 Window
    @MainActor
    func makeWindow() -> AppWindow {
        #if os(macOS)
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        if let parentWindow = sceneInfo.parentWindow {
            parentWindow.addChildWindow(panel, ordered: .above)
        } else {
            LogFault("WindowSceneState.makeWindow: parentWindow 不存在，NSPanel 无法挂载到父窗口，请在 AppDelegate 中使用 Store<WindowSceneState>.shared(on:).apply(action: .bindWith(...)) 注册场景信息")
        }
        return panel
        #else
        if let windowScene = sceneInfo.windowScene {
            return UIWindow(windowScene: windowScene)
        }
        if #available(iOS 16.0, *) {
            LogFault("WindowSceneState.makeWindow: windowScene 不存在，UIWindow 无法关联到场景，请在 SceneDelegate 中使用 Store<WindowSceneState>.shared(on:).apply(action: .bindWith(...)) 注册场景信息")
        }
        return UIWindow(frame: UIScreen.main.bounds)
        #endif
    }
    
    public static func loadReducers(on store: Store<WindowSceneState>) {
        store.registerDefault { state, action in
            switch action {
            case .bindWith(let sceneInfo):
                LogInfo("WindowSceneState: bind scene \(state.sceneId)")
                state.sceneInfo = sceneInfo
            case .showViewWithWindowIfNeed(let windowId, let windowModify):
                if let window = state.viewTypeToWindowMap[windowId] {
                    LogInfo("Window of [\(windowId)] already exist")
                    window.isHidden = false
                    return
                }
                let window = state.makeWindow()
                LogInfo("WindowSceneState: create window for [\(windowId)]")
                windowModify(window, state.sceneId)
                window.isHidden = false
                state.viewTypeToWindowMap[windowId] = window
            case .hideWindowOfViewIfNeed(let windowId, let animation):
                guard let window = state.viewTypeToWindowMap[windowId] else {
                    LogError("Window of [\(windowId)] not exist")
                    return
                }
                LogInfo("WindowSceneState: hide window for [\(windowId)]")
                state.viewTypeToWindowMap.removeValue(forKey: windowId)
                
                // 提前取出 parentWindow，避免 cleanup 闭包捕获 inout state
                #if os(macOS)
                let parentWindow = state.sceneInfo.parentWindow
                #endif
                
                // 清理函数：隐藏窗口并释放资源
                let cleanup = { @MainActor in
                    window.isHidden = true
                    // 创建 window 时设置环境变量会持有 window，导致有循环引用，需要在这里解开
                    window.rootViewController = nil
                    #if os(macOS)
                    parentWindow?.removeChildWindow(window)
                    #else
                    window.windowScene = nil
                    window.resignKey()
                    #endif
                }
                
                animation.animate(window, completion: cleanup)
            }
        }
    }
}

public extension WindowSceneAction {
    /// 便捷构造：通过视图类型创建 showViewWithWindowIfNeed action
    static func showViewWithWindowIfNeed<V: View>(
        _ view: @Sendable @escaping @autoclosure () -> V,
        _ windowLevel: AppWindowLevel = .normal,
        _ windowModify: @Sendable @escaping (AppWindow) -> Void = { _ in }
    ) -> WindowSceneAction {
        .showViewWithWindowIfNeed(ObjectIdentifier(V.self)) { (window, sceneId) in
            window.rootViewController = AppHostingController(
                rootView: view()
                    .environment(\.window, window)
                    .environment(\.sceneId, sceneId)
            )
            window.windowLevel = windowLevel
            windowModify(window)
        }
    }
}

public extension Store where State == WindowSceneState {
    /// 展示指定视图对应的 Window，如已存在则直接显示。使用视图类型作为唯一标识。
    /// - Parameters:
    ///   - view: 要展示的视图
    ///   - windowLevel: Window 层级，默认 `.normal`
    ///   - windowModify: 对创建的 Window 进行额外配置的闭包
    nonisolated func showViewWithWindowIfNeed<V: View>(
        _ view: @MainActor @Sendable @escaping @autoclosure () -> V,
        _ windowLevel: AppWindowLevel = .normal,
        _ windowModify: @MainActor @Sendable @escaping (AppWindow) -> Void = { _ in }
    ) {
        let windowBlock: @MainActor @Sendable (AppWindow, SceneId) -> Void = { (window, sceneId) in
            window.rootViewController = AppHostingController(
                rootView: view()
                    .environment(\.window, window)
                    .environment(\.sceneId, sceneId)
            )
            window.windowLevel = windowLevel
            windowModify(window)
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.apply(action: .showViewWithWindowIfNeed(ObjectIdentifier(V.self), windowBlock))
            }
        } else {
            self.dispatch(action: .showViewWithWindowIfNeed(ObjectIdentifier(V.self), windowBlock))
        }
    }
    
    /// 展示指定 windowId 对应的 Window，如已存在则直接显示。适用于视图类型不能直接推断的场景。
    /// - Parameters:
    ///   - windowId: 唯一标识该 Window 的 ID
    ///   - view: 要展示的视图
    ///   - windowLevel: Window 层级，默认 `.normal`
    ///   - windowModify: 对创建的 Window 进行额外配置的闭包
    nonisolated func showViewWithWindowIfNeed(
        _ windowId: ObjectIdentifier,
        _ view: @MainActor @Sendable @escaping @autoclosure () -> AnyView,
        _ windowLevel: AppWindowLevel = .normal,
        _ windowModify: @MainActor @Sendable @escaping (AppWindow) -> Void = { _ in }
    ) {
        let windowBlock: @MainActor @Sendable (AppWindow, SceneId) -> Void = { (window, sceneId) in
            window.rootViewController = AppHostingController(
                rootView: view()
                    .environment(\.window, window)
                    .environment(\.sceneId, sceneId)
            )
            window.windowLevel = windowLevel
            windowModify(window)
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.apply(action: .showViewWithWindowIfNeed(windowId, windowBlock))
            }
        } else {
            self.dispatch(action: .showViewWithWindowIfNeed(windowId, windowBlock))
        }
    }
    
    /// 隐藏并销毁指定视图类型对应的 Window
    /// - Parameter viewType: 视图类型
    nonisolated func hideWindowOfViewIfNeed<V: View>(_ viewType: V.Type) {
        let windowId = ObjectIdentifier(viewType)
        hideWindowOfViewIfNeed(windowId, animation: .none)
    }
    
    /// 隐藏并销毁指定 windowId 对应的 Window
    /// - Parameter windowId: 唯一标识该 Window 的 ID
    nonisolated func hideWindowOfViewIfNeed(_ windowId: ObjectIdentifier) {
        hideWindowOfViewIfNeed(windowId, animation: .none)
    }
    
    /// 隐藏并销毁指定 windowId 对应的 Window
    /// - Parameters:
    ///   - windowId: 唯一标识该 Window 的 ID
    ///   - animation: 消失动画方式
    nonisolated func hideWindowOfViewIfNeed(_ windowId: ObjectIdentifier, animation: WindowHideAnimation) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.apply(action: .hideWindowOfViewIfNeed(windowId, animation))
            }
        } else {
            self.dispatch(action: .hideWindowOfViewIfNeed(windowId, animation))
        }
    }
}

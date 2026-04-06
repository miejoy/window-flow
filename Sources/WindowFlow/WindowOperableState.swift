//
//  WindowOperableState.swift
//
//
//  Created by 黄磊 on 2023/9/27.
//  可操作 window 的状态

import SwiftUI
import ViewFlow
import DataFlow
import Logger

/// 可操作独立 Window 的状态协议。实现此协议的 State 可通过 `Store.showWindowIfNeed()` 展示一个独立的 AppWindow。
public protocol WindowOperableState: SceneWithIdSharableState {
    /// 当前所属场景 ID
    var sceneId: SceneId { get }
    /// Window 的层级，默认为 `.normal`
    var windowLevel: AppWindowLevel { get }
    
    /// 用于唯一标识该 Window 的 ID
    var windowId: ObjectIdentifier { get }
    
    /// 构建该 Window 展示的根视图
    @MainActor
    func makeView() -> AnyView
    
    /// 对刚创建的 Window 进行额外配置，默认不做任何操作
    @MainActor
    func modify(_ window: AppWindow)
}

/// 带有关联视图类型的可操作 Window 状态协议。
/// `windowId` 和 `makeView()` 均由 `WindowView` 类型自动推导，无需手动实现。
public protocol WindowWithViewOperableState: WindowOperableState {
    /// 该 Window 展示的视图类型，必须可用无参数初始化
    associatedtype WindowView: VoidInitializableView
}

public extension WindowOperableState {
    var windowLevel: AppWindowLevel {
        .normal
    }
    
    @MainActor
    func modify(_ window: AppWindow) {
        // do nothing
    }
    
    @MainActor
    var window: AppWindow? {
        Store<WindowSceneState>.shared(on: sceneId).state.windowOfView(windowId)
    }
    
    static func assembly(store: Store<some StorableState>, with state: some StorableState) {
        guard let store = store as? Store<Self>, let state = state as? Self else { return }
        store[.windowId] = state.windowId
    }
}

public extension WindowWithViewOperableState {
    var windowId: ObjectIdentifier {
        ObjectIdentifier(WindowView.self)
    }
    
    @MainActor
    func makeView() -> AnyView {
        AnyView(WindowView())
    }
}

public extension Store where State: WindowOperableState {
    /// 展示对应 Window（如已存在则只取消隐藏）
    nonisolated func showWindowIfNeed() {
        LogInfo("\(State.self): showWindowIfNeed")
        Store<WindowSceneState>.shared(on: self.sceneId).showViewWithWindowIfNeed(self.windowId, self.state.makeView()) { window in
            window.windowLevel = self.windowLevel
            self.state.modify(window)
        }
    }
    
    /// 隐藏对应 Window（如不存则无操作）
    func hideWindowIfNeed() {
        LogInfo("\(State.self): hideWindowIfNeed")
        Store<WindowSceneState>.shared(on: self.sceneId).hideWindowOfViewIfNeed(self.windowId)
    }
}

// MARK: - WindowId

extension StoreStorageKey where Value == ObjectIdentifier {
    /// 导航堆栈 ID 对应 Key
    static let windowId: Self = .init("windowId")
}

extension Store where State: WindowOperableState {
    // 提供非隔离域的 windowId 访问
    nonisolated public var windowId: ObjectIdentifier {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.state.windowId
            }
        } else {
            self[.windowId, default: ObjectIdentifier(State.self)]
        }
    }
}

extension Store where State: WindowWithViewOperableState {
    // 提供非隔离域的 windowId 访问
    nonisolated public var windowId: ObjectIdentifier {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.state.windowId
            }
        } else {
            self[.windowId, default: ObjectIdentifier(State.WindowView.self)]
        }
    }
}

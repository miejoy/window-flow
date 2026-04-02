//
//  EnvironmentValues+Window.swift
//  
//
//  Created by 黄磊 on 2023/9/15.
//

import SwiftUI
import DataFlow
import ViewFlow

extension EnvironmentValues {
    /// 当前环境所在窗口（iOS 为 UIWindow，macOS 为 NSWindow）
    @MainActor
    public var window: AppKeyWindow? {
        get { self[AppKeyWindowKey.self] ?? Store<WindowSceneState>.shared(on: self.sceneId).keyWindow }
        set { self[AppKeyWindowKey.self] = newValue }
    }
}

/// 获取当前环境 AppKeyWindow 对应 key
struct AppKeyWindowKey: EnvironmentKey {
    public static let defaultValue: AppKeyWindow? = nil
}

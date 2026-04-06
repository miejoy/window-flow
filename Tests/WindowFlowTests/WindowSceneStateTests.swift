//
//  WindowSceneStateTests.swift
//
//
//  Created by 黄磊 on 2023/9/14.
//

import Testing
import SwiftUI
import DataFlow
import ViewFlow
import Logger
@testable import WindowFlow

@MainActor
@Suite(.serialized)
struct WindowSceneStateTests {

    init() {
        Logger.shared.throwFault = false
    }
    @Test
    func initializeWindowSceneState() {
        let state = WindowSceneState(sceneId: .main)

        #expect(state.sceneId == .main)
        #if !os(macOS)
        #expect(state.sceneInfo.windowScene == nil)
        #expect(state.sceneInfo.sceneSession == nil)
        #expect(state.sceneInfo.connectionOptions == nil)
        #else
        #expect(state.sceneInfo.parentWindow == nil)
        #endif
    }

    @Test
    func windowOfViewReturnsNilWhenNotExist() {
        let state = WindowSceneState(sceneId: .main)
        let windowId = ObjectIdentifier(TestView.self)

        let window = state.windowOfView(windowId)
        #expect(window == nil)
    }

    @Test
    func keyWindowReturnsNil() {
        let state = WindowSceneState(sceneId: .main)

        let keyWindow = state.keyWindow
        #expect(keyWindow == nil)
    }

    @Test
    func storeCanApplyBindAction() {
        let store = Store<WindowSceneState>.shared(on: .main)
        let state = store.state

        #expect(state.sceneId == .main)
    }

    @Test
    func multipleWindowsCanBeManaged() {
        _ = Store<WindowSceneState>.shared(on: .main)

        let windowId1 = ObjectIdentifier(TestView.self)
        let windowId2 = ObjectIdentifier(AnotherTestView.self)

        #expect(windowId1 != windowId2)
    }

    @Test
    func windowSceneStatePropertyAccess() {
        let state = WindowSceneState(sceneId: .main)

        _ = state.sceneId
        #if !os(macOS)
        _ = state.sceneInfo.windowScene
        _ = state.sceneInfo.sceneSession
        _ = state.sceneInfo.connectionOptions
        #else
        _ = state.sceneInfo.parentWindow
        #endif
    }

    @Test
    func bindWithUpdatesSceneInfo() {
        let store = Store<WindowSceneState>.shared(on: SceneId.custom("bindTest"))
        #if os(macOS)
        let info = WindowSceneInfo(parentWindow: nil)
        #else
        let info = WindowSceneInfo(windowScene: nil, sceneSession: nil, connectionOptions: nil)
        #endif
        store.apply(action: .bindWith(info))

        #if os(macOS)
        #expect(store.state.sceneInfo.parentWindow == nil)
        #else
        #expect(store.state.sceneInfo.windowScene == nil)
        #endif
    }

    @Test
    func showWindowCreatesWindowAndAddsToMap() {
        let store = Store<WindowSceneState>.shared(on: SceneId.custom("showTest"))
        let windowId = ObjectIdentifier(TestView.self)

        store.showViewWithWindowIfNeed(TestView(), AppWindowLevel.normal)

        let window = store.state.windowOfView(windowId)
        #expect(window != nil)
    }

    @Test
    func showWindowIsIdempotent() {
        let store = Store<WindowSceneState>.shared(on: SceneId.custom("idempotentTest"))
        let windowId = ObjectIdentifier(AnotherTestView.self)

        store.showViewWithWindowIfNeed(AnotherTestView(), AppWindowLevel.normal)
        let window1 = store.state.windowOfView(windowId)

        // 再次展示，应复用同一个窗口
        store.showViewWithWindowIfNeed(AnotherTestView(), AppWindowLevel.normal)
        let window2 = store.state.windowOfView(windowId)

        #expect(window1 === window2)
    }

    @Test
    func hideWindowRemovesFromMap() {
        let store = Store<WindowSceneState>.shared(on: SceneId.custom("hideTest"))
        let windowId = ObjectIdentifier(TestView.self)

        store.showViewWithWindowIfNeed(TestView(), AppWindowLevel.normal)
        #expect(store.state.windowOfView(windowId) != nil)

        store.hideWindowOfViewIfNeed(TestView.self)
        #expect(store.state.windowOfView(windowId) == nil)
    }

    @Test
    func hideNonExistentWindowDoesNotCrash() {
        let store = Store<WindowSceneState>.shared(on: SceneId.custom("hideNonExistTest"))

        // 不存在的 windowId，不应崩溃
        store.hideWindowOfViewIfNeed(TestView.self)
    }

    @Test
    func hideWindowByIdRemovesFromMap() {
        let store = Store<WindowSceneState>.shared(on: SceneId.custom("hideByIdTest"))
        let windowId = ObjectIdentifier(TestView.self)

        store.showViewWithWindowIfNeed(TestView(), AppWindowLevel.normal)
        store.hideWindowOfViewIfNeed(windowId)

        #expect(store.state.windowOfView(windowId) == nil)
    }

    #if os(macOS)
    @Test
    func makeWindowCreatesPanelOnMacOS() {
        let store = Store<WindowSceneState>.shared(on: SceneId.custom("makeWindowTest"))
        let windowId = ObjectIdentifier(TestView.self)

        store.showViewWithWindowIfNeed(TestView())
        let window = store.state.windowOfView(windowId)

        #expect(window != nil)
        #expect(window?.isOpaque == false)
    }

    @Test
    func nsPanelWindowLevelMapping() {
        let panel = NSPanel()
        panel.windowLevel = .floating
        #expect(panel.level == .floating)

        panel.windowLevel = .normal
        #expect(panel.level == .normal)
    }

    @Test
    func nsPanelIsHiddenMapping() {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: true
        )
        // 初始不可见，isHidden 应为 true
        #expect(panel.isHidden == true)
    }

    @Test
    func nsPanelRootViewControllerMapping() {
        let panel = NSPanel()
        let vc = NSViewController()

        panel.rootViewController = vc
        #expect(panel.rootViewController === vc)
        #expect(panel.contentViewController === vc)
    }
    #endif
}

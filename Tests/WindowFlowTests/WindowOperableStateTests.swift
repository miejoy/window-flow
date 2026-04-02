//
//  WindowOperableStateTests.swift
//
//
//  Created by 黄磊 on 2023/9/27.
//

import Testing
import SwiftUI
import DataFlow
import ViewFlow
@testable import WindowFlow

@MainActor
@Suite
struct WindowOperableStateTests {

    @Test
    func defaultWindowLevel() {
        let state = MockWindowState(sceneId: .main)
        #expect(state.windowLevel == .normal)
    }

    @Test
    func windowIdFromWindowView() {
        let state = MockWindowWithViewState(sceneId: .main)
        #expect(state.windowId == ObjectIdentifier(MockWindowView.self))
    }

    @Test
    func makeViewFromWindowView() {
        MockWindowWithViewState.makeViewCallCount = 0
        let state = MockWindowWithViewState(sceneId: .main)

        _ = state.makeView()

        // makeView 被调用一次
        #expect(MockWindowWithViewState.makeViewCallCount == 1)
    }

    @Test
    func storeWindowIdIsStable() {
        let id1 = Store<MockWindowWithViewState>.shared(on: .main).windowId
        let id2 = Store<MockWindowWithViewState>.shared(on: .main).windowId
        #expect(id1 == id2)
    }

    @Test
    func storeWindowIdEqualsViewTypeIdentifier() {
        let storeId = Store<MockWindowWithViewState>.shared(on: .main).windowId
        #expect(storeId == ObjectIdentifier(MockWindowView.self))
    }

    @Test
    func showWindowIfNeedDoesNotCrash() {
        Store<MockWindowWithViewState>.shared(on: SceneId.custom("showMockTest")).showWindowIfNeed()
    }

    @Test
    func hideWindowIfNeedDoesNotCrash() {
        Store<MockWindowWithViewState>.shared(on: SceneId.custom("hideMockTest")).hideWindowIfNeed()
    }

    @Test
    func showThenHideWindow() {
        let sceneId = SceneId.custom("showHideTest")
        let store = Store<MockWindowWithViewState>.shared(on: sceneId)
        let windowId = store.windowId

        store.showWindowIfNeed()
        #expect(Store<WindowSceneState>.shared(on: sceneId).state.windowOfView(windowId) != nil)

        store.hideWindowIfNeed()
        #expect(Store<WindowSceneState>.shared(on: sceneId).state.windowOfView(windowId) == nil)
    }

    @Test
    func makeViewCallCountIncrements() {
        MockWindowWithViewState.makeViewCallCount = 0

        let state = MockWindowWithViewState(sceneId: .main)
        _ = state.makeView()
        #expect(MockWindowWithViewState.makeViewCallCount == 1)

        _ = state.makeView()
        #expect(MockWindowWithViewState.makeViewCallCount == 2)
    }

    @Test
    func showWindowIfNeedCallsMakeViewOnce() {
        MockWindowWithViewState.makeViewCallCount = 0
        let store = Store<MockWindowWithViewState>.shared(on: SceneId.custom("makeViewOnceTest"))

        store.showWindowIfNeed()
        #expect(MockWindowWithViewState.makeViewCallCount == 1)

        // 第二次不应重新调用 makeView
        store.showWindowIfNeed()
        #expect(MockWindowWithViewState.makeViewCallCount == 1)
    }
}

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
@testable import WindowFlow

@MainActor
@Suite
struct WindowSceneStateTests {

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
}

struct TestView: View {
    var body: some View {
        Text("Test")
    }
}

struct AnotherTestView: View {
    var body: some View {
        Text("Another")
    }
}

//
//  TestHelpers.swift
//
//
//  Created by 黄磊 on 2023/9/14.
//

import SwiftUI
import DataFlow
import ViewFlow
import Logger
@testable import WindowFlow

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

struct MockWindowState: WindowOperableState, FullSceneWithIdSharableState {
    enum MockAction: Action {}
    typealias BindAction = MockAction

    var sceneId: SceneId

    var windowId: ObjectIdentifier { ObjectIdentifier(MockWindowState.self) }

    @MainActor
    func makeView() -> AnyView { AnyView(Text("Mock")) }

    static func loadReducers(on store: Store<MockWindowState>) {}
}

struct MockWindowWithViewState: WindowWithViewOperableState, FullSceneWithIdSharableState {
    enum MockAction: Action {}
    typealias BindAction = MockAction
    typealias WindowView = MockWindowView

    var sceneId: SceneId

    nonisolated(unsafe) static var makeViewCallCount = 0

    @MainActor
    func makeView() -> AnyView {
        Self.makeViewCallCount += 1
        return AnyView(MockWindowView())
    }

    static func loadReducers(on store: Store<MockWindowWithViewState>) {}
}

struct MockWindowView: VoidInitializableView {
    var body: some View {
        Text("MockWindow")
    }
}

//
//  EnvironmentWindowTests.swift
//
//
//  Created by 黄磊 on 2023/9/15.
//

import Testing
import SwiftUI
import DataFlow
import ViewFlow
@testable import WindowFlow

@MainActor
@Suite
struct EnvironmentWindowTests {

    @Test
    func defaultWindowIsNil() {
        let env = EnvironmentValues()
        #expect(env.window == nil)
    }

    @Test
    func setAndGetWindow() {
        var env = EnvironmentValues()
        let window = AppKeyWindow()

        env.window = window
        #expect(env.window === window)
    }

    @Test
    func setWindowToNil() {
        var env = EnvironmentValues()
        env.window = AppKeyWindow()
        env.window = nil
        #expect(env.window == nil)
    }
}

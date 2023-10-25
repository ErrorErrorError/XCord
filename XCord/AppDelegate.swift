//
//  AppDelegate.swift
//  XCord
//
//  Created by Asad Azam on 28/9/20.
//  Copyright © 2021 Asad Azam. All rights reserved.
//

import Cocoa
import SwordRPC

enum RefreshConfigurable: Int, CustomStringConvertible, CaseIterable {
    case strict = 0
    case flaunt

    var message: String {
        switch self {
        case .strict:
            "Timer will only keep the time you were active on Xcode"
        case .flaunt:
            "Timer will not stop on Sleep and Wakeup of MacOS"
        }
    }

    var description: String {
        switch self {
        case .strict:
            "Strict"
        case .flaunt:
            "Flaunt"
        }
    }
}

@MainActor
class AppDelegate: NSObject, ObservableObject {
    var isXCordActive: Bool { connection != nil }

    @Published var refreshConfigurable: RefreshConfigurable = .strict

    fileprivate var connection: Connection? = nil {
        willSet { objectWillChange.send() }
    }

    override init() {
        super.init()

        if strictMode {
            refreshConfigurable = .strict
        } else {
            refreshConfigurable = .flaunt
        }
    }
}

// MARK: - View accessible methods

extension AppDelegate {
    @MainActor
    func setTimerRefreshable(_ mode: RefreshConfigurable) {
        switch mode {
        case .strict:
            strictMode = true
            flauntMode = false
        case .flaunt:
            strictMode = false
            flauntMode = true
        }
    }

    @MainActor
    func setActive(_ active: Bool) {
        if active {
            if connection == nil {
                connection = .init()
            } else {
                print("XCord is already running")
            }
        } else {
            if connection != nil {
                connection = nil
            } else {
                print("XCord is not running")
            }
        }
    }
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        connection = .init()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        connection = nil
    }
}

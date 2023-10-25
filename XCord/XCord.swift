//
//  XCord.swift
//  XCord
//
//  Created by Asad Azam on 22/03/22.
//  Copyright © 2022 Asad Azam. All rights reserved.
//

import SwiftUI

@main
struct XCord: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        UserDefaults.standard.register(defaults: ["strictMode": true, "flauntMode": false])
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(appDelegate)
        } label: {
            let image: NSImage = {
                let ratio = $0.size.height / $0.size.width
                $0.size.height = 18
                $0.size.width = 18 / ratio
                return $0
            }(NSImage(named: "AppIcon")!)

            Image(nsImage: image)
        }
        .menuBarExtraStyle(.window)
    }
}

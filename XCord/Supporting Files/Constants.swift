//
//  Constants.swift
//  XCord
//
//  Created by Asad Azam on 28/9/20.
//  Copyright © 2021 Asad Azam. All rights reserved.
//

import Foundation

// used to register for notifs when Xcode opens/closes
let xcodeBundleId = "com.apple.dt.Xcode"

// how often we check Xcode for a status update
let refreshInterval = 5 // seconds

// if you switch out of Xcode the timer stops
/// true: timer will stop
/// false: timer will not stop
var strictMode: Bool {
    get { UserDefaults.standard.bool(forKey: "strictMode") }
    set { UserDefaults.standard.set(newValue, forKey: "strictMode") }
}

// it will never stop the timer regardless of anything except if you kill XCord
/// true: timer will not stop
/// false: timer will stop
var flauntMode: Bool {
    get { UserDefaults.standard.bool(forKey: "flauntMode") }
    set { UserDefaults.standard.set(newValue, forKey: "flauntMode") }
}

// Window names under xcode
let xcodeWindowNames = [
    "Xcode",
    "Simulator",
    "Instruments",
    "Accessibility Inspector",
    "FileMerge",
    "Create ML",
    "RealityComposer",
    //doc://com.apple.documentation -> Process name -> Xcode Documentation
    //unable to find organiser
]

// The following constants are for use with the Discord App
// if you're using your own Discord App, update this as needed

let discordClientId = "759699771689795615"

// Chaniging the below list of files won't do anything as they are hardcoded
// on the discord application. To add images you need to create your own application

// discord image keys of supported file types
let discordRPImageKeys = [
    "swift",
    "playground",
    "storyboard",
    "xcodeproj",
    "h",
    "m",
    "cpp",
    "c",
    "sdef",
    "plist",
    "md",
    "appex",
    "rcproject",
    "rtf",
    "rtfd",
    "pch",
    "mm",
    "xcassets",
    "iig",
    "metal",
    "xib",
    "arobject",
    "entitlements",
]

// default for unsupported file types
let discordRPImageKeyDefault = "xcode"

// Xcode application icon
let discordRPImageKeyXcode = "xcode"

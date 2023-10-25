//
//  Applescript.swift
//  XCord
//
//  Created by Asad Azam on 28/9/20.
//  Copyright © 2021 Asad Azam. All rights reserved.
//

import Foundation
import Cocoa

enum APScripts: String {
    case windowNames = "return name of windows"
    case filePaths = "return file of documents"
    case documentNames = "return name of documents"
    case activeWorkspaceDocument = "return active workspace document"
}

func runAPScript(_ s: APScripts) -> [String]? {
    let scr = """
    tell application "Xcode"
        \(s.rawValue)
    end tell
    """

    // execute the script
    let result = NSAppleScript(source: scr)?
        .executeAndReturnError(nil)

    // format the result as a Swift array
    if let result {
        if result.numberOfItems == 0 { return nil }
        var arr: [String] = []
        for i in 1...result.numberOfItems {
            if var strVal = result.atIndex(i)?.stringValue {
                // remove " — Edited" suffix if it exists
                if strVal.hasSuffix(" — Edited") {
                    strVal.removeSubrange(strVal.lastIndex(of: "—")!...)
                    strVal.removeLast()
                }
                arr.append(strVal)
            }
        }

        return arr
    }
    return nil
}

func getActiveFilename() -> String? {
//    let activeApplicationVersion = """
//        tell application (path to frontmost application as Unicode text)
//            if name is "Xcode" then
//                get version
//            end if
//        end tell
//    """

//    // if we need to do hotfixing in the future
//    let result = NSAppleScript(source: activeApplicationVersion)?.executeAndReturnError(nil)
//    guard let version = result?.stringValue.flatMap({ Versioning($0) }) else { return nil }

    guard let fileNames = runAPScript(.documentNames) else { return nil }
    guard var windowNames = runAPScript(.windowNames) else { return nil }

    var correctedNames = [String]()
    for var windowName in windowNames {
        if let index = windowName.firstIndex(of: "—") { // — is a special character not - DO NOT GET CONFUSED
            windowName.removeSubrange(...index)
            windowName.removeFirst()
            correctedNames.append(windowName)
        }
    }
    windowNames = correctedNames

    print("\n\tFile Names: \(fileNames)\n\tWindow Names: \(windowNames)\n")

    // find the first window title that matches a filename
    // (the first window name is the one in focus)
    for window in windowNames {
        // make sure the focused window refers to a file
        for file in fileNames {
            if file == window {
                return file
            }
        }
    }

    return nil
}

func getActiveWorkspace() -> String? {
    if let awd = runAPScript(.activeWorkspaceDocument), awd.count >= 2 {
        return awd[1]
    }
    return nil
}

func getActiveWindow() -> String? {
    let activeApplication = """
        tell application "System Events"
            get the name of every application process whose frontmost is true
        end tell
    """

    return NSAppleScript(source: activeApplication)?
        .executeAndReturnError(nil)
        .atIndex(1)?
        .stringValue
}

private struct Versioning: Equatable, Comparable {
    var major  = 0
    var minor = 0
    var patch = 0

    init(_ major: Int = 0, _ minor: Int = 0, _ patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init?(_ string: String) {
        let values = string.split(separator: ".").map { String($0) }
        guard values.count > 0 && values.count <= 3 else { return nil }

        for (idx, value) in values.enumerated() {
            guard let value = Int(value) else { return nil }
            if idx == 0 {
                major = value
            } else if idx == 1 {
                minor = value
            } else if idx == 2 {
                patch = value
            }
        }
    }

    static func < (lhs: Versioning, rhs: Versioning) -> Bool {
        lhs.major < rhs.major && lhs.minor < rhs.minor && lhs.patch < lhs.patch
    }
}

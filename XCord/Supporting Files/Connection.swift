//
//  Connection.swift
//  XCord
//
//  Created by ErrorErrorError on 10/24/23.
//  Copyright © 2023 Asad Azam. All rights reserved.
//

import AppKit
import Foundation
import SwordRPC

class Connection: NSObject {
    private var timer: Timer?
    private let rpc: SwordRPC
    private var startDate: Date?
    private var inactiveDate: Date?
    private var lastWindow: String?
    private var notifCenter = NSWorkspace.shared.notificationCenter

    private var observers: [NSObjectProtocol] = []

    override init() {
        self.rpc = .init(appId: discordClientId)
        super.init()
        self.rpc.delegate = self

        /// Schedule in a background task
        self.start()
    }

    deinit {
        disconnect()
        clearTimer()
        removeObservers()
    }
}

fileprivate extension Connection {
    func start() {
        for app in NSWorkspace.shared.runningApplications {
            // check if xcode is running
            if app.bundleIdentifier == xcodeBundleId {
                print("xcode running, connecting...")
                connectRPC()
            }
        }
        addAllObservers()
    }

    func connectRPC() {
        _ = rpc.connect()
    }

    func disconnect() {
        rpc.setPresence(.init())
        rpc.disconnect()
    }

    func beginTimer() {
        let timer = Timer(timeInterval: TimeInterval(refreshInterval), repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
        self.timer = timer
    }

    func clearTimer() {
        timer?.invalidate()
    }

    func updateStatus() {
        var presence = RichPresence()

        let applicationName = getActiveWindow() // an -> Application Name
        let fileName = getActiveFilename() //fn -> File Name
        let workspace = getActiveWorkspace() //ws -> Workspace

        print("Application Name: \(applicationName ?? "")\nFile Name: \(fileName ?? "")\nWorkspace: \(workspace ?? "")\n")

        // determine file type
        if applicationName == "Xcode", let fileName {
            presence.details = "Editing \(fileName)"
            if let fileExt = getFileExt(fileName), discordRPImageKeys.contains(fileExt) {
                presence.assets.largeImage = fileExt
                presence.assets.smallImage = discordRPImageKeyXcode
            } else {
                presence.assets.largeImage = discordRPImageKeyDefault
            }
        } else if let applicationName, xcodeWindowNames.contains(applicationName) {
            presence.details = "Using \(applicationName)"
            presence.assets.largeImage = applicationName.replacingOccurrences(of: "\\s", with: "", options: .regularExpression).lowercased()
            presence.assets.smallImage = discordRPImageKeyXcode
        }

        // determine workspace type
        if let workspace {
            if applicationName == "Xcode" {
                if workspace != "Untitled" {
                    presence.state = "in \(withoutFileExt(workspace))"
                    lastWindow = workspace
                }
            } else {
                presence.assets.smallImage = discordRPImageKeyXcode
                presence.assets.largeImage = discordRPImageKeyDefault
                presence.state = "Working on \(withoutFileExt(lastWindow ?? workspace))"
            }
        }

        // Xcode was just launched?
        if fileName == nil && workspace == nil {
            presence.assets.largeImage = discordRPImageKeyXcode
            presence.details = "No file open"
        }

        presence.timestamps.start = startDate ?? .init()
        presence.timestamps.end = nil
        rpc.setPresence(presence)
        print("updated RP")
    }

    private func addAllObservers() {
        // run on Xcode launch
        removeObservers()
        observers.append(
            notifCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: nil) { [weak self] notif in
                if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                    if app.bundleIdentifier == xcodeBundleId {
                        print("xcode launched, connecting...")
                        self?.connectRPC()
                    }
                }
            }
        )

        // run on Xcode close
        observers.append(
            notifCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: nil) { [weak self] notif in
                if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                    if app.bundleIdentifier == xcodeBundleId {
                        print("xcode closed, disconnecting...")
                        self?.disconnect()
                    }
                }
            }
        )

        if strictMode {
            observers.append(
                notifCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil) { [weak self] notif in
                    if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                        if app.bundleIdentifier == xcodeBundleId {
                            guard let `self` = self else { return }

                            // If it came from an inactive state
                            if let inactiveDate = self.inactiveDate {
                                // print(self.startDate, newDate)
                                // print(self.startDate!.distance(to: newDate!))
                                self.startDate = self.startDate?.addingTimeInterval(-inactiveDate.timeIntervalSinceNow)
                            } else {
                                self.startDate = Date()
                                self.inactiveDate = nil
                            }
                            // User can now start or stop XCord have to check if rpc is connected
                            self.updateStatus()
                        }
                    }
                }
            )

            observers.append(
                notifCenter.addObserver(forName: NSWorkspace.didDeactivateApplicationNotification, object: nil, queue: nil) { [weak self] notif in
                    if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                        if app.bundleIdentifier == xcodeBundleId {
                            guard let `self` = self else {
                                return
                            }
                            //Xcode is inactive (Not frontmost)
                            self.inactiveDate = Date()
                            self.updateStatus()
                        }
                    }
                }
            )
        }

        if !flauntMode {
            observers.append(
                notifCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: nil) { [weak self] notif in
                    if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                        if app.bundleIdentifier == xcodeBundleId {
                            //Xcode is going to become inactive (Sleep)
                            guard let `self` = self else { return }
                            self.inactiveDate = Date()
                            self.updateStatus()
                        }
                    }
                }
            )

            observers.append(
                notifCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { [weak self] notif in
                    if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                        if app.bundleIdentifier == xcodeBundleId {
                            guard let `self` = self else { return }
                            //Xcode woke up from sleep
                            if let inactiveDate = self.inactiveDate {
                                self.startDate = self.startDate?.addingTimeInterval(-inactiveDate.timeIntervalSinceNow)
                                // print(self.startDate, newDate)
                            }
                            self.updateStatus()
                        }
                    }
                }
            )
        }
    }

    func removeObservers() {
        for observer in self.observers {
            notifCenter.removeObserver(observer)
        }
        observers.removeAll()
    }
}

extension Connection: SwordRPCDelegate {
    func swordRPCDidConnect(_ rpc: SwordRPC) {
        startDate = Date()
        beginTimer()
    }

    func swordRPCDidDisconnect(_ rpc: SwordRPC, code: Int?, message msg: String?) {
        print("disconnected")
        clearTimer()
    }

    func swordRPCDidReceiveError(_ rpc: SwordRPC, code: Int, message msg: String) {}
}

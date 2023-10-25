//
//  ContentView.swift
//  XCord
//
//  Created by Asad Azam on 22/03/22.
//  Copyright © 2022 Asad Azam. All rights reserved.
//

import SwiftUI
import CoreData
import SwordRPC

struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                if let image = NSImage(named: "AppIcon") {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32)
                }
                Text("XCord")
                    .font(.title3.weight(.bold))
                Spacer()
                Toggle("", isOn: .init(get: { appDelegate.isXCordActive }, set: { appDelegate.setActive($0) }))
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            HStack {
                Text("Timer Strictness")
                Spacer()
                Picker("Timer Strictness", selection: $appDelegate.refreshConfigurable) {
                    ForEach(RefreshConfigurable.allCases, id: \.self) { config in
                        VStack {
                            Text(config.description)
                            Text(config.message)
                        }
                        .tag(config)
                        .help(config.message)
                    }
                }
                .fixedSize()
                .pickerStyle(.menu)
                .labelsHidden()
            }

            Button {
                NSApp.terminate(nil)
            } label: {
                Text("Quit XCord")
                    .padding(4)
                    .padding(.horizontal, 4)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.red.opacity(0.2))
                    }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .onChange(of: appDelegate.refreshConfigurable) { newValue in
            appDelegate.setTimerRefreshable(newValue)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDelegate())
}

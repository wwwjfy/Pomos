//
//  PomosApp.swift
//  Pomos
//
//  Created by Assistant on 2025-12-15.
//

import SwiftUI

@main
struct PomosApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

// We still need a minimal AppDelegate for specific macOS handling if needed,
// but for now, we can just let SwiftUI handle it. 
// However, the original project likely has an AppDelegate. 
// We are REPLACING the old AppDelegate. So we define a new plain one or just omit if not needed.
// But wait, the original `main.m` is going to be removed.
// `PomosApp` with `@main` will be the entry point.
// I added `AppDelegate` adapter just in case we need to handle activation policies or dock clicks that SwiftUI doesn't cover yet firmly in all versions, 
// but for a simple timer, we might not need it. 
// Let's keep it simple and remove the adapter if not defined.

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Any setup
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

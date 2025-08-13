//
//  StatsPanelManager.swift
//  DynamicIsland
//
//  Created by DynamicIsland App on 2024.
//

import AppKit
import SwiftUI

class StatsPanelManager: ObservableObject {
    static let shared = StatsPanelManager()
    
    private var statsPanel: StatsPanel?
    
    private init() {}
    
    func showStatsPanel() {
        hideStatsPanel() // Close any existing panel
        
        let panel = StatsPanel()
        panel.positionNearNotch()
        
        self.statsPanel = panel
        
        // Make the panel key and order front to ensure it can receive focus
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        
        // Activate the app to ensure proper focus handling
        NSApp.activate(ignoringOtherApps: true)
        
        // Ensure the panel becomes the key window for input
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            panel.makeKey()
        }
    }
    
    func hideStatsPanel() {
        statsPanel?.close()
        statsPanel = nil
    }
    
    func toggleStatsPanel() {
        if let panel = statsPanel, panel.isVisible {
            hideStatsPanel()
        } else {
            showStatsPanel()
        }
    }
    
    var isPanelVisible: Bool {
        return statsPanel?.isVisible ?? false
    }
}

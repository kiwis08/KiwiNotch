//
//  ClipboardManager.swift
//  DynamicIsland
//
//  Created by GitHub Copilot on 17/07/25.
//

import AppKit
import SwiftUI
import Combine
import Foundation

// Clipboard item data structure
struct ClipboardItem: Identifiable, Codable {
    let id = UUID()
    let content: String
    let type: ClipboardItemType
    let timestamp: Date
    let preview: String
    
    init(content: String, type: ClipboardItemType) {
        self.content = content
        self.type = type
        self.timestamp = Date()
        self.preview = ClipboardItem.generatePreview(content: content, type: type)
    }
    
    static func generatePreview(content: String, type: ClipboardItemType) -> String {
        switch type {
        case .text:
            return String(content.prefix(50))
        case .url:
            if let url = URL(string: content) {
                return url.lastPathComponent.isEmpty ? url.host ?? content : url.lastPathComponent
            }
            return String(content.prefix(50))
        case .file:
            if let url = URL(string: content) {
                return url.lastPathComponent
            }
            return "File"
        case .image:
            return "Image"
        case .rtf:
            // Remove RTF formatting for preview
            let stripped = content.replacingOccurrences(of: "\\[^\\s]*\\s?", with: "", options: .regularExpression)
            return String(stripped.prefix(50))
        case .unknown:
            return String(content.prefix(50))
        }
    }
}

enum ClipboardItemType: String, CaseIterable, Codable {
    case text = "text"
    case url = "url"
    case file = "file"
    case image = "image"
    case rtf = "rtf"
    case unknown = "unknown"
    
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .url: return "link"
        case .file: return "doc"
        case .image: return "photo"
        case .rtf: return "doc.richtext"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .url: return "URL"
        case .file: return "File"
        case .image: return "Image"
        case .rtf: return "Rich Text"
        case .unknown: return "Unknown"
        }
    }
}

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var clipboardHistory: [ClipboardItem] = []
    @Published var isMonitoring: Bool = false
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let maxHistoryItems = 3
    
    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
        loadHistoryFromDefaults()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
    }
    
    func deleteItem(_ item: ClipboardItem) {
        clipboardHistory.removeAll { $0.id == item.id }
        saveHistoryToDefaults()
    }
    
    func clearHistory() {
        clipboardHistory.removeAll()
        saveHistoryToDefaults()
    }
    
    // MARK: - Private Methods
    
    private func checkClipboard() {
        let currentChangeCount = NSPasteboard.general.changeCount
        
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        guard let clipboardItem = getCurrentClipboardItem() else { return }
        
        // Don't add duplicate items
        if !clipboardHistory.contains(where: { $0.content == clipboardItem.content && $0.type == clipboardItem.type }) {
            addToHistory(clipboardItem)
        }
    }
    
    private func getCurrentClipboardItem() -> ClipboardItem? {
        let pasteboard = NSPasteboard.general
        
        // Check for URL first
        if let url = pasteboard.string(forType: .URL) ?? pasteboard.string(forType: .fileURL) {
            return ClipboardItem(content: url, type: .url)
        }
        
        // Check for file URLs
        if let fileURLs = pasteboard.propertyList(forType: .fileURL) as? [String], !fileURLs.isEmpty {
            return ClipboardItem(content: fileURLs.first!, type: .file)
        }
        
        // Check for images
        if pasteboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.tiff.rawValue, NSPasteboard.PasteboardType.png.rawValue]) {
            return ClipboardItem(content: "Image data", type: .image)
        }
        
        // Check for RTF
        if let rtfData = pasteboard.data(forType: .rtf),
           let rtfString = NSAttributedString(rtf: rtfData, documentAttributes: nil)?.string {
            return ClipboardItem(content: rtfString, type: .rtf)
        }
        
        // Check for plain text
        if let string = pasteboard.string(forType: .string) {
            // Determine if it's a URL
            if string.hasPrefix("http://") || string.hasPrefix("https://") || string.hasPrefix("file://") {
                return ClipboardItem(content: string, type: .url)
            }
            return ClipboardItem(content: string, type: .text)
        }
        
        return nil
    }
    
    private func addToHistory(_ item: ClipboardItem) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Remove any existing items with the same content
            self.clipboardHistory.removeAll { $0.content == item.content }
            
            // Add to beginning of array
            self.clipboardHistory.insert(item, at: 0)
            
            // Keep only the most recent items
            if self.clipboardHistory.count > self.maxHistoryItems {
                self.clipboardHistory = Array(self.clipboardHistory.prefix(self.maxHistoryItems))
            }
            
            self.saveHistoryToDefaults()
        }
    }
    
    // MARK: - Persistence
    
    private func saveHistoryToDefaults() {
        if let encoded = try? JSONEncoder().encode(clipboardHistory) {
            UserDefaults.standard.set(encoded, forKey: "ClipboardHistory")
        }
    }
    
    private func loadHistoryFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: "ClipboardHistory"),
           let history = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            clipboardHistory = history
        }
    }
}

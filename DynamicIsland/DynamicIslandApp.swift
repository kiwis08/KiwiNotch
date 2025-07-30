//
//  DynamicIslandApp.swift
//  DynamicIslandApp
//
//  Created by Harsh Vardhan  Goswami  on 02/08/24.
//

import AVFoundation
import Combine
import Defaults
import KeyboardShortcuts
import Sparkle
import SwiftUI

@main
struct DynamicNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Default(.menubarIcon) var showMenuBarIcon
    @Environment(\.openWindow) var openWindow

    let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

        // Initialize the settings window controller with the updater controller
        SettingsWindowController.shared.setUpdaterController(updaterController)
    }

    var body: some Scene {
        MenuBarExtra("dynamic.island", systemImage: "sparkle", isInserted: $showMenuBarIcon) {
            Button("Settings") {
                SettingsWindowController.shared.showWindow()
            }
            .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
            if false {
                Button("Activate License") {
                    openWindow(id: "activation")
                }
            }
            CheckForUpdatesView(updater: updaterController.updater)
            Divider()
            Button("Restart Dynamic Island") {
                guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }

                let workspace = NSWorkspace.shared

                if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier)
                {

                    let configuration = NSWorkspace.OpenConfiguration()
                    configuration.createsNewApplicationInstance = true

                    workspace.openApplication(at: appURL, configuration: configuration)
                }

                NSApplication.shared.terminate(nil)
            }
            Button("Quit", role: .destructive) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut(KeyEquivalent("Q"), modifiers: .command)
        }

        Window("Activation", id: "activation") {
            ActivationWindow()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var windows: [NSScreen: NSWindow] = [:]
    var viewModels: [NSScreen: DynamicIslandViewModel] = [:]
    var window: NSWindow?
    let vm: DynamicIslandViewModel = .init()
    @ObservedObject var coordinator = DynamicIslandViewCoordinator.shared
    var whatsNewWindow: NSWindow?
    var timer: Timer?
    let calendarManager = CalendarManager()
    let webcamManager = WebcamManager.shared
    var closeNotchWorkItem: DispatchWorkItem?
    private var previousScreens: [NSScreen]?
    private var onboardingWindowController: NSWindowController?
    private var cancellables = Set<AnyCancellable>()

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func onScreenLocked(_: Notification) {
        print("Screen locked")
        cleanupWindows()
    }
    
    @objc func onScreenUnlocked(_: Notification) {
        print("Screen unlocked")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.cleanupWindows()
            self?.adjustWindowPosition(changeAlpha: true)
        }
    }
    
    private func cleanupWindows(shouldInvert: Bool = false) {
        if shouldInvert ? !Defaults[.showOnAllDisplays] : Defaults[.showOnAllDisplays] {
            for window in windows.values {
                window.close()
                NotchSpaceManager.shared.notchSpace.windows.remove(window)
            }
            windows.removeAll()
            viewModels.removeAll()
        } else if let window = window {
            window.close()
            NotchSpaceManager.shared.notchSpace.windows.remove(window)
            self.window = nil
        }
    }

    private func createDynamicIslandWindow(for screen: NSScreen, with viewModel: DynamicIslandViewModel)
        -> NSWindow
    {
        let window = DynamicIslandWindow(
            contentRect: NSRect(
                x: 0, y: 0, width: openNotchSize.width, height: openNotchSize.height),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = NSHostingView(
            rootView: ContentView()
                .environmentObject(viewModel)
                .environmentObject(webcamManager)
        )
        
        window.orderFrontRegardless()
        NotchSpaceManager.shared.notchSpace.windows.insert(window)
        return window
    }

    private func positionWindow(_ window: NSWindow, on screen: NSScreen, changeAlpha: Bool = false)
    {
        if changeAlpha {
            window.alphaValue = 0
        }
        
        DispatchQueue.main.async { [weak window] in
            guard let window = window else { return }
            let screenFrame = screen.frame
            window.setFrameOrigin(
                NSPoint(
                    x: screenFrame.origin.x + (screenFrame.width / 2) - window.frame.width / 2,
                    y: screenFrame.origin.y + screenFrame.height - window.frame.height
                ))
            window.alphaValue = 1
        }
    }
    
    private func updateWindowSizeIfNeeded() {
        // Calculate required size based on current state
        let requiredSize = calculateRequiredNotchSize()
        
        // Update all windows if size has changed
        for (screen, window) in windows {
            if window.frame.size != requiredSize {
                let screenFrame = screen.frame
                let newFrame = NSRect(
                    x: screenFrame.origin.x + (screenFrame.width / 2) - requiredSize.width / 2,
                    y: screenFrame.origin.y + screenFrame.height - requiredSize.height,
                    width: requiredSize.width,
                    height: requiredSize.height
                )
                
                // Animate the frame change for smooth transition
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    context.allowsImplicitAnimation = true
                    window.setFrame(newFrame, display: true, animate: true)
                }
            }
        }
    }
    
    private func calculateRequiredNotchSize() -> CGSize {
        // Only apply dynamic sizing when on stats tab and stats are enabled
        guard coordinator.currentView == .stats && Defaults[.enableStatsFeature] else {
            return openNotchSize
        }
        
        let enabledGraphsCount = [
            Defaults[.showCpuGraph],
            Defaults[.showMemoryGraph], 
            Defaults[.showGpuGraph],
            Defaults[.showNetworkGraph],
            Defaults[.showDiskGraph]
        ].filter { $0 }.count
        
        // If 4+ graphs are enabled, increase width
        if enabledGraphsCount >= 4 {
            let extraWidth: CGFloat = CGFloat(enabledGraphsCount - 3) * 120
            return CGSize(width: openNotchSize.width + extraWidth, height: openNotchSize.height)
        }
        
        return openNotchSize
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {

        coordinator.setupWorkersNotificationObservers()
        
        // Observe tab changes to update window size dynamically
        coordinator.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.updateWindowSizeIfNeeded()
            }
        }.store(in: &cancellables)
        
        // Observe stats settings changes
        Defaults.publisher(.enableStatsFeature, options: []).sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateWindowSizeIfNeeded()
            }
        }.store(in: &cancellables)
        
        Defaults.publisher(.showCpuGraph, options: []).sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateWindowSizeIfNeeded()
            }
        }.store(in: &cancellables)
        
        Defaults.publisher(.showMemoryGraph, options: []).sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateWindowSizeIfNeeded()
            }
        }.store(in: &cancellables)
        
        Defaults.publisher(.showGpuGraph, options: []).sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateWindowSizeIfNeeded()
            }
        }.store(in: &cancellables)
        
        Defaults.publisher(.showNetworkGraph, options: []).sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateWindowSizeIfNeeded()
            }
        }.store(in: &cancellables)
        
        Defaults.publisher(.showDiskGraph, options: []).sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateWindowSizeIfNeeded()
            }
        }.store(in: &cancellables)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            forName: Notification.Name.selectedScreenChanged, object: nil, queue: nil
        ) { [weak self] _ in
            self?.adjustWindowPosition(changeAlpha: true)
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name.notchHeightChanged, object: nil, queue: nil
        ) { [weak self] _ in
            self?.adjustWindowPosition()
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name.automaticallySwitchDisplayChanged, object: nil, queue: nil
        ) { [weak self] _ in
            guard let self = self, let window = self.window else { return }
            window.alphaValue =
                self.coordinator.selectedScreen == self.coordinator.preferredScreen ? 1 : 0
        }

        NotificationCenter.default.addObserver(
            forName: Notification.Name.showOnAllDisplaysChanged, object: nil, queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            self.cleanupWindows(shouldInvert: true)

            if !Defaults[.showOnAllDisplays] {
                let viewModel = self.vm
                let window = self.createDynamicIslandWindow(
                    for: NSScreen.main ?? NSScreen.screens.first!, with: viewModel)
                self.window = window
                self.adjustWindowPosition(changeAlpha: true)
            } else {
                self.adjustWindowPosition()
            }
        }

        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(onScreenLocked(_:)),
            name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"), object: nil)
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(onScreenUnlocked(_:)),
            name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"), object: nil)

        KeyboardShortcuts.onKeyDown(for: .toggleSneakPeek) { [weak self] in
            guard let self = self else { return }
            self.coordinator.toggleSneakPeek(
                status: !self.coordinator.sneakPeek.show,
                type: .music,
                duration: 3.0
            )
        }

        KeyboardShortcuts.onKeyDown(for: .toggleNotchOpen) { [weak self] in
            guard let self = self else { return }
            
            let mouseLocation = NSEvent.mouseLocation
            
            var viewModel = self.vm

            if Defaults[.showOnAllDisplays] {
                for screen in NSScreen.screens {
                    if screen.frame.contains(mouseLocation) {
                        if let screenViewModel = self.viewModels[screen] {
                            viewModel = screenViewModel
                            break
                        }
                    }
                }
            }
            
            self.closeNotchWorkItem?.cancel()
            self.closeNotchWorkItem = nil
            
            switch viewModel.notchState {
            case .closed:
                viewModel.open()
                
                let workItem = DispatchWorkItem { [weak viewModel] in
                    viewModel?.close()
                }
                self.closeNotchWorkItem = workItem
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
            case .open:
                viewModel.close()
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .startDemoTimer) { [weak self] in
            guard let self = self else { return }
            // Start a 5-minute demo timer
            TimerManager.shared.startDemoTimer(duration: 300)
        }
        
        KeyboardShortcuts.onKeyDown(for: .clipboardHistoryPanel) { [weak self] in
            guard let self = self else { return }
            
            // Only open clipboard if the feature is enabled
            guard Defaults[.enableClipboardManager] else { return }
            
            // Find the appropriate view model based on mouse location
            let mouseLocation = NSEvent.mouseLocation
            var viewModel = self.vm
            
            if Defaults[.showOnAllDisplays] {
                for screen in NSScreen.screens {
                    if screen.frame.contains(mouseLocation) {
                        if let screenViewModel = self.viewModels[screen] {
                            viewModel = screenViewModel
                            break
                        }
                    }
                }
            }
            
            // Open the notch if it's closed
            if viewModel.notchState == .closed {
                viewModel.open()
                
                // Wait a bit for the notch to open before toggling clipboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.coordinator.toggleClipboardPopover()
                }
            } else {
                // If notch is already open, toggle immediately
                self.coordinator.toggleClipboardPopover()
            }
            
            // Start clipboard monitoring if not already running
            if !ClipboardManager.shared.isMonitoring {
                ClipboardManager.shared.startMonitoring()
            }
        }
        
        if !Defaults[.showOnAllDisplays] {
            let viewModel = self.vm
            let window = createDynamicIslandWindow(
                for: NSScreen.main ?? NSScreen.screens.first!, with: viewModel)
            self.window = window
            adjustWindowPosition(changeAlpha: true)
        } else {
            adjustWindowPosition(changeAlpha: true)
        }
        
        if coordinator.firstLaunch {
            DispatchQueue.main.async {
                self.showOnboardingWindow()
            }
            playWelcomeSound()
        }
        
        previousScreens = NSScreen.screens
    }
    
    func playWelcomeSound() {
        let audioPlayer = AudioPlayer()
        audioPlayer.play(fileName: "dynamic", fileExtension: "m4a")
    }
    
    func deviceHasNotch() -> Bool {
        if #available(macOS 12.0, *) {
            for screen in NSScreen.screens {
                if screen.safeAreaInsets.top > 0 {
                    return true
                }
            }
        }
        return false
    }
    
    @objc func screenConfigurationDidChange() {
        let currentScreens = NSScreen.screens

        let screensChanged =
            currentScreens.count != previousScreens?.count
            || Set(currentScreens.map { $0.localizedName })
                != Set(previousScreens?.map { $0.localizedName } ?? [])
            || Set(currentScreens.map { $0.frame }) != Set(previousScreens?.map { $0.frame } ?? [])

        previousScreens = currentScreens
        
        if screensChanged {
            DispatchQueue.main.async { [weak self] in
                self?.cleanupWindows()
                self?.adjustWindowPosition()
            }
        }
    }
    
    @objc func adjustWindowPosition(changeAlpha: Bool = false) {
        if Defaults[.showOnAllDisplays] {
            let currentScreens = Set(NSScreen.screens)
            
            for screen in windows.keys where !currentScreens.contains(screen) {
                if let window = windows[screen] {
                    window.close()
                    NotchSpaceManager.shared.notchSpace.windows.remove(window)
                    windows.removeValue(forKey: screen)
                    viewModels.removeValue(forKey: screen)
                }
            }
            
            for screen in currentScreens {
                if windows[screen] == nil {
                    let viewModel = DynamicIslandViewModel(screen: screen.localizedName)
                    let window = createDynamicIslandWindow(for: screen, with: viewModel)
                    
                    windows[screen] = window
                    viewModels[screen] = viewModel
                }
                
                if let window = windows[screen], let viewModel = viewModels[screen] {
                    positionWindow(window, on: screen, changeAlpha: changeAlpha)
                    
                    if viewModel.notchState == .closed {
                        viewModel.close()
                    }
                }
            }
        } else {
            let selectedScreen: NSScreen

            if let preferredScreen = NSScreen.screens.first(where: {
                $0.localizedName == coordinator.preferredScreen
            }) {
                coordinator.selectedScreen = coordinator.preferredScreen
                selectedScreen = preferredScreen
            } else if Defaults[.automaticallySwitchDisplay], let mainScreen = NSScreen.main {
                coordinator.selectedScreen = mainScreen.localizedName
                selectedScreen = mainScreen
            } else {
                if let window = window {
                    window.alphaValue = 0
                }
                return
            }
            
            vm.screen = selectedScreen.localizedName
            vm.notchSize = getClosedNotchSize(screen: selectedScreen.localizedName)
            
            if window == nil {
                window = createDynamicIslandWindow(for: selectedScreen, with: vm)
            }
            
            if let window = window {
                positionWindow(window, on: selectedScreen, changeAlpha: changeAlpha)
                
                if vm.notchState == .closed {
                    vm.close()
                }
            }
        }
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if window?.isVisible == true {
            window?.orderOut(nil)
        } else {
            window?.orderFrontRegardless()
        }
    }
    
    @objc func showMenu() {
        statusItem?.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
    
    @objc func quitAction() {
        NSApplication.shared.terminate(nil)
    }

    private func showOnboardingWindow() {
        if onboardingWindowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
                styleMask: [.titled, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Onboarding"
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.contentView = NSHostingView(rootView: OnboardingView(
                onFinish: {
                    window.orderOut(nil)
                    NSApp.setActivationPolicy(.accessory)
                    window.close()
                    NSApp.deactivate()
                },
                onOpenSettings: {
                    window.close()
                    SettingsWindowController.shared.showWindow()
                }
            ))
            window.isRestorable = false
            window.identifier = NSUserInterfaceItemIdentifier("OnboardingWindow")

            onboardingWindowController = NSWindowController(window: window)
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindowController?.window?.makeKeyAndOrderFront(nil)
        onboardingWindowController?.window?.orderFrontRegardless()
    }
}

extension Notification.Name {
    static let selectedScreenChanged = Notification.Name("SelectedScreenChanged")
    static let notchHeightChanged = Notification.Name("NotchHeightChanged")
    static let showOnAllDisplaysChanged = Notification.Name("showOnAllDisplaysChanged")
    static let automaticallySwitchDisplayChanged = Notification.Name("automaticallySwitchDisplayChanged")
}

extension CGRect: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin.x)
        hasher.combine(origin.y)
        hasher.combine(size.width)
        hasher.combine(size.height)
    }

    public static func == (lhs: CGRect, rhs: CGRect) -> Bool {
        return lhs.origin == rhs.origin && lhs.size == rhs.size
    }
}

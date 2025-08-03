//
//  NotchHomeView.swift
//  DynamicIsland
//
//  Created by Hugo Persson on 2024-08-18.
//  Modified by Harsh Vardhan Goswami & Richard Kunkli & Mustafa Ramadan
//

import Combine
import Defaults
import SwiftUI

// MARK: - Music Player Components

struct MusicPlayerView: View {
    @EnvironmentObject var vm: DynamicIslandViewModel
    let albumArtNamespace: Namespace.ID

    var body: some View {
        HStack {
            AlbumArtView(vm: vm, albumArtNamespace: albumArtNamespace)
            MusicControlsView().drawingGroup().compositingGroup()
        }
    }
}

struct AlbumArtView: View {
    @ObservedObject var musicManager = MusicManager.shared
    @ObservedObject var vm: DynamicIslandViewModel
    let albumArtNamespace: Namespace.ID

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if Defaults[.lightingEffect] {
                albumArtBackground
            }
            albumArtButton
        }
    }

    private var albumArtBackground: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .background(
                Image(nsImage: musicManager.albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: Defaults[.cornerRadiusScaling] ? MusicPlayerImageSizes.cornerRadiusInset.opened : MusicPlayerImageSizes.cornerRadiusInset.closed))
            .scaleEffect(x: 1.3, y: 1.4)
            .rotationEffect(.degrees(92))
            .blur(radius: 35)
            .opacity(min(0.6, 1 - max(musicManager.albumArt.getBrightness(), 0.3)))
    }

    private var albumArtButton: some View {
        Button {
            musicManager.openMusicApp()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                albumArtImage
                appIconOverlay
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(musicManager.isPlaying ? 1 : 0.4)
        .scaleEffect(musicManager.isPlaying ? 1 : 0.85)
    }

    private var albumArtImage: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .background(
                Image(nsImage: musicManager.albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: musicManager.isFlipping)
            )
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: Defaults[.cornerRadiusScaling] ? MusicPlayerImageSizes.cornerRadiusInset.opened : MusicPlayerImageSizes.cornerRadiusInset.closed))
            .matchedGeometryEffect(id: "albumArt", in: albumArtNamespace)
    }

    @ViewBuilder
    private var appIconOverlay: some View {
        if vm.notchState == .open && !musicManager.usingAppIconForArtwork {
            AppIcon(for: musicManager.bundleIdentifier ?? "com.apple.Music")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 30, height: 30)
                .offset(x: 10, y: 10)
                .transition(.scale.combined(with: .opacity).animation(.bouncy.delay(0.3)))
        }
    }
}

struct MusicControlsView: View {
    @ObservedObject var musicManager = MusicManager.shared
    @EnvironmentObject var vm: DynamicIslandViewModel
    @State private var sliderValue: Double = 0
    @State private var dragging: Bool = false
    @State private var lastDragged: Date = .distantPast
    
    var body: some View {
        VStack(alignment: .leading) {
            songInfoAndSlider
            playbackControls
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minWidth: Defaults[.showMirror] && Defaults[.showCalendar] ? 140 : 180)
        .onAppear {
            // Initialize slider value when view appears
            sliderValue = musicManager.elapsedTime
        }
        .onChange(of: vm.notchState) { _, newState in
            // Reset slider value when notch opens to prevent stuck state
            if newState == .open && !dragging {
                sliderValue = musicManager.elapsedTime
            }
        }
    }

    private var songInfoAndSlider: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 4) {
                songInfo(width: geo.size.width)
                musicSlider
            }
        }
        .padding(.top, 10)
        .padding(.leading, 5)
    }

    private func songInfo(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            MarqueeText($musicManager.songTitle, font: .headline, nsFont: .headline, textColor: .white, frameWidth: width)
            MarqueeText(
                $musicManager.artistName,
                font: .headline,
                nsFont: .headline,
                textColor: Defaults[.playerColorTinting] ? Color(nsColor: musicManager.avgColor)
                    .ensureMinimumBrightness(factor: 0.6) : .gray,
                frameWidth: width
            )
            .fontWeight(.medium)
        }
    }

    private var musicSlider: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            MusicSliderView(
                sliderValue: $sliderValue,
                duration: $musicManager.songDuration,
                lastDragged: $lastDragged,
                color: musicManager.avgColor,
                dragging: $dragging,
                currentDate: timeline.date,
                lastUpdated: musicManager.lastUpdated,
                ignoreLastUpdated: musicManager.ignoreLastUpdated,
                timestampDate: musicManager.timestampDate,
                elapsedTime: musicManager.elapsedTime,
                playbackRate: musicManager.playbackRate,
                isPlaying: musicManager.isPlaying
            ) { newValue in
                MusicManager.shared.seek(to: newValue)
            }
            .padding(.top, 5)
            .frame(height: 36)
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 8) {
            if Defaults[.showShuffleAndRepeat] {
                HoverButton(icon: "shuffle", iconColor: musicManager.isShuffled ? .red : .white, scale: .medium) {
                    Task {
                        await MusicManager.shared.toggleShuffle()
                    }
                }
            }
            HoverButton(icon: "backward.fill", scale: .medium) {
                Task {
                    await MusicManager.shared.previousTrack()
                }
            }
            HoverButton(icon: musicManager.isPlaying ? "pause.fill" : "play.fill", scale: .large) {
                Task {
                    await MusicManager.shared.togglePlay()
                }
            }
            HoverButton(icon: "forward.fill", scale: .medium) {
                Task {
                    await MusicManager.shared.nextTrack()
                }
            }
            if Defaults[.showShuffleAndRepeat] {
                HoverButton(icon: repeatIcon, iconColor: repeatIconColor, scale: .medium) {
                    Task {
                        await MusicManager.shared.toggleRepeat()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var repeatIcon: String {
        switch musicManager.repeatMode {
        case .off:
            return "repeat"
        case .all:
            return "repeat"
        case .one:
            return "repeat.1"
        }
    }

    private var repeatIconColor: Color {
        switch musicManager.repeatMode {
        case .off:
            return .white
        case .all, .one:
            return .red
        }
    }
}

// MARK: - Main View

struct NotchHomeView: View {
    @EnvironmentObject var vm: DynamicIslandViewModel
    @ObservedObject var webcamManager = WebcamManager.shared
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared
    @ObservedObject var coordinator = DynamicIslandViewCoordinator.shared
    let albumArtNamespace: Namespace.ID
    
    var body: some View {
        Group {
            if !coordinator.firstLaunch {
                mainContent
            }
        }
        .transition(.opacity.combined(with: .blurReplace))
    }

    private var mainContent: some View {
        HStack(alignment: .top, spacing: 20) {
            MusicPlayerView(albumArtNamespace: albumArtNamespace)
            
            if Defaults[.showCalendar] {
                CalendarView()
                    .onHover { isHovering in
                        vm.isHoveringCalendar = isHovering
                    }
                    .environmentObject(vm)
            }
            
            if Defaults[.showMirror],
               webcamManager.cameraAvailable,
               vm.notchState == .open {
                CameraPreviewView(webcamManager: webcamManager)
                    .scaledToFit()
                    .opacity(vm.notchState == .closed ? 0 : 1)
                    .blur(radius: vm.notchState == .closed ? 20 : 0)
            }
        }
        .transition(.opacity.animation(.smooth.speed(0.9))
            .combined(with: .blurReplace.animation(.smooth.speed(0.9)))
            .combined(with: .move(edge: .top)))
        .blur(radius: vm.notchState == .closed ? 30 : 0)
    }
}

struct MusicSliderView: View {
    @Binding var sliderValue: Double
    @Binding var duration: Double
    @Binding var lastDragged: Date
    var color: NSColor
    @Binding var dragging: Bool
    let currentDate: Date
    let lastUpdated: Date
    let ignoreLastUpdated: Bool
    let timestampDate: Date
    let elapsedTime: Double
    let playbackRate: Double
    let isPlaying: Bool
    var onValueChange: (Double) -> Void

    var currentElapsedTime: Double {
        // Don't update slider while user is dragging
        guard !dragging else { return sliderValue }
        
        // If not playing, use the current elapsed time from controller
        guard isPlaying else { return elapsedTime }
        
        // For playing media, calculate real-time progress
        let timeDiff = currentDate.timeIntervalSince(timestampDate)
        
        // Use real-time calculation for positive time differences with reasonable bounds
        // This provides smooth progression for all media sources
        if timeDiff >= 0 && timeDiff < 30.0 && playbackRate > 0 {
            let projectedTime = elapsedTime + (timeDiff * playbackRate)
            let clampedTime = min(projectedTime, duration)
            
            // Ensure we don't go backwards unless there's a significant jump
            if clampedTime >= sliderValue || abs(clampedTime - sliderValue) > 2.0 {
                return clampedTime
            } else {
                return sliderValue
            }
        } else {
            // For very stale timestamps or negative differences, use controller time
            // but only if it makes sense relative to current slider position
            let controllerTime = min(elapsedTime, duration)
            
            // Prevent backwards jumps unless there's a significant change (track change, seek)
            if controllerTime >= sliderValue || abs(controllerTime - sliderValue) > 5.0 {
                return controllerTime
            } else {
                return sliderValue
            }
        }
    }

    var body: some View {
        VStack {
            CustomSlider(
                value: $sliderValue,
                range: 0 ... duration,
                color: Defaults[.sliderColor] == SliderColorEnum.albumArt ? Color(
                    nsColor: color
                ).ensureMinimumBrightness(factor: 0.8) : Defaults[.sliderColor] == SliderColorEnum.accent ? .accentColor : .white,
                dragging: $dragging,
                lastDragged: $lastDragged,
                onValueChange: onValueChange
            )
            .frame(height: 10, alignment: .center)
            HStack {
                Text(timeString(from: sliderValue))
                Spacer()
                Text(timeString(from: duration))
            }
            .fontWeight(.medium)
            .foregroundColor(Defaults[.playerColorTinting] ? Color(nsColor: color)
                .ensureMinimumBrightness(factor: 0.6) : .gray)
            .font(.caption)
        }
        .onChange(of: currentDate) {
            sliderValue = currentElapsedTime
        }
        .onChange(of: elapsedTime) {
            // Update slider when media changes (e.g., track changes, seeking)
            // But only if we're not dragging and the difference is significant
            if !dragging && abs(elapsedTime - sliderValue) > 1.0 {
                sliderValue = elapsedTime
            }
        }
        .onChange(of: duration) {
            // Handle track changes - reset slider if duration changes significantly
            if !dragging && sliderValue > duration {
                sliderValue = min(elapsedTime, duration)
            }
        }
    }

    func timeString(from seconds: Double) -> String {
        let totalMinutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var color: Color = .white
    @Binding var dragging: Bool
    @Binding var lastDragged: Date
    var onValueChange: ((Double) -> Void)?
    var thumbSize: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = CGFloat(dragging ? 9 : 5)
            let rangeSpan = range.upperBound - range.lowerBound

            let filledTrackWidth = min(rangeSpan == .zero ? 0 : ((value - range.lowerBound) / rangeSpan) * width, width)

            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: height)

                // Filled track
                Rectangle()
                    .fill(color)
                    .frame(width: filledTrackWidth, height: height)
            }
            .cornerRadius(height / 2)
            .frame(height: 10)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        withAnimation {
                            dragging = true
                        }
                        let newValue = range.lowerBound + Double(gesture.location.x / width) * rangeSpan
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        onValueChange?(value)
                        dragging = false
                        lastDragged = Date()
                    }
            )
            .animation(.bouncy.speed(1.4), value: dragging)
        }
    }
}

#Preview {
    NotchHomeView(
        albumArtNamespace: Namespace().wrappedValue
    )
    .environmentObject(DynamicIslandViewModel())
}

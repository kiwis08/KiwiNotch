//
//  NotchTimerView.swift
//  DynamicIsland
//
//  Timer tab interface for the Dynamic Island
//

import SwiftUI
import Defaults

struct NotchTimerView: View {
    @EnvironmentObject var vm: DynamicIslandViewModel
    @ObservedObject var timerManager = TimerManager.shared
    @ObservedObject var coordinator = DynamicIslandViewCoordinator.shared
    
    var body: some View {
        HStack(alignment: .center, spacing: 32) {
            // Timer Progress and Controls
            timerProgressSection
            
            // Timer Control Panel
            controlsSection
        }
        .padding(.horizontal, 20)
        .transition(.opacity.combined(with: .blurReplace))
    }
    
    private var timerProgressSection: some View {
        VStack(spacing: 16) {
            // Circular progress display
            ZStack {
                // Background ring
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        timerManager.currentColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: timerManager.progress)
                
                // Timer icon in center
                Image(systemName: "timer")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(timerManager.currentColor)
                    .scaleEffect(timerManager.isRunning ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: timerManager.isRunning)
            }
            
            // Time display
            VStack(spacing: 4) {
                Text(timerManager.formattedTimeRemaining)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(timerManager.isOvertime ? .red : .white)
                
                if timerManager.isTimerActive && timerManager.isPaused {
                    Text("Paused")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: 20) {
            if timerManager.isTimerActive {
                // Active timer controls
                activeTimerControls
            } else {
                // Quick timer setup
                quickTimerControls
            }
        }
    }
    
    private var activeTimerControls: some View {
        VStack(spacing: 16) {
            if timerManager.isOvertime {
                // Overtime controls - only show stop button
                Button(action: {
                    timerManager.forceStopTimer()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.red)
                        Text("Stop")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.red)
                    }
                    .frame(height: 40)
                    .frame(minWidth: 100)
                    .background(.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { isHovering in
                    if isHovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            } else {
                // Normal timer controls
                HStack(spacing: 16) {
                    // Pause/Resume button
                    Button(action: {
                        if timerManager.isPaused {
                            timerManager.resumeTimer()
                        } else {
                            timerManager.pauseTimer()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text(timerManager.isPaused ? "Resume" : "Pause")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .frame(height: 40)
                        .frame(minWidth: 100)
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { isHovering in
                        if isHovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    
                    // Stop button
                    Button(action: {
                        timerManager.stopTimer()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Stop")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .frame(height: 40)
                        .frame(minWidth: 100)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { isHovering in
                        if isHovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
            }
        }
    }
    
    private var quickTimerControls: some View {
        VStack(spacing: 16) {
            // Quick timer grid
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    quickTimerButton(minutes: 1, title: "1 min")
                    quickTimerButton(minutes: 5, title: "5 min")
                    quickTimerButton(minutes: 15, title: "15 min")
                }
                
                // Demo timer
                Button(action: {
                    timerManager.startDemoTimer(duration: 10) // 10 second demo
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "flask")
                            .font(.system(size: 14, weight: .medium))
                        Text("Demo (10s)")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(height: 40)
                    .frame(minWidth: 120)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { isHovering in
                    if isHovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
    }
    
    private func quickTimerButton(minutes: Int, title: String) -> some View {
        Button(action: {
            timerManager.startDemoTimer(duration: TimeInterval(minutes * 60))
        }) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("min")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, height: 60)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    NotchTimerView()
        .environmentObject(DynamicIslandViewModel())
        .frame(width: 500, height: 200)
        .background(.black)
}

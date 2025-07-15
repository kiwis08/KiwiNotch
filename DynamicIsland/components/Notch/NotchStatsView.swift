//
//  NotchStatsView.swift
//  DynamicIsland
//
//  Stats tab view for system performance monitoring
//

import SwiftUI
import Defaults

struct NotchStatsView: View {
    @ObservedObject var statsManager = StatsManager.shared
    @Default(.enableStatsFeature) var enableStatsFeature
    
    var body: some View {
        VStack(spacing: 0) {
            if !enableStatsFeature {
                // Disabled state
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Stats Disabled")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Enable stats monitoring in Settings to view system performance data.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Stats content - use full width and height
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 12) {
                        // Stats Grid - use more space
                        HStack(spacing: 12) {
                            // CPU Usage
                            StatCard(
                                title: "CPU",
                                value: statsManager.cpuUsageString,
                                data: statsManager.cpuHistory,
                                color: .blue,
                                icon: "cpu"
                            )
                            
                            // Memory Usage
                            StatCard(
                                title: "Memory",
                                value: statsManager.memoryUsageString,
                                data: statsManager.memoryHistory,
                                color: .green,
                                icon: "memorychip"
                            )
                            
                            // GPU Usage
                            StatCard(
                                title: "GPU",
                                value: statsManager.gpuUsageString,
                                data: statsManager.gpuHistory,
                                color: .purple,
                                icon: "display"
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(16)
                    
                    // Live indicator and controls in top-right corner
                    HStack(spacing: 8) {
                        // Control buttons
                        HStack(spacing: 4) {
                            if statsManager.isMonitoring {
                                Button("Stop") {
                                    statsManager.stopMonitoring()
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                                .controlSize(.mini)
                            } else {
                                Button("Start") {
                                    statsManager.startMonitoring()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.mini)
                            }
                            
                            Button("Clear") {
                                clearStatsData()
                            }
                            .buttonStyle(.bordered)
                            .disabled(statsManager.isMonitoring)
                            .controlSize(.mini)
                        }
                        .font(.caption2)
                        
                        // Live indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(statsManager.isMonitoring ? .green : .red)
                                .frame(width: 6, height: 6)
                            
                            Text(statsManager.isMonitoring ? "Live" : "Off")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            if enableStatsFeature && !statsManager.isMonitoring {
                statsManager.startMonitoring()
            }
        }
        .onDisappear {
            // Keep monitoring running when tab is not visible
        }
    }
    
    private func clearStatsData() {
        statsManager.cpuHistory = Array(repeating: 0.0, count: 30)
        statsManager.memoryHistory = Array(repeating: 0.0, count: 30)
        statsManager.gpuHistory = Array(repeating: 0.0, count: 30)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let data: [Double]
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            // Header - more compact
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption2)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Current value - larger and more prominent
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Mini graph - use more height
            MiniGraph(data: data, color: color)
                .frame(height: 50)
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MiniGraph: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 1.0
            let normalizedData = maxValue > 0 ? data.map { $0 / maxValue } : data
            
            Path { path in
                guard !normalizedData.isEmpty else { return }
                
                let stepX = geometry.size.width / CGFloat(normalizedData.count - 1)
                
                for (index, value) in normalizedData.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height * (1 - CGFloat(value))
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: 2)
            
            // Gradient fill
            Path { path in
                guard !normalizedData.isEmpty else { return }
                
                let stepX = geometry.size.width / CGFloat(normalizedData.count - 1)
                
                path.move(to: CGPoint(x: 0, y: geometry.size.height))
                
                for (index, value) in normalizedData.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height * (1 - CGFloat(value))
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

#Preview {
    NotchStatsView()
        .frame(width: 400, height: 300)
        .background(Color.black)
}

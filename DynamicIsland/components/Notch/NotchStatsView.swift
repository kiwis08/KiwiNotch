//
//  NotchStatsView.swift
//  DynamicIsland
//
//  Stats tab view for system performance monitoring
// Created by Hariharan Mudaliar

import SwiftUI
import Defaults

// Graph data protocol for unified interface
protocol GraphData {
    var title: String { get }
    var color: Color { get }
    var icon: String { get }
    var type: GraphType { get }
}

enum GraphType {
    case single
    case dual
}

// Single value graph data
struct SingleGraphData: GraphData {
    let title: String
    let value: String
    let data: [Double]
    let color: Color
    let icon: String
    let type: GraphType = .single
}

// Dual value graph data (for network/disk)
struct DualGraphData: GraphData {
    let title: String
    let positiveValue: String
    let negativeValue: String
    let positiveData: [Double]
    let negativeData: [Double]
    let positiveColor: Color
    let negativeColor: Color
    let color: Color // Primary color for the component
    let icon: String
    let type: GraphType = .dual
}

struct NotchStatsView: View {
    @ObservedObject var statsManager = StatsManager.shared
    @Default(.enableStatsFeature) var enableStatsFeature
    @Default(.showCpuGraph) var showCpuGraph
    @Default(.showMemoryGraph) var showMemoryGraph
    @Default(.showGpuGraph) var showGpuGraph
    @Default(.showNetworkGraph) var showNetworkGraph
    @Default(.showDiskGraph) var showDiskGraph
    
    var availableGraphs: [GraphData] {
        var graphs: [GraphData] = []
        
        if showCpuGraph {
            graphs.append(SingleGraphData(
                title: "CPU",
                value: statsManager.cpuUsageString,
                data: statsManager.cpuHistory,
                color: .blue,
                icon: "cpu"
            ))
        }
        
        if showMemoryGraph {
            graphs.append(SingleGraphData(
                title: "Memory",
                value: statsManager.memoryUsageString,
                data: statsManager.memoryHistory,
                color: .green,
                icon: "memorychip"
            ))
        }
        
        if showGpuGraph {
            graphs.append(SingleGraphData(
                title: "GPU",
                value: statsManager.gpuUsageString,
                data: statsManager.gpuHistory,
                color: .purple,
                icon: "display"
            ))
        }
        
        if showNetworkGraph {
            graphs.append(DualGraphData(
                title: "Network",
                positiveValue: String(format: "↓%.1f MB/s", statsManager.networkDownload),
                negativeValue: String(format: "↑%.1f MB/s", statsManager.networkUpload),
                positiveData: statsManager.networkDownloadHistory,
                negativeData: statsManager.networkUploadHistory,
                positiveColor: .orange,
                negativeColor: .red,
                color: .orange,
                icon: "network"
            ))
        }
        
        if showDiskGraph {
            graphs.append(DualGraphData(
                title: "Disk",
                positiveValue: String(format: "R %.1f MB/s", statsManager.diskRead),
                negativeValue: String(format: "W %.1f MB/s", statsManager.diskWrite),
                positiveData: statsManager.diskReadHistory,
                negativeData: statsManager.diskWriteHistory,
                positiveColor: .cyan,
                negativeColor: .yellow,
                color: .cyan,
                icon: "internaldrive"
            ))
        }
        
        return graphs
    }
    
    // Simplified and more consistent layout system
    @ViewBuilder
    var statsGridLayout: some View {
        let graphCount = availableGraphs.count
        
        // Use LazyVGrid for all cases - more predictable layout behavior
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(graphCount, 3)),
            spacing: 12
        ) {
            ForEach(0..<graphCount, id: \.self) { index in
                UnifiedStatsCard(graphData: availableGraphs[index])
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).animation(.easeInOut(duration: 0.4)),
                        removal: .scale.combined(with: .opacity).animation(.easeInOut(duration: 0.4))
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: graphCount)
    }
    
    // Helper function to create graph views using unified component
    @ViewBuilder
    func graphView(for graphData: GraphData) -> some View {
        UnifiedStatsCard(graphData: graphData)
    }

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
            } else if availableGraphs.isEmpty {
                // No graphs enabled state
                VStack(spacing: 12) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No Graphs Enabled")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Enable graph visibility in Settings → Stats to view performance data.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Stats content with improved animation coordination
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 12) {
                        // Simplified consistent layout
                        statsGridLayout
                    }
                    .padding(16)
                    .animation(.easeInOut(duration: 0.4), value: availableGraphs.count)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).animation(.easeInOut(duration: 0.4)),
                        removal: .scale.combined(with: .opacity).animation(.easeInOut(duration: 0.4))
                    ))
                    
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
                                statsManager.clearHistory()
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
        .animation(.easeInOut(duration: 0.4), value: enableStatsFeature)
        .animation(.easeInOut(duration: 0.4), value: availableGraphs.count)
    }
}

// Unified Stats Card Component - handles both single and dual data types
struct UnifiedStatsCard: View {
    let graphData: GraphData
    
    var body: some View {
        VStack(spacing: 6) {
            // Header - consistent across all card types
            HStack(spacing: 4) {
                Image(systemName: graphData.icon)
                    .foregroundColor(graphData.color)
                    .font(.caption2)
                
                Text(graphData.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Values section - adapts based on graph type
            Group {
                if let singleData = graphData as? SingleGraphData {
                    Text(singleData.value)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                } else if let dualData = graphData as? DualGraphData {
                    HStack(spacing: 6) {
                        Text(dualData.positiveValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(dualData.positiveColor)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(dualData.negativeValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(dualData.negativeColor)
                    }
                }
            }
            .frame(height: 22) // Fixed height for consistent card sizing
            
            // Graph section - adapts based on graph type
            Group {
                if let singleData = graphData as? SingleGraphData {
                    MiniGraph(data: singleData.data, color: singleData.color)
                } else if let dualData = graphData as? DualGraphData {
                    DualQuadrantGraph(
                        positiveData: dualData.positiveData,
                        negativeData: dualData.negativeData,
                        positiveColor: dualData.positiveColor,
                        negativeColor: dualData.negativeColor
                    )
                }
            }
            .frame(height: 50) // Fixed height for consistent card sizing
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

struct DualQuadrantGraph: View {
    let positiveData: [Double]
    let negativeData: [Double]
    let positiveColor: Color
    let negativeColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            let maxPositive = positiveData.max() ?? 1.0
            let maxNegative = negativeData.max() ?? 1.0
            let maxValue = max(maxPositive, maxNegative)
            
            let normalizedPositive = maxValue > 0 ? positiveData.map { $0 / maxValue } : positiveData
            let normalizedNegative = maxValue > 0 ? negativeData.map { $0 / maxValue } : negativeData
            
            let centerY = geometry.size.height / 2
            
            ZStack {
                // Center dividing line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: centerY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: centerY))
                }
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                
                // Positive quadrant (upper half)
                Path { path in
                    guard !normalizedPositive.isEmpty else { return }
                    
                    let stepX = geometry.size.width / CGFloat(normalizedPositive.count - 1)
                    
                    for (index, value) in normalizedPositive.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = centerY - (centerY * CGFloat(value)) // Above center
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(positiveColor, lineWidth: 2)
                
                // Positive fill
                Path { path in
                    guard !normalizedPositive.isEmpty else { return }
                    
                    let stepX = geometry.size.width / CGFloat(normalizedPositive.count - 1)
                    
                    path.move(to: CGPoint(x: 0, y: centerY))
                    
                    for (index, value) in normalizedPositive.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = centerY - (centerY * CGFloat(value))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: geometry.size.width, y: centerY))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [positiveColor.opacity(0.3), positiveColor.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                
                // Negative quadrant (lower half)
                Path { path in
                    guard !normalizedNegative.isEmpty else { return }
                    
                    let stepX = geometry.size.width / CGFloat(normalizedNegative.count - 1)
                    
                    for (index, value) in normalizedNegative.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = centerY + (centerY * CGFloat(value)) // Below center
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(negativeColor, lineWidth: 2)
                
                // Negative fill
                Path { path in
                    guard !normalizedNegative.isEmpty else { return }
                    
                    let stepX = geometry.size.width / CGFloat(normalizedNegative.count - 1)
                    
                    path.move(to: CGPoint(x: 0, y: centerY))
                    
                    for (index, value) in normalizedNegative.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = centerY + (centerY * CGFloat(value))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: geometry.size.width, y: centerY))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [negativeColor.opacity(0.3), negativeColor.opacity(0.1)]),
                        startPoint: .bottom,
                        endPoint: .center
                    )
                )
            }
        }
    }
}

#Preview {
    NotchStatsView()
        .frame(width: 400, height: 300)
        .background(Color.black)
}

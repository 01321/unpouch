import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var selectedDataPoint: (date: Date, count: Int, mg: Int)? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Period Selector
                Picker("period", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases) { period in
                        Text(period.localizableKey).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Chart
                if #available(iOS 16.0, *) {
                    let stats = dataStore.getStatsForPeriod(selectedPeriod)
                    
                    Chart(stats, id: \.date) { point in
                        LineMark(
                            x: .value("date", point.date),
                            y: .value("count", point.count)
                        )
                        .interpolationMethod(.catmullRom) // Smooth line
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        AreaMark(
                            x: .value("date", point.date),
                            y: .value("count", point.count)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue.opacity(0.2))
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: chartStrideCount)) { _ in
                            AxisValueLabel(format: .dateTime.day().month(), centered: true)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 300)
                    .onTapGesture { location in
                        // Simple tap handling to find nearest point
                        // In a real app, you'd calculate the closest data point based on location
                        // For now, we just show the last point or handle it differently if needed
                        // A proper implementation requires mapping screen coordinates to data
                    }
                    
                    // Details Section
                    if let point = selectedDataPoint {
                        VStack(spacing: 10) {
                            Text(point.date, style: .date)
                                .font(.headline)
                            HStack(spacing: 20) {
                                VStack {
                                    Text("pouches_count")
                                        .foregroundColor(.secondary)
                                    Text("\(point.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                VStack {
                                    Text("total_mg")
                                        .foregroundColor(.secondary)
                                    Text("\(point.mg) mg")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                    } else {
                        Text("tap_chart_details")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                } else {
                    Text("charts_require_ios16")
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .navigationTitle("statistics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onChange(of: selectedPeriod) { _ in
                selectedDataPoint = nil
            }
        }
    }
    
    private var chartStrideCount: Int {
        switch selectedPeriod {
        case .day24: return 4 // Every 6 hours roughly
        case .week: return 1 // Every day
        case .month2: return 7 // Every week
        case .month6: return 14 // Every 2 weeks
        case .year: return 1 // Every month (handled by data grouping)
        case .year2: return 2 // Every 2 months
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(DataStore())
}

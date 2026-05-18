import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataStore: DataStore
    
    @State private var selectedPeriod: StatsPeriod = .week
    
    var body: some View {
        VStack(spacing: 20) {
            // Period Selector with readable labels
            Picker("period", selection: $selectedPeriod) {
                ForEach(StatsPeriod.allCases) { period in
                    Text(period.localizedName).tag(period)
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
                        y: .value("count", max(0, point.count))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [dataStore.settings.resolvedAccentColor, dataStore.settings.resolvedAccentColor.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    AreaMark(
                        x: .value("date", point.date),
                        y: .value("count", max(0, point.count))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(dataStore.settings.resolvedAccentColor.opacity(0.2))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: chartStrideCount)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel(format: .dateTime.day().month(), centered: true)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartYScale(domain: 0...(max(1, stats.map { $0.count }.max() ?? 1)))
                .frame(height: 300)
                
                // Summary Section
                VStack(spacing: 10) {
                    HStack(spacing: 20) {
                        VStack {
                            Text("total_pouches")
                                .foregroundColor(.secondary)
                            Text("\(stats.reduce(0) { $0 + $1.count })")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        VStack {
                            Text("total_mg_sum")
                                .foregroundColor(.secondary)
                            Text("\(stats.reduce(0) { $0 + $1.mg }) mg")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
            } else {
                Text("charts_require_ios16")
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .navigationTitle("statistics")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPeriod) { _ in
            // Reset any selection when period changes
        }
    }
    
    private var chartStrideCount: Int {
        switch selectedPeriod {
        case .day24: return 4
        case .week: return 1
        case .month2: return 7
        case .month6: return 14
        case .year: return 1
        case .year2: return 2
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(DataStore())
}

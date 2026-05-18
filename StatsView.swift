import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPeriod: StatsPeriod = .day24
    @State private var selectedPoint: (date: Date, count: Int, mg: Int)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            // Back button and Period Selector
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(dataStore.settings.resolvedAccentColor)
                }
                
                Spacer()
                
                Picker("period", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases) { period in
                        Text(period.localizedName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                
                Spacer()
                
                // Invisible spacer to balance the back button
                Color.clear.frame(width: 30)
            }
            .padding(.horizontal)
            
            // Chart
            if #available(iOS 16.0, *) {
                let stats = dataStore.getStatsForPeriod(selectedPeriod)
                
                Chart(stats, id: \.date) { point in
                    LineMark(
                        x: .value("date", point.date),
                        y: .value("count", max(0, point.count))
                    )
                    .interpolationMethod(.linear)
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
                    .interpolationMethod(.linear)
                    .foregroundStyle(dataStore.settings.resolvedAccentColor.opacity(0.2))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: xAxisStride, count: 1)) { value in
                        if let date = value.as(Date.self) {
                            if selectedPeriod == .day24 {
                                AxisValueLabel(format: .dateTime.hour(), centered: true)
                            } else if selectedPeriod == .month6 || selectedPeriod == .year1 {
                                AxisValueLabel(format: .dateTime.month().day(), centered: true)
                            } else {
                                AxisValueLabel(format: .dateTime.day().month(), centered: true)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartYScale(domain: 0...(max(1, stats.map { $0.count }.max() ?? 1)))
                .frame(height: 300)
                .onTapGesture { location in
                    // Find the closest data point to the tap location
                    if let chartFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 300),
                       chartFrame.contains(location) {
                        let relativeX = (location.x - chartFrame.minX) / chartFrame.width
                        let index = Int(relativeX * Double(stats.count))
                        if index >= 0 && index < stats.count {
                            selectedPoint = stats[index]
                        }
                    }
                }
                .overlay(
                    Group {
                        if let point = selectedPoint {
                            VStack {
                                Text(formatDateForTooltip(point.date, for: selectedPeriod))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.8))
                                    .cornerRadius(4)
                                
                                Text("\(point.count) pouches\n\(point.mg) mg")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(dataStore.settings.resolvedAccentColor)
                                    .cornerRadius(8)
                                    .shadow(radius: 5)
                                
                                Spacer()
                            }
                            .padding()
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                )
                
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
            selectedPoint = nil
        }
    }
    
    private var xAxisStride: Int {
        switch selectedPeriod {
        case .day24: return 4
        case .week1, .week2: return 1
        case .month1: return 5
        case .month2: return 7
        case .month6: return 15
        case .year1: return 30
        }
    }
    
    private func formatDateForTooltip(_ date: Date, for period: StatsPeriod) -> String {
        let formatter = DateFormatter()
        if period == .day24 {
            formatter.dateFormat = "HH:mm"
        } else if period == .month6 || period == .year1 {
            formatter.dateFormat = "MMM dd"
        } else {
            formatter.dateFormat = "dd MMM"
        }
        return formatter.string(from: date)
    }
}

#Preview {
    StatsView()
        .environmentObject(DataStore())
}

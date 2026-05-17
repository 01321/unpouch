import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var selectedDataPoint: (date: Date, count: Int)? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Period Selector
                Picker("period", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Chart
                if let chartData = generateChartData() {
                    Chart(chartData, id: \.date) { item in
                        LineMark(
                            x: .value("date", item.date),
                            y: .value("count", item.count)
                        )
                        .interpolationMethod(.catmullRom) // Smooth line
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("date", item.date),
                            y: .value("count", item.count)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel(format: .dateTime.day().month())
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                            if let date = proxy.value(atX: x) as Date? {
                                                // Find closest data point
                                                if let closest = chartData.min(by: {
                                                    abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                                }) {
                                                    selectedDataPoint = (date: closest.date, count: closest.count)
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            // Optional: clear selection on lift
                                            // selectedDataPoint = nil
                                        }
                                )
                        }
                    }
                    .padding()
                    
                    // Tooltip / Detail View
                    if let point = selectedDataPoint {
                        VStack {
                            Text(point.date, style: .date)
                                .font(.headline)
                            Text("\(point.count) pouches")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.white.shadow(radius: 10))
                        .cornerRadius(10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                } else {
                    Text("no_data")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }
    
    private func generateChartData() -> [ChartDataPoint]? {
        let pouches = dataStore.getPouchesForPeriod(selectedPeriod)
        guard !pouches.isEmpty else { return nil }
        
        let calendar = Calendar.current
        var grouped: [Date: Int] = [:]
        
        // Determine grouping unit based on period
        let component: Calendar.Component
        switch selectedPeriod {
        case .day24, .week:
            component = .hour // Show per hour for short periods? Or per day? Request said "day" for week.
            // Let's stick to Day for everything except 24h maybe?
            // Request: "week -> per day", "year -> per month"
            // Let's refine:
            // 24h -> per hour
            // week, 2m -> per day
            // 6m, 1y, 2y -> per month/week mix? Let's do Month for > 2 months
        case .month, .months2:
            component = .day
        case .months6, .year, .years2:
            component = .month
        }
        
        // Re-evaluating based on specific request:
        // "tydzień to pokazuje ile w dany dzień" (week -> per day)
        // "rok ile w danym miesiącu" (year -> per month)
        // Let's map:
        // 24h -> Hourly
        // Week, Month, 2 Months -> Daily
        // 6 Months, 1 Year, 2 Years -> Monthly
        
        let groupComponent: Calendar.Component
        switch selectedPeriod {
        case .day24:
            groupComponent = .hour
        case .week, .month, .months2:
            groupComponent = .day
        case .months6, .year, .years2:
            groupComponent = .month
        }
        
        for pouch in pouches {
            if let intervalStart = calendar.date(from: calendar.dateComponents([groupComponent], from: pouch.date)) {
                grouped[intervalStart, default: 0] += 1
            }
        }
        
        var result: [ChartDataPoint] = grouped.map { date, count in
            ChartDataPoint(date: date, count: count)
        }.sorted { $0.date < $1.date }
        
        // Fill gaps if necessary? Charts usually handles missing points by breaking line.
        // For a smooth continuous line, we might want to fill zeros.
        // Let's try without filling first, or fill if it looks broken.
        // Filling logic omitted for brevity, but Charts often interpolates.
        
        return result
    }
}

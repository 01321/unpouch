import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var selectedDate: Date?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Period Selector
                Picker("period", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases, id: \.self) { period in
                        Text(period.localizedName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Chart
                if #available(iOS 16.0, *) {
                    chartView
                        .frame(height: 300)
                        .padding()
                } else {
                    Text("Charts require iOS 16+")
                        .foregroundColor(.secondary)
                }
                
                // Selected Date Details
                if let date = selectedDate {
                    let count = pouchesCount(for: date)
                    VStack(spacing: 5) {
                        Text(date, style: .date)
                            .font(.headline)
                        Text("\(count) pouches")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .navigationTitle("statistics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @available(iOS 16.0, *)
    var chartView: some View {
        Chart(dataPoints, id: \.date) { point in
            LineMark(
                x: .value("date", point.date),
                y: .value("count", point.count)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.blue.gradient)
            
            AreaMark(
                x: .value("date", point.date),
                yStart: .value("count", 0),
                yEnd: .value("count", point.count)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: xAxisStride))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartSelection(selection: $selectedDate)
    }
    
    var dataPoints: [DataPoint] {
        let pouches = dataStore.getPouchesForPeriod(selectedPeriod)
        guard !pouches.isEmpty else { return [] }
        
        let calendar = Calendar.current
        var grouped: [Date: Int] = [:]
        
        for pouch in pouches {
            let interval: DateComponents
            switch selectedPeriod {
            case .day, .week:
                interval = DateComponents(day: 1)
            case .month, .twoMonths:
                interval = DateComponents(day: 1)
            case .sixMonths, .year, .twoYears:
                interval = DateComponents(month: 1)
            }
            
            if let startOfDay = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: pouch.date)) {
                grouped[startOfDay, default: 0] += 1
            }
        }
        
        return grouped.map { DataPoint(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    var xAxisStride: Int {
        switch selectedPeriod {
        case .day: return 1
        case .week: return 1
        case .month: return 7
        case .twoMonths: return 14
        case .sixMonths: return 30
        case .year: return 60
        case .twoYears: return 90
        }
    }
    
    func pouchesCount(for date: Date) -> Int {
        let calendar = Calendar.current
        let pouches = dataStore.getPouchesForPeriod(selectedPeriod)
        
        return pouches.filter { pouch in
            calendar.isDate(pouch.date, inSameDayAs: date)
        }.count
    }
}

struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedPeriod: TimePeriod = .day24
    @State private var showingMainView = false
    
    enum TimePeriod: String, CaseIterable, Identifiable {
        case day24 = "24H"
        case week1 = "1W"
        case week2 = "2W"
        case month1 = "1M"
        case month2 = "2M"
        case month6 = "6M"
        case year1 = "1Y"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .day24: return 1
            case .week1: return 7
            case .week2: return 14
            case .month1: return 30
            case .month2: return 60
            case .month6: return 180
            case .year1: return 365
            }
        }
    }
    
    var filteredData: [Pouch] {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: now) else {
            return []
        }
        
        var entries = dataStore.pouches.filter { entry in
            return entry.date >= startDate && entry.date <= now
        }
        entries.sort { $0.date < $1.date }
        return entries
    }
    
    var chartData: [(date: Date, value: Int)] {
        let calendar = Calendar.current
        var result: [(Date, Int)] = []
        
        guard !filteredData.isEmpty else { return [] }
        
        if selectedPeriod == .day24 {
            // Dla 24h pokazujemy każdą rejestrację z godziną
            for entry in filteredData {
                result.append((entry.date, entry.strength))
            }
        } else {
            // Agregacja dzienna dla dłuższych okresów
            var dailySums: [Date: Int] = [:]
            for entry in filteredData {
                let dayStart = calendar.startOfDay(for: entry.date)
                dailySums[dayStart, default: 0] += entry.strength
            }
            
            // Wypełnianie luk zerami, aby wykres był ciągły
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) else {
                return []
            }
            
            var currentDate = startDate
            while currentDate <= endDate {
                let dayStart = calendar.startOfDay(for: currentDate)
                let value = dailySums[dayStart] ?? 0
                if currentDate <= endDate {
                     result.append((dayStart, value))
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
            }
        }
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header z przyciskiem powrotu
            HStack {
                Button(action: {
                    showingMainView = true
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding()
            
            // Picker okresu
            Picker("Period", selection: $selectedPeriod) {
                ForEach(TimePeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom)
            
            // Wykres
            if chartData.isEmpty {
                VStack {
                    Spacer()
                    Text("No data available for this period")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                makeChart()
                    .frame(height: 300)
                    .padding()
            }
            
            Spacer()
        }
        .navigationDestination(isPresented: $showingMainView) {
            ContentView()
                .environmentObject(dataStore)
        }
    }
    
    @ViewBuilder
    func makeChart() -> some View {
        Chart(chartData, id: \.date) { item in
            LineMark(
                x: .value("Date", item.date),
                y: .value("Count", item.value)
            )
            .interpolationMethod(.linear) // Ostry wykres (liniowy)
            .symbol(.circle)
            
            PointMark(
                x: .value("Date", item.date),
                y: .value("Count", item.value)
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: xAxisStride())) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(format: xAxisFormat(date))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Interakcja obsługiwana przez chartTooltip
                            }
                    )
            }
        }
        .chartOverlay { proxy in
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Custom tooltip logic if needed
                            }
                    )
                
                // Tooltip removed - iOS 17+ feature not available
            }
        }
    }
    
    func findClosestItem(to location: CGPoint, in proxy: ChartProxy, geometry: GeometryProxy) -> (date: Date, value: Int)? {
        guard let plotFrameRect = proxy.plotFrame else { return nil }
        let plotFrame = plotFrameRect.rect
        let relativeX = location.x - plotFrame.minX
        
        var closestItem: (date: Date, value: Int)?
        var minDistance: CGFloat = .infinity
        
        for item in chartData {
            if let xPos = proxy.position(forX: item.date) {
                let distance = abs(xPos - location.x)
                if distance < minDistance && distance < 20 { // Tolerance
                    minDistance = distance
                    closestItem = item
                }
            }
        }
        return closestItem
    }
    
    func xAxisStride() -> Calendar.Component {
        switch selectedPeriod {
        case .day24: return .hour
        case .week1, .week2: return .day
        case .month1, .month2: return .day
        case .month6, .year1: return .month
        }
    }
    
    func xAxisFormat(_ date: Date) -> Date.FormatStyle {
        switch selectedPeriod {
        case .day24:
            return .dateTime.hour().minute()
        case .week1, .week2:
            return .dateTime.weekday(.abbreviated).day()
        case .month1, .month2:
            return .dateTime.day().month(.abbreviated)
        case .month6, .year1:
            return .dateTime.month(.abbreviated)
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(DataStore())
}

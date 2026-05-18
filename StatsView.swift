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
            // Dla 24h pokazujemy każdą rejestrację z godziną (zaokrągloną do godziny)
            for entry in filteredData {
                let hourStart = calendar.date(bySettingHour: calendar.component(.hour, from: entry.date),
                                              minute: 0, second: 0, of: entry.date) ?? entry.date
                result.append((hourStart, entry.strength))
            }
        } else if selectedPeriod == .week1 || selectedPeriod == .week2 {
            // Dla 1W i 2W - ostatnie 7/14 dni, dane dzienne bez agregacji
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days + 1, to: endDate) else {
                return []
            }
            
            // Wypełnij wszystkie dni zerami
            var currentDate = calendar.startOfDay(for: startDate)
            while currentDate <= endDate {
                let daySum = filteredData.filter { entry in
                    calendar.isDate(entry.date, inSameDayAs: currentDate)
                }.reduce(0) { $0 + $1.strength }
                result.append((currentDate, daySum))
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
            }
        } else if selectedPeriod == .month1 || selectedPeriod == .month2 {
            // Dla 1M i 2M - dane tygodniowe (suma z tygodnia)
            var weeklySums: [Date: Int] = [:]
            for entry in filteredData {
                // Znajdź początek tygodnia (poniedziałek)
                var startOfWeek = calendar.startOfDay(for: entry.date)
                var weekday = calendar.component(.weekday, from: entry.date)
                let firstWeekday = calendar.firstWeekday
                var daysToMonday = weekday - firstWeekday + 1
                if daysToMonday <= 0 {
                    daysToMonday += 7
                }
                startOfWeek = calendar.date(byAdding: .day, value: -daysToMonday + 1, to: startOfWeek) ?? startOfWeek
                
                weeklySums[startOfWeek, default: 0] += entry.strength
            }
            
            // Wypełnij tygodnie zerami
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) else {
                return []
            }
            
            var currentDate = calendar.startOfDay(for: startDate)
            // Dostosuj do początku tygodnia
            var weekday = calendar.component(.weekday, from: currentDate)
            let firstWeekday = calendar.firstWeekday
            var daysToMonday = weekday - firstWeekday + 1
            if daysToMonday <= 0 {
                daysToMonday += 7
            }
            currentDate = calendar.date(byAdding: .day, value: -daysToMonday + 1, to: currentDate) ?? currentDate
            
            while currentDate <= endDate {
                let value = weeklySums[currentDate] ?? 0
                result.append((currentDate, value))
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? endDate
            }
        } else {
            // Agregacja miesięczna dla 6M i 1Y
            var monthlySums: [Date: Int] = [:]
            for entry in filteredData {
                // Znajdź początek miesiąca
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)) ?? entry.date
                monthlySums[monthStart, default: 0] += entry.strength
            }
            
            // Wypełnij miesiące zerami
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) else {
                return []
            }
            
            var currentDate = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate)) ?? startDate
            
            while currentDate <= endDate {
                let value = monthlySums[currentDate] ?? 0
                result.append((currentDate, value))
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? endDate
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
                let date = value.as(Date.self)
                AxisValueLabel(format: date.map { xAxisFormat($0) } ?? .dateTime)            }
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
    
    
    func xAxisStride() -> Calendar.Component {
        switch selectedPeriod {
        case .day24: return .hour
        case .week1, .week2: return .day
        case .month1, .month2: return .weekOfYear
        case .month6, .year1: return .month
        }
    }
    
    func xAxisFormat(_ date: Date) -> Date.FormatStyle {
        switch selectedPeriod {
        case .day24:
            return .dateTime.hour()
        case .week1, .week2:
            return .dateTime.day().month(.abbreviated)
        case .month1, .month2:
            return .dateTime.day().month(.abbreviated)
        case .month6, .year1:
            return .dateTime.month(.abbreviated).year()
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(DataStore())
}

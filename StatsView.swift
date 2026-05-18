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
    
    var filteredData: [PouchEntry] {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: now) else {
            return []
        }
        
        var entries = dataStore.entries.filter { $0.date >= startDate && $0.date <= now }
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
                result.append((entry.date, entry.count))
            }
        } else {
            // Agregacja dzienna dla dłuższych okresów
            var dailySums: [Date: Int] = [:]
            for entry in filteredData {
                if let dayStart = calendar.startOfDay(for: entry.date) {
                    dailySums[dayStart, default: 0] += entry.count
                }
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
                // Pomijamy dni z końcówki zakresu, które są w przyszłości lub mają 0 i są poza zakresem danych
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
                x: .value("Date", item.date, unit: .hour),
                y: .value("Count", item.value)
            )
            .interpolationMethod(.linear) // Ostry wykres (liniowy)
            .symbol(Circle().stroke(lineWidth: 2))
            
            PointMark(
                x: .value("Date", item.date, unit: .hour),
                y: .value("Count", item.value)
            )
            .annotation(position: .overlay) {
                if selectedPeriod == .day24 {
                    // Pokaż godzinę tylko dla 24h przy punktach, jeśli chcemy, ale dymek obsłuży to lepiej
                }
            }
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
                            .onChanged { value in
                                // Logika dymka jest obsługiwana natywnie przez Chart w nowszych iOS
                                // lub można dodać custom overlay jeśli potrzebny jest specyficzny styl
                            }
                    )
            }
        }
        .chartTooltip { proxy in
            if let date = proxy.index(as: Date.self),
               let item = chartData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) && ($0.date.timeIntervalSince(date) > -3600 && $0.date.timeIntervalSince(date) < 3600) || abs($0.date.timeIntervalSince(date)) < 3600 }) {
                
                VStack(alignment: .center) {
                    Text(item.date, style: .date)
                        .font(.caption)
                    Text("\(item.value) pouches")
                        .font(.headline)
                    if selectedPeriod == .day24 {
                        Text(item.date, style: .time)
                            .font(.caption2)
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.8))
                .cornerRadius(8)
            }
        }
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
            return .dateTime.month(.abbreviated).year()
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(DataStore())
}

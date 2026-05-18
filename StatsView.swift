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
            // Dla 24h - pełne 24 godziny, ale etykiety tylko tam gdzie są zmiany
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .hour, value: -23, to: endDate) else {
                return []
            }
            
            // Wypełnij wszystkie godziny zerami
            var currentDate = calendar.date(bySettingHour: calendar.component(.hour, from: startDate),
                                           minute: 0, second: 0, of: startDate) ?? startDate
            
            // Znajdź godziny, w których były zmiany (dla etykiet)
            var hoursWithChanges: Set<Int> = []
            for entry in filteredData {
                let hour = calendar.component(.hour, from: entry.date)
                hoursWithChanges.insert(hour)
            }
            
            while currentDate <= endDate {
                let hourCount = filteredData.filter { entry in
                    calendar.isDate(entry.date, equalTo: currentDate, toGranularity: .hour)
                }.count
                result.append((currentDate, hourCount))
                currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? endDate
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
                let dayCount = filteredData.filter { entry in
                    calendar.isDate(entry.date, inSameDayAs: currentDate)
                }.count
                result.append((currentDate, dayCount))
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
            }
        } else if selectedPeriod == .month1 || selectedPeriod == .month2 {
            // Dla 1M i 2M - dane tygodniowe (suma z tygodnia)
            var weeklyCounts: [Date: Int] = [:]
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
                
                weeklyCounts[startOfWeek, default: 0] += 1
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
                let value = weeklyCounts[currentDate] ?? 0
                result.append((currentDate, value))
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? endDate
            }
        } else {
            // Agregacja miesięczna dla 6M i 1Y
            var monthlyCounts: [Date: Int] = [:]
            for entry in filteredData {
                // Znajdź początek miesiąca
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)) ?? entry.date
                monthlyCounts[monthStart, default: 0] += 1
            }
            
            // Wypełnij miesiące zerami
            let endDate = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) else {
                return []
            }
            
            var currentDate = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate)) ?? startDate
            
            while currentDate <= endDate {
                let value = monthlyCounts[currentDate] ?? 0
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
                
                // Podsumowanie w zaokrąglonym prostokącie
                summaryBox
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // Koszt w zaokrąglonym prostokącie
                costBox
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            
            Spacer()
        }
        .navigationDestination(isPresented: $showingMainView) {
            ContentView()
                .environmentObject(dataStore)
        }
    }
    
    var summaryBox: some View {
        let totalPouches = filteredData.count
        let totalMg = filteredData.reduce(0) { $0 + $1.strength }
        
        return VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Pouches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalPouches)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total mg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalMg)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    var costBox: some View {
        let totalPouches = filteredData.count
        let costPerPouch = 1.05
        let totalCost = Double(totalPouches) * costPerPouch
        
        return VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated Cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f zł", totalCost))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Per pouch")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f zł", costPerPouch))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
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
            AxisMarks(values: xAxisValues()) { value in
                let date = value.as(Date.self)
                AxisValueLabel(format: date.map { xAxisFormat($0) } ?? .dateTime)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let intValue = value.as(Int.self) {
                    AxisValueLabel("\(intValue)")
                } else {
                    AxisGridLine()
                    AxisTick()
                }
            }
        }
        .chartYScale(domain: 0...) // Zawsze zaczynaj od 0, żeby wykres nie "malal"
    }
    
    
    func xAxisValues() -> AxisMarkValues {
        switch selectedPeriod {
        case .day24:
            // Dla 24h - pokazuj tylko godziny, w których były zmiany
            let hoursWithChanges = Set(filteredData.map { Calendar.current.component(.hour, from: $0.date) })
            if hoursWithChanges.isEmpty {
                return .stride(by: Calendar.Component.hour, count: 6)
            }
            // Zwróć customowe wartości dla godzin ze zmianami
            let calendar = Calendar.current
            let now = Date()
            guard let startDate = calendar.date(byAdding: .hour, value: -23, to: now) else {
                return .stride(by: Calendar.Component.hour, count: 6)
            }
            var datesWithChanges: [Date] = []
            for hour in hoursWithChanges.sorted() {
                if let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) {
                    if date >= startDate && date <= now {
                        datesWithChanges.append(date)
                    }
                }
            }
            return .custom(datesWithChanges)
        case .week1:
            // Pokaż co 3 dni dla 7 dni
            return .stride(by: Calendar.Component.day, count: 3)
        case .week2:
            // Pokaż co 5 dni dla 14 dni, żeby się nie nakładały
            return .stride(by: Calendar.Component.day, count: 5)
        case .month1, .month2:
            return .stride(by: Calendar.Component.weekOfYear, count: 1)
        case .month6:
            // Pokaż co 3 miesiące dla 6M
            return .stride(by: Calendar.Component.month, count: 3)
        case .year1:
            // Pokaż co 4 miesiące dla 1Y, żeby się nie nakładały
            return .stride(by: Calendar.Component.month, count: 4)
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
            return .dateTime.hour().minute(.omitted)
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

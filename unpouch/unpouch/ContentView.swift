import SwiftUI

struct ContentView: View {
    @StateObject private var dataStore = DataStore()
    @State private var showingAddSheet = false
    @State private var showingStatsView = false
    @State private var showingSettings = false
    @State private var selectedStrength: Int = 10
    
    private var themeColor: Color {
        switch dataStore.settings.themeColor {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    Text("unpouch.")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Today")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Text("\(dataStore.getTodayPouches().count)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(themeColor)
                    
                    HStack {
                        let todayCount = dataStore.getTodayPouches().count
                        let limit = dataStore.settings.dailyLimit
                        if todayCount < limit {
                            Text("Under limit ✅")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        } else if todayCount == limit {
                            Text("At limit ⚠️")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        } else {
                            Text("Over limit ❌")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                Button(action: { showingAddSheet = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Pouch")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: { showingStatsView = true }) {
                        VStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                            Text("Stats")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Button(action: { showingSettings = true }) {
                        VStack {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                            Text("Settings")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSheet) {
                AddPouchView(dataStore: dataStore, selectedStrength: $selectedStrength, themeColor: themeColor)
            }
            .fullScreenCover(isPresented: $showingStatsView) {
                StatsView(dataStore: dataStore, themeColor: themeColor)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(dataStore: dataStore, themeColor: themeColor)
            }
        }
    }
}

struct AddPouchView: View {
    @ObservedObject var dataStore: DataStore
    @Binding var selectedStrength: Int
    @Environment(\.dismiss) var dismiss
    var themeColor: Color
    
    @State private var showingCustomStrength = false
    @State private var customStrengthValue: String = ""
    
    private var availableStrengths: [Int] {
        let defaultStrengths = Array(stride(from: 10, through: 100, by: 10))
        let customStrengths = dataStore.settings.customStrengths
        var allStrengths = Set(defaultStrengths + customStrengths)
        
        // Get used strengths and prioritize them
        let usedStrengths = dataStore.getUsedStrengths()
        
        // Sort: used strengths first (descending by usage), then others
        var result: [Int] = []
        
        // Add used strengths first
        for strength in usedStrengths.reversed() {
            if allStrengths.contains(strength) {
                result.append(strength)
                allStrengths.remove(strength)
            }
        }
        
        // Add remaining strengths sorted
        let remaining = allStrengths.sorted()
        result.append(contentsOf: remaining)
        
        // Limit to 10 options
        return Array(result.prefix(10))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Strength")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                        ForEach(availableStrengths, id: \.self) { strength in
                            Button(action: {
                                selectedStrength = strength
                                dataStore.addPouch(strength: strength)
                                dismiss()
                            }) {
                                Text("\(strength)mg")
                                    .font(.headline)
                                    .frame(width: 80, height: 60)
                                    .background(strength == selectedStrength ? themeColor : Color(.systemGray5))
                                    .foregroundColor(strength == selectedStrength ? .white : .primary)
                                    .cornerRadius(10)
                            }
                        }
                        
                        Button(action: { showingCustomStrength = true }) {
                            Text("Custom")
                                .font(.headline)
                                .frame(width: 80, height: 60)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Add Pouch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCustomStrength) {
                CustomStrengthView(dataStore: dataStore, customStrengthValue: $customStrengthValue, themeColor: themeColor)
            }
        }
    }
}

struct CustomStrengthView: View {
    @ObservedObject var dataStore: DataStore
    @Binding var customStrengthValue: String
    @Environment(\.dismiss) var dismiss
    var themeColor: Color
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter strength (mg)", text: $customStrengthValue)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    if let value = Int(customStrengthValue), value > 0 && value <= 200 {
                        dataStore.addCustomStrength(value)
                        dismiss()
                    }
                }) {
                    Text("Save Custom Strength")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Custom Strength")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct StatsView: View {
    @ObservedObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    var themeColor: Color
    
    @State private var selectedPeriod: StatsPeriod = .day24
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                ChartView(dataStore: dataStore, period: selectedPeriod, themeColor: themeColor)
                    .frame(height: 300)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ChartView: View {
    @ObservedObject var dataStore: DataStore
    var period: StatsPeriod
    var themeColor: Color
    
    var data: [(date: Date, count: Int)] {
        dataStore.getStatsForPeriod(period)
    }
    
    var maxValue: Int {
        data.map { $0.count }.max() ?? 1
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Grid lines
                ForEach(0..<5) { i in
                    let y = CGFloat(i) * geometry.size.height / 4
                    Line(start: CGPoint(x: 0, y: y), end: CGPoint(x: geometry.size.width, y: y))
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
                
                // Bars
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(data.indices, id: \.self) { index in
                        let item = data[index]
                        let barHeight = maxValue > 0 ? (CGFloat(item.count) / CGFloat(maxValue)) * (geometry.size.height - 30) : 0
                        
                        VStack {
                            Text("\(item.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Rectangle()
                                .fill(themeColor)
                                .frame(width: max(0, (geometry.size.width - CGFloat(data.count - 1) * 4) / CGFloat(data.count), height: max(0, barHeight)))
                                .cornerRadius(3)
                            
                            Text(formatDate(item.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch period {
        case .day24:
            formatter.dateFormat = "HH"
        case .week1, .month1:
            formatter.dateFormat = "dd/MM"
        case .year1, .all:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }
}

struct Line: Shape {
    var start: CGPoint
    var end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}

struct SettingsView: View {
    @ObservedObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    var themeColor: Color
    
    @State private var showingLanguagePicker = false
    @State private var showingColorPicker = false
    @State private var limitText: String = ""
    
    let languages = ["English", "Polski", "Deutsch", "Français", "Español"]
    let languageCodes = ["en", "pl", "de", "fr", "es"]
    
    let colorOptions: [(name: String, code: String, color: Color)] = [
        ("Blue", "blue", .blue),
        ("Red", "red", .red),
        ("Green", "green", .green),
        ("Orange", "orange", .orange),
        ("Purple", "purple", .purple),
        ("Pink", "pink", .pink)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Limit")) {
                    HStack {
                        Text("Limit")
                        Spacer()
                        TextField("Limit", text: $limitText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: limitText) { newValue in
                                if let value = Int(newValue) {
                                    dataStore.settings.dailyLimit = value
                                    dataStore.saveSettings()
                                }
                            }
                    }
                    .onAppear {
                        limitText = "\(dataStore.settings.dailyLimit)"
                    }
                }
                
                Section(header: Text("Language")) {
                    Picker("Language", selection: $dataStore.settings.languageCode) {
                        ForEach(0..<languages.count, id: \.self) { index in
                            Text(languages[index]).tag(languageCodes[index])
                        }
                    }
                    .onChange(of: dataStore.settings.languageCode) { _ in
                        dataStore.saveSettings()
                    }
                }
                
                Section(header: Text("Theme Color")) {
                    Picker("Color", selection: $dataStore.settings.themeColor) {
                        ForEach(colorOptions, id: \.code) { option in
                            HStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 20, height: 20)
                                Text(option.name)
                            }
                            .tag(option.code)
                        }
                    }
                    .onChange(of: dataStore.settings.themeColor) { _ in
                        dataStore.saveSettings()
                    }
                }
                
                Section(header: Text("Custom Strengths")) {
                    ForEach(dataStore.settings.customStrengths, id: \.self) { strength in
                        HStack {
                            Text("\(strength)mg")
                            Spacer()
                            Button("Delete", role: .destructive) {
                                dataStore.removeCustomStrength(strength)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Delete All Data", role: .destructive) {
                        dataStore.deleteAllPouches()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

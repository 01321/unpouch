import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showSettings = false
    @State private var showStrengthPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Title at the top
                Text("unpouch.")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Top Stats Section
                VStack(spacing: 10) {
                    Text("today")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    let stats = dataStore.getTodayStats()
                    
                    Text("\(stats.count)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [dataStore.settings.resolvedAccentColor, dataStore.settings.resolvedAccentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("\(stats.totalMg) mg")
                        .font(.title)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    
                    // Limit Status
                    LimitStatusView(count: stats.count, limit: dataStore.settings.dailyLimit)
                }
                
                Spacer()
                
                // Controls Section
                VStack(spacing: 20) {
                    // Strength Selector Button
                    Button(action: {
                        showStrengthPicker = true
                    }) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("\(dataStore.settings.currentStrength) mg")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                    }
                    .sheet(isPresented: $showStrengthPicker) {
                        StrengthPickerView()
                            .environmentObject(dataStore)
                    }
                    
                    // Main Add Button
                    Button(action: {
                        dataStore.addPouch(strength: dataStore.settings.currentStrength)
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [dataStore.settings.resolvedAccentColor.opacity(0.8), dataStore.settings.resolvedAccentColor.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 220, height: 220)
                                .shadow(color: dataStore.settings.resolvedAccentColor.opacity(0.4), radius: 15, x: 0, y: 10)
                            
                            VStack(spacing: 5) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 50))
                                Text("add_pouch")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                        }
                    }
                    
                    // Remove Button
                    Button(action: {
                        dataStore.removeLastPouch()
                    }) {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                            Text("remove_last")
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                // Stats Entry Button
                NavigationLink(destination: {
                    StatsView()
                        .environmentObject(dataStore)
                }) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("view_stats")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(dataStore.settings.resolvedAccentColor)
                    .cornerRadius(15)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(dataStore.settings.resolvedAccentColor)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(dataStore)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct LimitStatusView: View {
    let count: Int
    let limit: Int
    
    var statusText: String {
        let diff = count - limit
        if diff == 0 {
            return "limit_exact"
        } else if diff > 0 {
            if diff == 1 {
                return "limit_slightly_over"
            } else {
                return "limit_over"
            }
        } else {
            if diff == -1 {
                return "limit_slightly_under"
            } else {
                return "under_limit_emoji"
            }
        }
    }
    
    var statusColor: Color {
        let diff = count - limit
        if diff > 1 { return .red }
        if diff == 1 { return .orange }
        if diff == 0 { return .green }
        if diff == -1 { return .blue }
        return .gray
    }
    
    var body: some View {
        Text(statusText)
            .font(.headline)
            .foregroundColor(statusColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(statusColor.opacity(0.1))
            .cornerRadius(20)
    }
}

struct StrengthPickerView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var showCustomStrengthSheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("available_strengths")) {
                    ForEach(dataStore.settings.usedStrengths(from: dataStore.pouches), id: \.self) { strength in
                        Button(action: {
                            dataStore.settings.currentStrength = strength
                            dataStore.save()
                            dismiss()
                        }) {
                            HStack {
                                Text("\(strength) mg")
                                Spacer()
                                if dataStore.settings.currentStrength == strength {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(dataStore.settings.resolvedAccentColor)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: { showCustomStrengthSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("add_custom_strength")
                        }
                        .foregroundColor(dataStore.settings.resolvedAccentColor)
                    }
                }
            }
            .navigationTitle("select_strength")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCustomStrengthSheet) {
                CustomStrengthInputView(showSheet: $showCustomStrengthSheet)
                    .environmentObject(dataStore)
            }
        }
    }
}

struct CustomStrengthInputView: View {
    @EnvironmentObject var dataStore: DataStore
    @Binding var showSheet: Bool
    @State private var customStrengthValue = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("enter_custom_strength")) {
                    TextField("strength_mg", text: $customStrengthValue)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("custom_strength")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        showSheet = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("add") {
                        if let value = Int(customStrengthValue), value > 0 && value <= 200 {
                            if !dataStore.settings.customStrengths.contains(value) {
                                dataStore.settings.customStrengths.append(value)
                                dataStore.settings.currentStrength = value
                                dataStore.save()
                            }
                            showSheet = false
                        }
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataStore())
}

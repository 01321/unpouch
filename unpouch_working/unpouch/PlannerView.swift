import SwiftUI

struct PlannerView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var dailyPouches: String = ""
    @State private var sleepHours: String = ""
    @State private var packPrice: String = ""
    @State private var pouchesPerPack: String = ""
    @State private var currency: String = ""
    
    var activeHours: Double {
        let sleep = Double(sleepHours) ?? dataStore.settings.sleepHours
        return max(0, 24.0 - sleep)
    }
    
    var intervalPerPouch: Double {
        let pouches = Int(dailyPouches) ?? dataStore.settings.plannerDailyLimit
        if pouches <= 0 || activeHours <= 0 { return 0 }
        return activeHours / Double(pouches)
    }
    
    var calculatedCostPerPouch: Double {
        let price = Double(packPrice) ?? dataStore.settings.packPrice
        let count = Int(pouchesPerPack) ?? dataStore.settings.pouchesPerPack
        guard count > 0 else { return 0 }
        return price / Double(count)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Section 1: Daily Limit with interval preview below
                Section(header: Text("planner_daily_limit_header")) {
                    HStack {
                        Text("planner_pouches_per_day")
                        Spacer()
                        TextField("8", text: $dailyPouches)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    // Interval displayed below container in smaller font
                    if let pouches = Int(dailyPouches), pouches > 0 {
                        Text(String(format: "planner_approx_interval".localized, formatTime(intervalPerPouch)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                
                // Section 2: Sleep hours with active time below
                Section(header: Text("planner_sleep_duration")) {
                    HStack {
                        Text("planner_sleep_hours")
                        Spacer()
                        TextField("8", text: $sleepHours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    // Active time displayed below in smaller font
                    Text(String(format: "planner_active_time_display".localized, String(format: "%.1f", activeHours)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                // Section 3: Pack Information
                Section(header: Text("planner_pack_info")) {
                    HStack {
                        Text("planner_pack_price")
                        Spacer()
                        TextField("15.50", text: $packPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("planner_pouches_in_pack")
                        Spacer()
                        TextField("12", text: $pouchesPerPack)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("planner_currency")
                        Spacer()
                        TextField("PLN", text: $currency)
                            .autocapitalization(.none)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Cost per pouch displayed at the very bottom, outside main containers
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("planner_cost_per_pouch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "estimated_cost_format".localized, calculatedCostPerPouch, currency.isEmpty ? dataStore.settings.currency : currency))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("planner")
            .onAppear {
                dailyPouches = String(dataStore.settings.plannerDailyLimit)
                sleepHours = String(dataStore.settings.sleepHours)
                packPrice = String(dataStore.settings.packPrice)
                pouchesPerPack = String(dataStore.settings.pouchesPerPack)
                currency = dataStore.settings.currency
            }
            .onChange(of: dailyPouches) { newValue in
                if let value = Int(newValue), value > 0 {
                    dataStore.settings.plannerDailyLimit = value
                    dataStore.save()
                    dataStore.resetNextPouchTimer()
                }
            }
            .onChange(of: sleepHours) { newValue in
                if let value = Double(newValue), value >= 0 && value <= 24 {
                    dataStore.settings.sleepHours = value
                    dataStore.save()
                    dataStore.resetNextPouchTimer()
                }
            }
            .onChange(of: packPrice) { newValue in
                if let value = Double(newValue), value >= 0 {
                    dataStore.settings.packPrice = value
                    dataStore.save()
                }
            }
            .onChange(of: pouchesPerPack) { newValue in
                if let value = Int(newValue), value > 0 {
                    dataStore.settings.pouchesPerPack = value
                    dataStore.save()
                }
            }
            .onChange(of: currency) { newValue in
                if !newValue.isEmpty {
                    dataStore.settings.currency = newValue
                    dataStore.save()
                }
            }
        }
    }
    
    private func formatTime(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        
        if h > 0 {
            return String(format: "%dh %dm", h, m)
        } else {
            return String(format: "%dm", m)
        }
    }
}

#Preview {
    PlannerView()
        .environmentObject(DataStore())
}

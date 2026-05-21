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
                Section(header: Text("planner_daily_limit_header")) {
                    TextField("planner_pouches_per_day", text: $dailyPouches)
                        .keyboardType(.numberPad)
                    
                    if let pouches = Int(dailyPouches), pouches > 0 {
                        HStack {
                            Text("planner_interval_preview")
                            Spacer()
                            Text(String(format: "%.1f h", intervalPerPouch))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("planner_active_hours_info")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("planner_active_hours")
                            Spacer()
                            Text(String(format: "%.1f h", activeHours))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("planner_sleep_duration")) {
                    TextField("planner_sleep_hours", text: $sleepHours)
                        .keyboardType(.decimalPad)
                    
                    Text("planner_sleep_hours_info")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("planner_pack_info")) {
                    TextField("planner_pack_price", text: $packPrice)
                        .keyboardType(.decimalPad)
                    
                    TextField("planner_pouches_in_pack", text: $pouchesPerPack)
                        .keyboardType(.numberPad)
                    
                    TextField("planner_currency", text: $currency)
                        .autocapitalization(.none)
                    
                    if let _ = Double(packPrice), let count = Int(pouchesPerPack), count > 0 {
                        HStack {
                            Text("planner_cost_per_pouch")
                            Spacer()
                            Text(String(format: "%.2f %@", calculatedCostPerPouch, currency.isEmpty ? dataStore.settings.currency : currency))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("planner_summary")) {
                    HStack {
                        Text("planner_pouches_per_day")
                        Spacer()
                        Text("\(dataStore.settings.plannerDailyLimit)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("planner_time_between_pouches")
                        Spacer()
                        Text(String(format: "%.1f h", intervalPerPouch))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("planner_sleep_hours")
                        Spacer()
                        Text(String(format: "%.1f h", dataStore.settings.sleepHours))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("planner_cost_per_pouch")
                        Spacer()
                        Text(String(format: "%.2f %@", dataStore.settings.costPerPouch, dataStore.settings.currency))
                            .foregroundColor(.secondary)
                    }
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
}

#Preview {
    PlannerView()
        .environmentObject(DataStore())
}

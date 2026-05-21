import SwiftUI

struct PlannerView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var dailyPouches: String = ""
    @State private var sleepStartHour: Double = 23
    @State private var sleepEndHour: Double = 7
    
    var activeHours: Double {
        var start = sleepEndHour
        var end = sleepStartHour
        if end < start {
            end += 24
        }
        return max(0, end - start)
    }
    
    var intervalPerPouch: Double {
        let pouches = Int(dailyPouches) ?? dataStore.settings.plannerDailyLimit
        if pouches <= 0 || activeHours <= 0 { return 0 }
        return activeHours / Double(pouches)
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
                
                Section(header: Text("planner_sleep_schedule")) {
                    VStack(alignment: .leading) {
                        Text("planner_sleep_start")
                        DatePicker("", selection: .constant(Date().addingTimeInterval((sleepStartHour - Calendar.current.component(.hour, from: Date())) * 3600)), in: ...Date(), displayedComponents: .hourAndMinute)
                            .onChange(of: sleepStartHour) { newValue in
                                dataStore.settings.sleepStartHour = newValue
                            }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("planner_sleep_end")
                        DatePicker("", selection: .constant(Date().addingTimeInterval((sleepEndHour - Calendar.current.component(.hour, from: Date())) * 3600)), in: ...Date(), displayedComponents: .hourAndMinute)
                            .onChange(of: sleepEndHour) { newValue in
                                dataStore.settings.sleepEndHour = newValue
                            }
                    }
                    
                    Text("planner_sleep_info")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                }
            }
            .navigationTitle("planner")
            .onAppear {
                dailyPouches = String(dataStore.settings.plannerDailyLimit)
                sleepStartHour = dataStore.settings.sleepStartHour
                sleepEndHour = dataStore.settings.sleepEndHour
            }
            .onChange(of: dailyPouches) { newValue in
                if let value = Int(newValue), value > 0 {
                    dataStore.settings.plannerDailyLimit = value
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

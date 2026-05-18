import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedPeriod: StatsPeriod = .day24
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Period Selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Chart
                if selectedPeriod == .all {
                    // Single value for "All"
                    let total = Double(dataStore.pouches.count)
                    VStack {
                        Text("Total Pouches")
                            .font(.headline)
                        Text("\(Int(total))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(getThemeColor())
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                } else {
                    let stats = dataStore.getStatsForPeriod(selectedPeriod)
                    let labels = getLabels(for: selectedPeriod)
                    
                    Chart {
                        ForEach(Array(stats.enumerated()), id: \.offset) { index, value in
                            BarMark(
                                x: Plots.value("Time", labels[index]),
                                y: Plots.value("Count", max(0, value))
                            )
                            .foregroundStyle(getThemeColor())
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartYScale(domain: 0...(stats.max() ?? 10))
                    .frame(height: 300)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                }
                
                // Total Nicotine
                VStack(alignment: .leading, spacing: 10) {
                    Text("Total Nicotine")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    let totalNicotine = dataStore.getTotalNicotineForPeriod(selectedPeriod)
                    Text("\(String(format: "%.2f", totalNicotine))g")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(getThemeColor())
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func getLabels(for period: StatsPeriod) -> [String] {
        switch period {
        case .day24:
            return (0..<24).map { "\($0):00" }
        case .week:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return (0..<7).map {
                let date = Calendar.current.date(byAdding: .day, value: -(6 - $0), to: Date())!
                return formatter.string(from: date)
            }
        case .month:
            return (1...30).map { "Day \($0)" }
        case .year:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return (0..<12).map {
                let date = Calendar.current.date(byAdding: .month, value: -(11 - $0), to: Date())!
                return formatter.string(from: date)
            }
        case .all:
            return ["Total"]
        }
    }
    
    func getThemeColor() -> Color {
        switch dataStore.settings.themeColor {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(DataStore())
}

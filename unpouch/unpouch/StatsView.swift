import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var selectedPoint: (date: Date, count: Int)? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if #available(iOS 16.0, *) {
                    Chart(dataStore.getStatsForPeriod(selectedPeriod), id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Count", item.count)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.blue.gradient)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Count", item.count)
                        )
                        .symbolSize(40)
                        .foregroundStyle(Color.blue)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: selectedPeriod == .day24 ? 6 : 1)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(), granularity: .day)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle().fill(Color.clear).contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let x = value.location.x
                                        let date = proxy.value(atX: x) as Date?
                                        if let date = date {
                                            let data = dataStore.getStatsForPeriod(selectedPeriod)
                                            if let closest = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                                selectedPoint = closest
                                            }
                                        }
                                    }
                                )
                        }
                    }
                    
                    if let point = selectedPoint {
                        VStack {
                            Text(point.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(point.count) pouches")
                                .font(.headline)
                                .padding(8)
                                .background(Color.white.shadow(radius: 5))
                                .cornerRadius(8)
                        }
                        .transition(.opacity.combined(with: .scale))
                        .padding(.top, 10)
                    }
                } else {
                    Text("Charts require iOS 16+")
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(NSLocalizedString("statistics", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

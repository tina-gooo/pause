//
//  StatsView.swift
//  One-Sec
//
//  Created by Christina Go on 10/26/26.
//


//
//  StatsView.swift
//  One-Sec
//
//  Screen Time-style stats: Week / Day chart + ranked list of apps.
//  Requires iOS 17 (chartXSelection).
//
import SwiftUI
import Charts

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("trackingEvents") private var trackingEventsData = "[]"

    private enum Period: String, CaseIterable {
        case week = "Week"
        case day = "Day"
    }

    private struct Bucket: Identifiable {
        let date: Date
        let opened: Int
        let closed: Int
        var id: Date { date }
        var total: Int { opened + closed }
    }

    private struct AppRow: Identifiable {
        let id: String
        let attempts: Int
        let opened: Int
        var closed: Int { max(attempts - opened, 0) }
    }

    @State private var period: Period = .day
    @State private var offset = 0            // 0 = current, -1 = previous, ...
    @State private var selectedDate: Date?

    private let openedColor = Color.orange
    private let closedColor = Color.blue
    private let cardColor = Color(white: 0.11)
    private var cal: Calendar { .current }

    // MARK: - Data

    private var events: [TrackingEvent] {
        (try? JSONDecoder().decode(
            [TrackingEvent].self,
            from: Data(trackingEventsData.utf8)
        )) ?? []
    }

    private var unit: Calendar.Component { period == .day ? .hour : .day }

    private var window: DateInterval {
        let today = cal.startOfDay(for: Date())
        switch period {
        case .day:
            let start = cal.date(byAdding: .day, value: offset, to: today)!
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            return DateInterval(start: start, end: end)
        case .week:
            // Trailing 7 days ending on the shown day.
            let end = cal.date(byAdding: .day, value: 1 + offset * 7, to: today)!
            let start = cal.date(byAdding: .day, value: -7, to: end)!
            return DateInterval(start: start, end: end)
        }
    }

    private var buckets: [Bucket] {
        let count = period == .day ? 24 : 7
        let inWindow = events.filter { window.contains($0.timestamp) }

        return (0..<count).map { i in
            let start = cal.date(byAdding: unit, value: i, to: window.start)!
            let end = cal.date(byAdding: unit, value: 1, to: start)!
            let slice = inWindow.filter { $0.timestamp >= start && $0.timestamp < end }

            let attempts = slice.filter { $0.type == "attempt" }.count
            let opened = slice.filter { $0.type == "continued" }.count
            return Bucket(date: start, opened: opened, closed: max(attempts - opened, 0))
        }
    }

    private var selectedBucket: Bucket? {
        guard let selectedDate else { return nil }
        return buckets.first {
            cal.isDate(selectedDate, equalTo: $0.date, toGranularity: unit)
        }
    }

    private var listInterval: DateInterval {
        guard let b = selectedBucket else { return window }
        let end = cal.date(byAdding: unit, value: 1, to: b.date)!
        return DateInterval(start: b.date, end: end)
    }

    private var rows: [AppRow] {
        let slice = events.filter { listInterval.contains($0.timestamp) }
        return Dictionary(grouping: slice, by: \.appID)
            .map { id, evs in
                AppRow(
                    id: id,
                    attempts: evs.filter { $0.type == "attempt" }.count,
                    opened: evs.filter { $0.type == "continued" }.count
                )
            }
            .filter { $0.attempts > 0 || $0.opened > 0 }
            .sorted { ($0.attempts, $1.id) > ($1.attempts, $0.id) }
    }

    // MARK: - Labels

    private var dateTitle: String {
        switch period {
        case .day:
            if offset == 0 { return "Today" }
            if offset == -1 { return "Yesterday" }
            return window.start.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        case .week:
            let last = cal.date(byAdding: .day, value: -1, to: window.end)!
            let f = Date.FormatStyle.dateTime.month(.abbreviated).day()
            return "\(window.start.formatted(f)) – \(last.formatted(f))"
        }
    }

    private var headerLabel: String {
        if selectedBucket != nil { return "ATTEMPTS" }
        return period == .week ? "DAILY AVERAGE" : "TOTAL"
    }

    private var headerValue: String {
        if let b = selectedBucket { return "\(b.total)" }
        let total = buckets.reduce(0) { $0 + $1.total }
        if period == .week {
            let avg = Double(total) / 7
            return avg == avg.rounded() ? "\(Int(avg))" : String(format: "%.1f", avg)
        }
        return "\(total)"
    }

    private var headerSubtitle: String {
        guard let b = selectedBucket else { return dateTitle }
        switch period {
        case .day:
            return "\(dateTitle), \(b.date.formatted(.dateTime.hour()))"
        case .week:
            return b.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Period", selection: $period) {
                        ForEach(Period.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    chartCard
                    listCard
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Pause Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: period) { _, _ in
            offset = 0
            selectedDate = nil
        }
        .onChange(of: offset) { _, _ in selectedDate = nil }
    }

    // MARK: - Chart card

    private var chartCard: some View {
        let data = buckets
        let yMax = max(4, data.map(\.total).max() ?? 0)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(headerLabel)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button { offset -= 1 } label: {
                    Image(systemName: "chevron.left")
                }
                Button { offset += 1 } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(offset >= 0)
            }
            .font(.body.weight(.semibold))

            Text(headerValue)
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            Chart(data) { b in
                BarMark(
                    x: .value("Time", b.date, unit: unit),
                    y: .value("Count", b.closed)
                )
                .foregroundStyle(by: .value("Outcome", "Closed out"))
                .opacity(opacity(for: b))

                BarMark(
                    x: .value("Time", b.date, unit: unit),
                    y: .value("Count", b.opened)
                )
                .foregroundStyle(by: .value("Outcome", "Opened"))
                .opacity(opacity(for: b))
            }
            .chartForegroundStyleScale([
                "Closed out": closedColor,
                "Opened": openedColor
            ])
            .chartLegend(.hidden)
            .chartXSelection(value: $selectedDate)
            .chartYScale(domain: 0...yMax)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) {
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.15))
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                if period == .day {
                    AxisMarks(values: .stride(by: .hour, count: 6)) {
                        AxisTick()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                } else {
                    AxisMarks(values: .stride(by: .day)) {
                        AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                    }
                }
            }
            .frame(height: 200)

            HStack(spacing: 16) {
                legendDot(closedColor, "Closed out")
                legendDot(openedColor, "Opened")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        }
        .padding(16)
        .background(cardColor, in: RoundedRectangle(cornerRadius: 14))
    }

    private func opacity(for b: Bucket) -> Double {
        guard let sel = selectedBucket else { return 1 }
        return sel.id == b.id ? 1 : 0.35
    }

    private func legendDot(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
        }
    }

    // MARK: - Ranked list

    private var listCard: some View {
        let items = rows
        let maxAttempts = max(items.map(\.attempts).max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 0) {
            Text("MOST TRIED")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            if items.isEmpty {
                Text("No attempts in this period.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, row in
                    appRow(rank: index + 1, row: row, maxAttempts: maxAttempts)
                    if index < items.count - 1 {
                        Divider().padding(.leading, 64)
                    }
                }
            }
        }
        .padding(16)
        .background(cardColor, in: RoundedRectangle(cornerRadius: 14))
    }

    private func appRow(rank: Int, row: AppRow, maxAttempts: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            appIcon(row.id)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(row.id.capitalized)
                        .font(.body.weight(.medium))
                    Spacer()
                    Text("\(row.attempts)")
                        .font(.body.weight(.semibold))
                }

                GeometryReader { geo in
                    let full = geo.size.width * CGFloat(row.attempts) / CGFloat(maxAttempts)
                    let total = max(row.attempts, 1)
                    HStack(spacing: 0) {
                        Rectangle().fill(closedColor)
                            .frame(width: full * CGFloat(row.closed) / CGFloat(total))
                        Rectangle().fill(openedColor)
                            .frame(width: full * CGFloat(min(row.opened, total)) / CGFloat(total))
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 5)

                Text("\(row.opened) opened · \(row.closed) closed out")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
    }

    private func appIcon(_ appID: String) -> some View {
        let gradient: LinearGradient
        switch appID {
        case "instagram":
            gradient = LinearGradient(
                colors: [.purple, .pink, .orange],
                startPoint: .bottomLeading, endPoint: .topTrailing
            )
        case "brave":
            gradient = LinearGradient(
                colors: [.orange, .red],
                startPoint: .top, endPoint: .bottom
            )
        default:
            gradient = LinearGradient(
                colors: [.gray, .gray.opacity(0.6)],
                startPoint: .top, endPoint: .bottom
            )
        }

        return RoundedRectangle(cornerRadius: 10)
            .fill(gradient)
            .frame(width: 36, height: 36)
            .overlay(
                Text(appID.prefix(1).uppercased())
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            )
    }
}

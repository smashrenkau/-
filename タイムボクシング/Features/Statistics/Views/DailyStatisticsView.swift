import SwiftUI
import Charts

struct DailyStatisticsView: View {
    @Bindable var viewModel: StatisticsViewModel
    let schedules: [ScheduleItem]

    private let lineColor = Color(hex: "#9B8FE9")
    private let gaugeColor = Color(hex: "#7EC8E3")

    private var dailyData: [DailyRating] {
        viewModel.dailyRatings(from: schedules)
    }

    private var todayAverage: Double? {
        viewModel.todayAverageRating(from: schedules)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                chartCard
                todayGaugeCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("日別集中度")
                    .font(.headline.bold())

                Spacer()

                Menu {
                    ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                        Button {
                            withAnimation { viewModel.selectedPeriod = period }
                        } label: {
                            HStack {
                                Text(period.rawValue)
                                if viewModel.selectedPeriod == period {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedPeriod.rawValue)
                            .font(.subheadline)
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.subheadline)
                    }
                    .foregroundStyle(lineColor)
                }
            }

            if dailyData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("データがありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                chartView
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var chartView: some View {
        Chart(dailyData) { item in
            LineMark(
                x: .value("日付", item.date, unit: .day),
                y: .value("集中度", item.averageRating)
            )
            .foregroundStyle(lineColor)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("日付", item.date, unit: .day),
                y: .value("集中度", item.averageRating)
            )
            .foregroundStyle(lineColor)
            .symbolSize(30)

            if let selectedDate = viewModel.selectedTooltipDate,
               Calendar.current.isDate(item.date, inSameDayAs: selectedDate) {
                RuleMark(x: .value("日付", item.date, unit: .day))
                    .foregroundStyle(.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, spacing: 8) {
                        tooltipView(date: item.date, rating: item.averageRating)
                    }
            }
        }
        .chartYScale(domain: 0...5)
        .chartYAxis {
            AxisMarks(values: [0, 1, 2, 3, 4, 5]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel {
                    if let intVal = value.as(Int.self) {
                        Text("\(intVal)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: xAxisStrideComponent, count: xAxisStrideCount)) { value in
                AxisGridLine()
                    .foregroundStyle(.clear)
                AxisValueLabel(format: xAxisDateFormat)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let origin = geometry[proxy.plotFrame!].origin
                                let x = value.location.x - origin.x
                                if let date: Date = proxy.value(atX: x) {
                                    let nearest = findNearestDataPoint(to: date)
                                    viewModel.selectedTooltipDate = nearest?.date
                                }
                            }
                            .onEnded { _ in
                                viewModel.selectedTooltipDate = nil
                            }
                    )
            }
        }
        .frame(height: 200)
    }

    private func tooltipView(date: Date, rating: Double) -> some View {
        VStack(spacing: 2) {
            Text(date, format: .dateTime.month().day())
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f点", rating))
                .font(.caption.bold())
                .foregroundStyle(lineColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    private func findNearestDataPoint(to date: Date) -> DailyRating? {
        dailyData.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    private var xAxisStrideComponent: Calendar.Component {
        switch viewModel.selectedPeriod {
        case .week: return .day
        case .month: return .day
        case .threeMonths: return .month
        case .sixMonths: return .month
        case .year: return .month
        case .fiveYears: return .year
        case .all: return .month
        }
    }

    private var xAxisStrideCount: Int {
        switch viewModel.selectedPeriod {
        case .week: return 1
        case .month: return 7
        case .threeMonths: return 1
        case .sixMonths: return 1
        case .year: return 2
        case .fiveYears: return 1
        case .all:
            let count = dailyData.count
            return max(count / 5, 1)
        }
    }

    private var xAxisDateFormat: Date.FormatStyle {
        switch viewModel.selectedPeriod {
        case .week:
            return .dateTime.month(.abbreviated).day()
        case .month:
            return .dateTime.month(.abbreviated).day()
        case .threeMonths, .sixMonths:
            return .dateTime.month(.abbreviated)
        case .year:
            return .dateTime.year().month(.abbreviated)
        case .fiveYears, .all:
            return .dateTime.year().month(.abbreviated)
        }
    }

    // MARK: - Today Gauge Card

    private var todayGaugeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本日の集中度")
                .font(.headline.bold())

            if let avg = todayAverage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        gaugeBar(value: avg)

                        Text(String(format: "%.1f点", avg))
                            .font(.title3.bold())
                            .foregroundStyle(gaugeColor)
                    }

                    HStack {
                        Text("1")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("5")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 2)
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "moon.zzz")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("まだ評価がありません")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private func gaugeBar(value: Double) -> some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let fillRatio = (value - 1.0) / 4.0
            let fillWidth = max(width * fillRatio, 0)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(gaugeColor.opacity(0.15))
                    .frame(height: 16)

                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [gaugeColor.opacity(0.6), gaugeColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth, height: 16)
                    .animation(.easeInOut(duration: 0.6), value: value)
            }
        }
        .frame(height: 16)
    }
}

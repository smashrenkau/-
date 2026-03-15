import SwiftUI
import SwiftData

enum StatisticsTab: String, CaseIterable {
    case daily = "日別統計"
    case task = "タスク別統計"
}

struct StatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allSchedules: [ScheduleItem]
    @State private var viewModel = StatisticsViewModel()
    @State private var selectedTab: StatisticsTab = .daily

    private let accentColor = Color(hex: "#9B8FE9")

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .opacity(0.3)

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .background(Color(hex: "#F4F3FA"))
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("統計")
                .font(.headline.bold())

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#6B6B8D"))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.85))
                        .clipShape(Circle())
                        .shadow(color: accentColor.opacity(0.1), radius: 4, y: 2)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: "#F4F3FA"))
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .daily:
            DailyStatisticsView(viewModel: viewModel, schedules: allSchedules)
        case .task:
            TaskStatisticsView()
        }
    }

    // MARK: - Custom Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(StatisticsTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab == .daily ? "chart.line.uptrend.xyaxis" : "square.grid.2x2")
                            .font(.system(size: 18))

                        Text(tab.rawValue)
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(selectedTab == tab ? accentColor : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        VStack {
                            Rectangle()
                                .fill(selectedTab == tab ? accentColor : .clear)
                                .frame(height: 2.5)
                            Spacer()
                        }
                    )
                }
            }
        }
        .background(.white)
        .shadow(color: .black.opacity(0.05), radius: 8, y: -2)
    }
}

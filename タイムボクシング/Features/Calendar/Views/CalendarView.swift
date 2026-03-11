import SwiftUI
import SwiftData

struct CalendarView: View {
    @State private var viewModel = CalendarViewModel()
    @State private var showScheduleForm = false
    @State private var showTaskForm = false
    @State private var showTaskList = false
    @Query private var allSchedules: [ScheduleItem]

    private let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    headerView
                    weekdayHeader

                    GeometryReader { geometry in
                        let headerHeight: CGFloat = 24
                        let gridSpacing: CGFloat = 2
                        let rows = CGFloat(viewModel.numberOfRows)
                        let cellHeight = (geometry.size.height - headerHeight - gridSpacing * (rows - 1)) / rows

                        ScrollView {
                            calendarGrid(cellHeight: max(cellHeight, 70))
                        }
                    }
                }

                FloatingAddButton(
                    onAddSchedule: { showScheduleForm = true },
                    onAddTask: { showTaskForm = true },
                    onShowTaskList: { showTaskList = true }
                )
                .padding(20)
            }
            .navigationDestination(for: Date.self) { date in
                DayScheduleView(date: date)
            }
            .fullScreenCover(isPresented: $showScheduleForm) {
                ScheduleFormView()
            }
            .sheet(isPresented: $showTaskForm) {
                TaskFormView()
                    .presentationDetents([.medium])
            }
            .fullScreenCover(isPresented: $showTaskList) {
                TaskListView()
            }
        }
    }

    // MARK: - Sub Views

    private var headerView: some View {
        HStack {
            Button { withAnimation { viewModel.goToPreviousMonth() } } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(viewModel.headerText)
                .font(.title2.bold())

            Spacer()

            Button { withAnimation { viewModel.goToNextMonth() } } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 4)
    }

    private func calendarGrid(cellHeight: CGFloat) -> some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(viewModel.daysInMonth.enumerated()), id: \.offset) { _, date in
                if let date {
                    NavigationLink(value: date) {
                        CalendarDayCellView(
                            day: viewModel.dayNumber(date),
                            isToday: viewModel.isToday(date),
                            schedules: viewModel.schedules(for: date, from: allSchedules),
                            cellHeight: cellHeight
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(height: cellHeight)
                }
            }
        }
        .padding(.horizontal, 4)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 {
                        withAnimation { viewModel.goToNextMonth() }
                    } else if value.translation.width > 50 {
                        withAnimation { viewModel.goToPreviousMonth() }
                    }
                }
        )
    }
}

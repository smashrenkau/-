import SwiftUI
import SwiftData

struct DayScheduleView: View {
    let date: Date
    @State private var viewModel: DayScheduleViewModel
    @State private var showScheduleForm = false
    @State private var showTimer = false
    @State private var selectedSchedule: ScheduleItem?
    @State private var editingSchedule: ScheduleItem?
    @Query private var allSchedules: [ScheduleItem]

    init(date: Date) {
        self.date = date
        _viewModel = State(initialValue: DayScheduleViewModel(date: date))
    }

    private var daySchedules: [ScheduleItem] {
        viewModel.schedulesForDate(allSchedules)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            timelineView

            FloatingAddButton(
                onAddSchedule: { showScheduleForm = true },
                onShowTimer: { showTimer = true }
            )
            .padding(20)
        }
        .navigationTitle(viewModel.headerText)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showScheduleForm) {
            ScheduleFormView(initialDate: date)
        }
        .fullScreenCover(item: $editingSchedule) { schedule in
            ScheduleFormView(schedule: schedule)
        }
        .fullScreenCover(isPresented: $showTimer) {
            TimerView()
        }
        .sheet(item: $selectedSchedule) { schedule in
            ScheduleDetailView(schedule: schedule) { editTarget in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    editingSchedule = editTarget
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Timeline

    private var timelineView: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    hoursGrid

                    let segmentLayouts = viewModel.computeSegmentLayouts(for: daySchedules)
                    let availableWidth = geometry.size.width - 56

                    ForEach(segmentLayouts, id: \.segment.id) { layout in
                        let boxWidth = availableWidth / CGFloat(layout.totalColumns)

                        TimeBoxView(segment: layout.segment)
                            .frame(
                                width: boxWidth - 2,
                                height: viewModel.boxHeight(for: layout.segment)
                            )
                            .offset(
                                x: 50 + boxWidth * CGFloat(layout.column),
                                y: viewModel.yOffset(for: layout.segment)
                            )
                            .onTapGesture {
                                selectedSchedule = layout.schedule
                            }
                    }
                }
                .frame(height: 25 * viewModel.hourHeight)
            }
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        viewModel.applyPinchScale(value.magnification)
                    }
                    .onEnded { _ in
                        viewModel.resetPinchScale()
                    }
            )
        }
    }

    private var hoursGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<25, id: \.self) { hour in
                HStack(alignment: .top, spacing: 4) {
                    Text(String(format: "%d:00", hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)

                    VStack(spacing: 0) {
                        Divider()
                        Spacer()
                    }
                }
                .frame(height: viewModel.hourHeight)
            }
        }
    }
}

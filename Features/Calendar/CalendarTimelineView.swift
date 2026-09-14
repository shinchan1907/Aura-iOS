import SwiftUI
import SwiftData

public struct CalendarTimelineView: View {
    @Query(sort: \TaskItem.dueDate) private var allTasks: [TaskItem]
    @Query(sort: \AttendanceRecord.punchInTime) private var attendanceRecords: [AttendanceRecord]
    
    @State private var selectedDate: Date = Date()
    @State private var displayMonth: Date = Date()
    
    public init() {}
    
    private var tasksForSelectedDate: [TaskItem] {
        allTasks.filter { task in
            guard let due = task.dueDate else { return false }
            return Calendar.current.isDate(due, inSameDayAs: selectedDate)
        }
    }
    
    private var attendanceForSelectedDate: AttendanceRecord? {
        attendanceRecords.first { record in
            Calendar.current.isDate(record.punchInTime, inSameDayAs: selectedDate)
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AuraColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AuraLayout.spacingLarge) {
                        // Month Header & Navigation
                        monthHeader
                        
                        // Interactive Calendar Grid
                        calendarGrid
                        
                        // Agenda for Selected Date
                        selectedDateAgenda
                    }
                    .padding(AuraLayout.screenPadding)
                }
            }
            .navigationTitle("Calendar & Timeline")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var monthHeader: some View {
        HStack {
            Text(displayMonth.formatted(.dateTime.month(.wide).year()))
                .font(AuraTypography.title2)
                .foregroundColor(AuraColors.textPrimary)
            
            Spacer()
            
            HStack(spacing: AuraLayout.spacingSmall) {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .padding(8)
                        .background(AuraColors.glassSurface)
                        .clipShape(Circle())
                }
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .padding(8)
                        .background(AuraColors.glassSurface)
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private var calendarGrid: some View {
        VStack(spacing: AuraLayout.spacingSmall) {
            // Weekday Headers
            HStack {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(AuraTypography.caption.bold())
                        .foregroundColor(AuraColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            let days = generateCalendarDays(for: displayMonth)
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        let hasTasks = allTasks.contains(where: { t in
                            guard let due = t.dueDate else { return false }
                            return Calendar.current.isDate(due, inSameDayAs: date)
                        })
                        let hasAttendance = attendanceRecords.contains(where: { r in
                            Calendar.current.isDate(r.punchInTime, inSameDayAs: date)
                        })
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = date
                                AuraHaptics.selection()
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(AuraTypography.subheadline.weight(isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? .white : (Calendar.current.isDateInToday(date) ? AuraColors.accent : AuraColors.textPrimary))
                                
                                HStack(spacing: 3) {
                                    if hasTasks {
                                        Circle()
                                            .fill(isSelected ? .white : AuraColors.accent)
                                            .frame(width: 4, height: 4)
                                    }
                                    if hasAttendance {
                                        Circle()
                                            .fill(isSelected ? .white : AuraColors.success)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                            }
                            .frame(height: 42)
                            .frame(maxWidth: .infinity)
                            .background(
                                isSelected ? AuraColors.accent : (Calendar.current.isDateInToday(date) ? AuraColors.accent.opacity(0.15) : Color.clear)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 42)
                    }
                }
            }
        }
        .glassCard()
    }
    
    private var selectedDateAgenda: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            Text("Agenda for \(selectedDate.formatted(date: .complete, time: .omitted))")
                .font(AuraTypography.headline)
                .foregroundColor(AuraColors.textPrimary)
            
            // Attendance Summary for Selected Date
            if let attendance = attendanceForSelectedDate {
                HStack(spacing: AuraLayout.spacingMedium) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(AuraColors.success)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Office Attendance")
                            .font(AuraTypography.headline)
                            .foregroundColor(AuraColors.textPrimary)
                        Text("Punched In: \(attendance.punchInTime.formatted(date: .omitted, time: .shortened)) • \(attendance.status.label)")
                            .font(AuraTypography.caption)
                            .foregroundColor(AuraColors.textSecondary)
                    }
                    Spacer()
                }
                .glassCard(padding: 12, borderColor: AuraColors.success.opacity(0.3))
            }
            
            // Tasks Scheduled for Selected Date
            if tasksForSelectedDate.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(AuraColors.textSecondary)
                    Text("No tasks scheduled for this day.")
                        .font(AuraTypography.subheadline)
                        .foregroundColor(AuraColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .glassCard()
            } else {
                ForEach(tasksForSelectedDate) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        TaskRowView(task: task)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: displayMonth) {
            displayMonth = newMonth
        }
    }
    
    private func generateCalendarDays(for month: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        let weekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: weekday)
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
}

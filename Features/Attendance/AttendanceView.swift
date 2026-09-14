import SwiftUI
import SwiftData
import CoreLocation

public struct AttendanceView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \AttendanceRecord.punchInTime, order: .reverse)
    private var allAttendanceRecords: [AttendanceRecord]
    
    @Query private var officeLocations: [OfficeLocation]
    
    @State private var locationManager = LocationManager.shared
    @State private var showingOfficeConfig = false
    @State private var showingManualPunchSheet = false
    @State private var selectedMonth: Date = Date()
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var liveShiftTimeSeconds: TimeInterval = 0
    
    public init() {}
    
    private var activeOffice: OfficeLocation? {
        officeLocations.first
    }
    
    private var activeRecord: AttendanceRecord? {
        allAttendanceRecords.first(where: { $0.punchOutTime == nil })
    }
    
    private var monthlyRecords: [AttendanceRecord] {
        let calendar = Calendar.current
        return allAttendanceRecords.filter { record in
            calendar.isDate(record.punchInTime, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var totalMonthlyHours: Double {
        monthlyRecords.reduce(0.0) { $0 + ($1.totalDurationSeconds / 3600.0) }
    }
    
    private var completedPunchDays: Int {
        monthlyRecords.filter { $0.punchOutTime != nil }.count
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Vibrant background ambient glow
                AuraColors.background.ignoresSafeArea()
                
                LinearGradient(
                    colors: [
                        activeRecord != nil ? AuraColors.cyanAccent.opacity(0.12) : AuraColors.accent.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AuraLayout.spacingLarge) {
                        
                        // Header GPS & Status Card
                        locationStatusCard
                        
                        // Main Punch Action Control
                        punchControlCard
                        
                        // Monthly Overview & Attendance Metrics
                        monthlyMetricsSection
                        
                        // Interactive Attendance Calendar Grid
                        monthlyCalendarView
                        
                        // Detailed Punch History
                        punchHistorySection
                    }
                    .padding(AuraLayout.screenPadding)
                }
            }
            .navigationTitle("Office Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingOfficeConfig = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.headline)
                            .foregroundColor(AuraColors.accent)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingManualPunchSheet = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(AuraColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingOfficeConfig) {
                OfficeConfigSheet(isPresented: $showingOfficeConfig, office: activeOffice)
            }
            .sheet(isPresented: $showingManualPunchSheet) {
                ManualPunchSheet(isPresented: $showingManualPunchSheet, office: activeOffice)
            }
            .onAppear {
                locationManager.requestPermissions()
                if let office = activeOffice {
                    locationManager.evaluateLocationAgainstOffice(office: office)
                }
                updateLiveTimer()
            }
            .onReceive(timer) { _ in
                updateLiveTimer()
            }
        }
    }
    
    // MARK: - Location Status Card
    private var locationStatusCard: some View {
        HStack(spacing: AuraLayout.spacingMedium) {
            Image(systemName: locationManager.isAtOffice ? "building.2.crop.circle.fill" : "location.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(locationManager.isAtOffice ? AuraColors.success : AuraColors.warning)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activeOffice?.name ?? "Office Location Not Set")
                    .font(AuraTypography.headline)
                    .foregroundColor(AuraColors.textPrimary)
                
                if let dist = locationManager.distanceToOfficeMeters {
                    Text(dist <= (activeOffice?.radiusMeters ?? 100) ? "Within Office Geofence 🟢" : "\(Int(dist))m away from office 📍")
                        .font(AuraTypography.caption)
                        .foregroundColor(AuraColors.textSecondary)
                } else {
                    Text("Tap ⚙️ to configure office GPS coordinates")
                        .font(AuraTypography.caption)
                        .foregroundColor(AuraColors.textSecondary)
                }
            }
            Spacer()
            
            Button(action: {
                if let office = activeOffice {
                    locationManager.evaluateLocationAgainstOffice(office: office)
                }
            }) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .padding(8)
                    .background(AuraColors.glassSurface)
                    .clipShape(Circle())
            }
        }
        .glassCard(borderColor: locationManager.isAtOffice ? AuraColors.success.opacity(0.4) : AuraColors.glassBorder)
    }
    
    // MARK: - Punch Control Card
    private var punchControlCard: some View {
        VStack(spacing: AuraLayout.spacingMedium) {
            if let record = activeRecord {
                // Active Punch-In Status View
                VStack(spacing: AuraLayout.spacingSmall) {
                    HStack {
                        Circle()
                            .fill(AuraColors.cyanAccent)
                            .frame(width: 10, height: 10)
                        Text("SHIFT IN PROGRESS")
                            .font(AuraTypography.stats)
                            .foregroundColor(AuraColors.cyanAccent)
                    }
                    
                    Text(formatTimeInterval(liveShiftTimeSeconds))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(AuraColors.textPrimary)
                    
                    Text("Punched in at \(record.punchInTime.formatted(date: .omitted, time: .shortened))")
                        .font(AuraTypography.subheadline)
                        .foregroundColor(AuraColors.textSecondary)
                }
                
                Button(action: {
                    locationManager.punchOut(context: modelContext, record: record, office: activeOffice)
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("PUNCH OUT")
                            .font(AuraTypography.title2.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AuraColors.punchOutGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusMedium))
                    .shadow(color: AuraColors.destructive.opacity(0.3), radius: 10, y: 4)
                }
            } else {
                // Ready to Punch In View
                VStack(spacing: AuraLayout.spacingSmall) {
                    Text("Ready for Work?")
                        .font(AuraTypography.headline)
                        .foregroundColor(AuraColors.textSecondary)
                    Text("Mark your office punch in timestamp.")
                        .font(AuraTypography.subheadline)
                        .foregroundColor(AuraColors.textSecondary)
                }
                
                Button(action: {
                    _ = locationManager.punchIn(context: modelContext, office: activeOffice)
                }) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("PUNCH IN")
                            .font(AuraTypography.title2.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AuraColors.punchInGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusMedium))
                    .shadow(color: AuraColors.cyanAccent.opacity(0.4), radius: 12, y: 4)
                }
            }
        }
        .glassCard(
            borderColor: activeRecord != nil ? AuraColors.cyanAccent.opacity(0.5) : AuraColors.accent.opacity(0.3),
            glowColor: activeRecord != nil ? AuraColors.cyanAccent : AuraColors.accent
        )
    }
    
    // MARK: - Monthly Metrics Section
    private var monthlyMetricsSection: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            HStack {
                Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
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
            
            HStack(spacing: AuraLayout.spacingMedium) {
                metricTile(title: "Days Attended", value: "\(completedPunchDays)", icon: "calendar.badge.clock", color: AuraColors.success)
                metricTile(title: "Total Hours", value: String(format: "%.1fh", totalMonthlyHours), icon: "clock.fill", color: AuraColors.cyanAccent)
                let avg = completedPunchDays > 0 ? totalMonthlyHours / Double(completedPunchDays) : 0
                metricTile(title: "Avg Shift", value: String(format: "%.1fh", avg), icon: "chart.line.uptrend.xyaxis", color: AuraColors.projectPurple)
            }
        }
    }
    
    private func metricTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
            Text(value)
                .font(AuraTypography.title1)
                .foregroundColor(AuraColors.textPrimary)
            Text(title)
                .font(AuraTypography.caption)
                .foregroundColor(AuraColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 12)
    }
    
    // MARK: - Monthly Calendar Grid
    private var monthlyCalendarView: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            Text("Monthly Attendance Grid")
                .font(AuraTypography.headline)
                .foregroundColor(AuraColors.textPrimary)
            
            let daysInMonth = generateCalendarGrid(for: selectedMonth)
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            
            // Weekday Headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(AuraTypography.caption.bold())
                        .foregroundColor(AuraColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        let record = recordForDate(date)
                        VStack(spacing: 2) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(AuraTypography.subheadline.weight(record != nil ? .bold : .regular))
                                .foregroundColor(Calendar.current.isDateInToday(date) ? AuraColors.accent : AuraColors.textPrimary)
                            
                            if let record = record {
                                Circle()
                                    .fill(statusColor(for: record))
                                    .frame(width: 6, height: 6)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(height: 38)
                        .frame(maxWidth: .infinity)
                        .background(
                            Calendar.current.isDateInToday(date) ? AuraColors.accent.opacity(0.15) : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall))
                    } else {
                        Color.clear.frame(height: 38)
                    }
                }
            }
        }
        .glassCard()
    }
    
    // MARK: - Punch History Section
    private var punchHistorySection: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingMedium) {
            Text("Punch Activity Log")
                .font(AuraTypography.headline)
                .foregroundColor(AuraColors.textPrimary)
            
            if monthlyRecords.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(AuraColors.textSecondary)
                    Text("No punch records for this month")
                        .font(AuraTypography.subheadline)
                        .foregroundColor(AuraColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .glassCard()
            } else {
                ForEach(monthlyRecords) { record in
                    HStack(spacing: AuraLayout.spacingMedium) {
                        Circle()
                            .fill(statusColor(for: record))
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.punchInTime.formatted(date: .abbreviated, time: .shortened))
                                .font(AuraTypography.headline)
                                .foregroundColor(AuraColors.textPrimary)
                            
                            if let punchOut = record.punchOutTime {
                                Text("Punch Out: \(punchOut.formatted(date: .omitted, time: .shortened)) • \(formatTimeInterval(record.totalDurationSeconds))")
                                    .font(AuraTypography.caption)
                                    .foregroundColor(AuraColors.textSecondary)
                            } else {
                                Text("Currently Punched In 🟢")
                                    .font(AuraTypography.caption)
                                    .foregroundColor(AuraColors.cyanAccent)
                            }
                        }
                        Spacer()
                        
                        Text(record.status.label)
                            .font(AuraTypography.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(for: record).opacity(0.15))
                            .foregroundColor(statusColor(for: record))
                            .clipShape(Capsule())
                    }
                    .glassCard(padding: 12)
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func updateLiveTimer() {
        if let active = activeRecord {
            liveShiftTimeSeconds = active.currentDuration
        } else {
            liveShiftTimeSeconds = 0
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    private func recordForDate(_ date: Date) -> AttendanceRecord? {
        monthlyRecords.first { record in
            Calendar.current.isDate(record.punchInTime, inSameDayAs: date)
        }
    }
    
    private func statusColor(for record: AttendanceRecord) -> Color {
        guard record.punchOutTime != nil else { return AuraColors.cyanAccent }
        switch record.status {
        case .present: return AuraColors.success
        case .overtime: return AuraColors.projectPurple
        case .halfDay: return AuraColors.warning
        case .absent, .inProgress: return AuraColors.accent
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func generateCalendarGrid(for month: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        let weekday = calendar.component(.weekday, from: firstDay) - 1
        var grid: [Date?] = Array(repeating: nil, count: weekday)
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                grid.append(date)
            }
        }
        return grid
    }
}

// MARK: - Office Config Sheet
struct OfficeConfigSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    var office: OfficeLocation?
    
    @State private var name: String = "Main Office"
    @State private var latitudeString: String = "0.0"
    @State private var longitudeString: String = "0.0"
    @State private var radius: Double = 100.0
    @State private var autoPunchIn = true
    @State private var autoPunchOut = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Office Location Info") {
                    TextField("Office Name", text: $name)
                    
                    Button("📍 Use Current GPS Location") {
                        if let loc = LocationManager.shared.currentLocation {
                            latitudeString = "\(loc.coordinate.latitude)"
                            longitudeString = "\(loc.coordinate.longitude)"
                        }
                    }
                    .foregroundColor(AuraColors.accent)
                    
                    HStack {
                        Text("Latitude")
                        Spacer()
                        TextField("Lat", text: $latitudeString)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Longitude")
                        Spacer()
                        TextField("Lon", text: $longitudeString)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Geofence Radius") {
                    VStack(alignment: .leading) {
                        Text("Radius: \(Int(radius)) meters")
                        Slider(value: $radius, in: 50...500, step: 25)
                    }
                }
                
                Section("Automated Geofence Actions") {
                    Toggle("Auto-remind on Entry", isOn: $autoPunchIn)
                    Toggle("Auto-remind on Exit", isOn: $autoPunchOut)
                }
            }
            .navigationTitle("Configure Office GPS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveOffice() }
                }
            }
            .onAppear {
                if let office = office {
                    name = office.name
                    latitudeString = "\(office.latitude)"
                    longitudeString = "\(office.longitude)"
                    radius = office.radiusMeters
                    autoPunchIn = office.autoPunchInEnabled
                    autoPunchOut = office.autoPunchOutEnabled
                }
            }
        }
    }
    
    private func saveOffice() {
        let lat = Double(latitudeString) ?? 0.0
        let lon = Double(longitudeString) ?? 0.0
        
        if let office = office {
            office.name = name
            office.latitude = lat
            office.longitude = lon
            office.radiusMeters = radius
            office.autoPunchInEnabled = autoPunchIn
            office.autoPunchOutEnabled = autoPunchOut
            office.isConfigured = true
            LocationManager.shared.updateOfficeGeofence(office: office)
        } else {
            let newOffice = OfficeLocation(
                name: name,
                latitude: lat,
                longitude: lon,
                radiusMeters: radius,
                autoPunchInEnabled: autoPunchIn,
                autoPunchOutEnabled: autoPunchOut,
                isConfigured: true
            )
            modelContext.insert(newOffice)
            LocationManager.shared.updateOfficeGeofence(office: newOffice)
        }
        AuraHaptics.success()
        isPresented = false
    }
}

// MARK: - Manual Punch Sheet
struct ManualPunchSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    var office: OfficeLocation?
    
    @State private var punchInDate = Date()
    @State private var punchOutDate = Date()
    @State private var hasPunchOut = true
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Punch In Time") {
                    DatePicker("Punch In", selection: $punchInDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Punch Out Time") {
                    Toggle("Set Punch Out", isOn: $hasPunchOut)
                    if hasPunchOut {
                        DatePicker("Punch Out", selection: $punchOutDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes (e.g. Worked from home)", text: $notes)
                }
            }
            .navigationTitle("Manual Punch Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveManualPunch() }
                }
            }
        }
    }
    
    private func saveManualPunch() {
        let record = AttendanceRecord(
            date: punchInDate,
            punchInTime: punchInDate,
            punchOutTime: hasPunchOut ? punchOutDate : nil,
            locationName: office?.name ?? "Office",
            notes: notes
        )
        record.recalculateStatus()
        modelContext.insert(record)
        AuraHaptics.success()
        isPresented = false
    }
}

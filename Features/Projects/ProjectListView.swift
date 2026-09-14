import SwiftUI
import SwiftData

public struct ProjectListView: View {
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingCreateProject = false
    @State private var showArchivedFilter = false
    
    public init() {}
    
    private var displayedProjects: [Project] {
        projects.filter { $0.isArchived == showArchivedFilter }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AuraBackgroundView()
                
                VStack(spacing: 0) {
                    // Filter Bar
                    Picker("Filter", selection: $showArchivedFilter) {
                        Text("Active Projects").tag(false)
                        Text("Archived").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AuraLayout.screenPadding)
                    .padding(.vertical, AuraLayout.spacingSmall)
                    
                    if displayedProjects.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AuraLayout.spacingMedium) {
                                ForEach(displayedProjects) { project in
                                    NavigationLink(value: project) {
                                        ProjectCardView(project: project)
                                    }
                                }
                            }
                            .padding(AuraLayout.screenPadding)
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingCreateProject = true }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                            .foregroundColor(AuraColors.accent)
                    }
                }
            }
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
            .sheet(isPresented: $showingCreateProject) {
                CreateProjectSheet(isPresented: $showingCreateProject)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AuraLayout.spacingMedium) {
            Spacer()
            Image(systemName: showArchivedFilter ? "archivebox" : "folder")
                .font(.system(size: 54))
                .foregroundColor(AuraColors.accent.opacity(0.5))
            Text(showArchivedFilter ? "No Archived Projects" : "No Projects Yet")
                .font(AuraTypography.title2)
                .foregroundColor(AuraColors.textPrimary)
            Text(showArchivedFilter ? "Archived projects will appear here." : "Group tasks into structured projects with milestones and progress tracking.")
                .font(AuraTypography.body)
                .foregroundColor(AuraColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AuraLayout.spacingXLarge)
            
            if !showArchivedFilter {
                Button("Create Project") {
                    showingCreateProject = true
                }
                .buttonStyle(.auraPrimary)
                .padding(.top, AuraLayout.spacingLarge)
            }
            Spacer()
        }
    }
}

struct ProjectCardView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
            HStack {
                Image(systemName: project.iconName)
                    .font(.title3)
                    .foregroundColor(Color(hex: project.colorHex) ?? AuraColors.accent)
                Spacer()
                Text("\(project.tasks.count) tasks")
                    .font(AuraTypography.stats)
                    .foregroundColor(AuraColors.textSecondary)
            }
            
            Spacer(minLength: AuraLayout.spacingMedium)
            
            Text(project.title)
                .font(AuraTypography.headline)
                .foregroundColor(AuraColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AuraColors.glassSurface)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(Color(hex: project.colorHex) ?? AuraColors.accent)
                        .frame(width: geo.size.width * CGFloat(project.derivedProgress), height: 6)
                }
            }
            .frame(height: 6)
        }
        .glassCard(borderColor: Color(hex: project.colorHex)?.opacity(0.3) ?? AuraColors.glassBorder)
    }
}

struct CreateProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var descriptionText = ""
    @State private var selectedColorHex = "#6159F7"
    @State private var selectedIcon = "folder.fill"
    
    private let availableColors = ["#6159F7", "#1EC7F2", "#26D98C", "#FF9E1A", "#FA4362", "#A659F7"]
    private let availableIcons = ["folder.fill", "briefcase.fill", "hammer.fill", "rocket.fill", "lightbulb.fill", "terminal.fill"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AuraBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AuraLayout.spacingLarge) {
                        VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
                            Text("Project Info")
                                .font(AuraTypography.headline)
                                .foregroundColor(AuraColors.textSecondary)
                            AuraGlassTextField(placeholder: "Project Title", text: $title, iconName: "folder.fill")
                            AuraGlassTextField(placeholder: "Description (Optional)", text: $descriptionText, iconName: "text.alignleft")
                        }
                        .glassCard()
                        
                        VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
                            Text("Theme Color")
                                .font(AuraTypography.headline)
                                .foregroundColor(AuraColors.textSecondary)
                            
                            HStack(spacing: AuraLayout.spacingMedium) {
                                ForEach(availableColors, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex) ?? .blue)
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColorHex == hex ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColorHex = hex
                                            AuraHaptics.selection()
                                        }
                                }
                            }
                        }
                        .glassCard()
                        
                        VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
                            Text("Workspace Icon")
                                .font(AuraTypography.headline)
                                .foregroundColor(AuraColors.textSecondary)
                            
                            HStack(spacing: AuraLayout.spacingMedium) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? (Color(hex: selectedColorHex) ?? AuraColors.accent) : AuraColors.textSecondary)
                                        .padding(10)
                                        .background(selectedIcon == icon ? AuraColors.glassSurface : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AuraLayout.cornerRadiusSmall)
                                                .stroke(selectedIcon == icon ? (Color(hex: selectedColorHex) ?? AuraColors.accent) : Color.clear, lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            selectedIcon = icon
                                            AuraHaptics.selection()
                                        }
                                }
                            }
                        }
                        .glassCard()
                        
                        AuraGlassButton(title: "Create Workspace", iconName: "folder.badge.plus") {
                            createProject()
                        }
                    }
                    .padding(AuraLayout.screenPadding)
                }
            }
            .navigationTitle("New Workspace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
    
    private func createProject() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let project = Project(
            title: trimmed,
            descriptionText: descriptionText,
            iconName: selectedIcon,
            colorHex: selectedColorHex
        )
        modelContext.insert(project)
        AuraHaptics.success()
        isPresented = false
    }
}

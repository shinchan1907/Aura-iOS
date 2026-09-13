import SwiftUI
import SwiftData

public struct ProjectListView: View {
    @Query(sort: \Project.createdAt) private var projects: [Project]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingCreateProject = false
    @State private var newProjectTitle = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AuraColors.background.ignoresSafeArea()
                
                if projects.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AuraLayout.spacingMedium) {
                            ForEach(projects) { project in
                                NavigationLink(value: project) {
                                    ProjectCardView(project: project)
                                }
                            }
                        }
                        .padding(AuraLayout.screenPadding)
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
                Text("Project Detail for \(project.title)")
            }
            .alert("New Project", isPresented: $showingCreateProject) {
                TextField("Project Title", text: $newProjectTitle)
                Button("Cancel", role: .cancel) {
                    newProjectTitle = ""
                }
                Button("Create") {
                    createProject()
                }
            } message: {
                Text("Enter a name for your new project.")
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AuraLayout.spacingMedium) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(AuraColors.accent.opacity(0.5))
            Text("No Projects Yet")
                .font(AuraTypography.title2)
                .foregroundColor(AuraColors.textPrimary)
            Text("Create a project to group related tasks.")
                .font(AuraTypography.body)
                .foregroundColor(AuraColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Create Project") {
                showingCreateProject = true
            }
            .buttonStyle(.auraPrimary)
            .padding(.top, AuraLayout.spacingLarge)
        }
        .padding(AuraLayout.screenPadding)
    }
    
    private func createProject() {
        let trimmed = newProjectTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let project = Project(title: trimmed)
        modelContext.insert(project)
        newProjectTitle = ""
        AuraHaptics.success()
    }
}

struct ProjectCardView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: AuraLayout.spacingSmall) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(Color(hex: project.colorHex) ?? AuraColors.accent)
                Spacer()
                Text("\(project.tasks.count)")
                    .font(AuraTypography.stats)
                    .foregroundColor(AuraColors.textSecondary)
            }
            
            Spacer(minLength: AuraLayout.spacingMedium)
            
            Text(project.title)
                .font(AuraTypography.headline)
                .foregroundColor(AuraColors.textPrimary)
                .lineLimit(2)
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AuraColors.tertiaryBackground)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(Color(hex: project.colorHex) ?? AuraColors.accent)
                        .frame(width: geo.size.width * CGFloat(project.progress), height: 6)
                }
            }
            .frame(height: 6)
        }
        .auraCard()
    }
}

import WidgetKit
import SwiftUI
import SwiftData

struct TaskProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: .now, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent,
                  in context: Context) async -> TaskEntry {
        TaskEntry(date: .now, configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent,
                  in context: Context) async -> Timeline<TaskEntry> {
        let entry = TaskEntry(date: .now, configuration: configuration)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        return Timeline(entries: [entry], policy: .after(next))
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct FinlineWidgetEntryView: View {
    let entry: TaskEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView()
            case .systemMedium:
                MediumWidgetView()
            case .systemLarge:
                LargeWidgetView()
            default:
                MediumWidgetView()
            }
        }
        .containerBackground(for: .widget) {
//            LinearGradient(
//                colors: [Color(red: 0.8, green: 0.9, blue: 1.0),
//                        Color(red: 0.9, green: 0.95, blue: 1.0)],
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
            colorScheme == .dark ? Color.darkModeWidget : Color.secondary
        }
    }
}

struct FinlineWidget: Widget {
    let kind: String = "FinlineWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: TaskProvider()
        ) { entry in
            FinlineWidgetEntryView(entry: entry)
                .modelContainer(sharedContainer)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .configurationDisplayName("Today's Tasks")
        .description("View your tasks for today")
    }
}

private let sharedContainer: ModelContainer = {
    let schema = Schema([
        Goal.self,
        GoalTask.self,
    ])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        allowsSave: true,
        groupContainer: .identifier("group.c7.finline")
    )

    do {
        return try ModelContainer(for: schema, configurations: [config])
    } catch {
        fatalError("Could not create ModelContainer for widget: \(error)")
    }
}()

struct SmallWidgetView: View {
    @Query private var allTasks: [GoalTask]
    
    private var todayTasks: [GoalTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return allTasks.filter { task in
            task.workingTime >= today && task.workingTime < tomorrow
        }
    }
    
    private var activeTasks: [GoalTask] {
        todayTasks.filter { !$0.isCompleted }
    }

    var body: some View {
        VStack(spacing: 8) {
            
            VStack(spacing: 2) {
                Text("today")
                    .font(.system(size: 10))
//                    .foregroundColor(.black.opacity(0.6))
                
                Text("\(activeTasks.count)")
                    .font(.system(size: 40, weight: .bold))
//                    .foregroundColor(.black)
                
                Text("Tasks")
                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundColor(.black)
            }
            
            Image("penguinWidget")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .clipped()
        }
        .padding(12)
    }
}

struct MediumWidgetView: View {
    @Query private var allTasks: [GoalTask]
    
    private var todayTasks: [GoalTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return allTasks.filter { task in
            task.workingTime >= today && task.workingTime < tomorrow
        }.sorted { $0.workingTime < $1.workingTime }
    }
    
    private var activeTasks: [GoalTask] {
        todayTasks.filter { !$0.isCompleted }
    }
    
    private var groupedTasks: [(goal: Goal?, tasks: [GoalTask])] {
        var groups: [(goal: Goal?, tasks: [GoalTask])] = []
        
        for task in activeTasks {
            if let index = groups.firstIndex(where: { $0.goal?.id == task.goal?.id }) {
                groups[index].tasks.append(task)
            } else {
                groups.append((goal: task.goal, tasks: [task]))
            }
        }
        
        for i in groups.indices {
            groups[i].tasks.sort { t1, t2 in
                t1.workingTime < t2.workingTime
            }
        }
        
        var sortedGroups = groups
        sortedGroups.sort { g1, g2 in
            let name1 = g1.goal?.name ?? ""
            let name2 = g2.goal?.name ?? ""
            return name1 < name2
        }
        
        return sortedGroups
    }
    
    
    
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack{
                VStack {
                    Spacer()
                        .frame(height: 76)
                    Image("penguinWidget")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        //.padding(.top, 64)
                       // .clipped()
                }
                VStack(alignment: .leading, spacing: 0)  {
                    Spacer()
                        .frame(height: 16)
                    Text("today you got")
                        .font(.system(size: 12, weight: .medium))
                        .italic()
                        
                    
                    Text("\(activeTasks.count) Tasks")
                        .font(.system(size: 32, weight: .bold))
                        
                    Spacer()
                }
//                .padding(.bottom,92)
            }
            .frame(height: 150)
           // .padding(.top, 20)
            // Task List
            VStack(alignment: .leading, spacing: 12) {
                
                if activeTasks.isEmpty {
                    VStack(spacing: 4) {
                        Text("No More Task")
                            .font(.system(.headline, weight: .semibold))
                           
                        Text("Do you have task? add it!")
                            .font(.caption)
                           
                    }
                    //Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 4){
                        if let firstGroup = groupedTasks.first {
                            if let goal = firstGroup.goal {
                                HStack {
                                    Text(goal.name)
                                        .font(.caption)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                    
                                }
                            }
                            
                            ForEach(firstGroup.tasks.prefix(2)) { task in
                                TaskRowView(task: task)
                            }
                            
                            if firstGroup.tasks.count > 2 {
                                Text("+\(firstGroup.tasks.count - 2) more")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                 
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LargeWidgetView: View {
    @Query private var allTasks: [GoalTask]
    
    private var todayTasks: [GoalTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return allTasks.filter { task in
            task.workingTime >= today && task.workingTime < tomorrow
        }.sorted { $0.workingTime < $1.workingTime }
    }
    
    private var activeTasks: [GoalTask] {
        todayTasks.filter { !$0.isCompleted }
    }
    
    private var groupedTasks: [(goal: Goal?, tasks: [GoalTask])] {
            var groups: [(goal: Goal?, tasks: [GoalTask])] = []
            
            for task in activeTasks {
                if let index = groups.firstIndex(where: { $0.goal?.id == task.goal?.id }) {
                    groups[index].tasks.append(task)
                } else {
                    groups.append((goal: task.goal, tasks: [task]))
                }
            }
            
            // Sort tasks within each group by working time
            for i in groups.indices {
                groups[i].tasks.sort { t1, t2 in
                    t1.workingTime < t2.workingTime
                }
            }
            
            // Sort groups by Goal Name
            var sortedGroups = groups
            sortedGroups.sort { g1, g2 in
                let name1 = g1.goal?.name ?? ""
                let name2 = g2.goal?.name ?? ""
                return name1 < name2
            }
            
            return sortedGroups
        }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image("penguinWidget")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("today you got")
                        .font(.system(size: 12, weight: .medium))
                        .italic()
                    
                    Text("\(activeTasks.count) Tasks")
                        .font(.system(size: 32, weight: .bold))
                }
                Spacer()
            }
            
            if activeTasks.isEmpty {
                Spacer()
                VStack(spacing: 4) {
                    Text("No More Task")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Do you have task? add it!")
                        .font(.system(size: 14))
                }
                Spacer()
            } else {
                GroupedTaskList(groupedTasks: groupedTasks, activeTasksCount: activeTasks.count)
            }
        }
//        .padding(16)
    }
}

struct GroupedTaskList: View {
    let groupedTasks: [(goal: Goal?, tasks: [GoalTask])]
    let activeTasksCount: Int
    
    private let limit = 3
    
    private var limitedGroups: [(goal: Goal?, tasks: [GoalTask])] {
        var result: [(goal: Goal?, tasks: [GoalTask])] = []
        var totalTasksAdded = 0
        
        for group in groupedTasks {
            let remainingSlots = limit - totalTasksAdded
            guard remainingSlots > 0 else { break }
            
            let tasksToTake = min(group.tasks.count, remainingSlots)
            
            if tasksToTake > 0 {
                let newGroup = (goal: group.goal, tasks: Array(group.tasks.prefix(tasksToTake)))
                result.append(newGroup)
                totalTasksAdded += tasksToTake
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
          
            ForEach(Array(limitedGroups.enumerated()), id: \.offset) { _, group in
                
                VStack(alignment: .leading, spacing: 4) {
                   
                    if let goal = group.goal {
                        HStack {
                            Text(goal.name)
                                .font(.subheadline)
    
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 4)
                    } else {
                        Text("Other Tasks")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.leading, 4)
                    }
                    
                    ForEach(group.tasks) { task in
                        TaskRowView(task: task)
                    }
                }
                .padding(.bottom, 8)
            }
            
            Spacer(minLength: 0)
            
            let totalRemaining = activeTasksCount - limitedGroups.reduce(0) { $0 + $1.tasks.count }
            if totalRemaining > 0 {
                Text("+\(totalRemaining) more tasks")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
}
struct TaskRowView: View {
    let task: GoalTask
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: task.workingTime)
        let end = formatter.string(from: task.workingTime.addingTimeInterval(TimeInterval(task.focusDuration * 60)))
        return "\(start) - \(end)"
    }
    
    var durationString: String {
        let hours = task.focusDuration / 60
        let minutes = task.focusDuration % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeString)
                    .font(.caption2)
                
                Text(task.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
            
            Spacer()
            
            Text(durationString)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
       .padding(8)
       .background(colorScheme == .light ? Color.white : Color.black)
        .cornerRadius(20)
    }
}

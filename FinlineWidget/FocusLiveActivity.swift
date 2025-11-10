//
//  FocusLiveActivity.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 10/11/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            VStack(spacing: 8) {
                Text(context.attributes.goalName)
                    .font(.headline)
                Text(context.state.taskTitle)
                    .font(.subheadline)
                Text(TimeFormatter.format(seconds: context.state.remainingTime))
                    .font(.largeTitle)
                    .bold()
                if context.state.isResting {
                    Text("Resting...")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
            }
            .padding()
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .foregroundColor(.white)
                        .padding(.leading, 5)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.goalName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(context.state.taskTitle)
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                        Text(TimeFormatter.format(seconds: context.state.remainingTime))
                            .font(.title2)
                            .bold()
                            .monospacedDigit()
                            .foregroundColor(.white)
                        if context.state.isResting {
                            Text("Resting...")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.white)
            } compactTrailing: {
                Text(TimeFormatter.shortFormat(seconds: context.state.remainingTime))
                    .foregroundColor(.white)
            } minimal: {
                Text(TimeFormatter.shortFormat(seconds: context.state.remainingTime))
                    .foregroundColor(.white)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

// MARK: - Preview
#Preview("Dynamic Island Preview", as: .content, using: FocusActivityAttributes.preview) {
    FocusLiveActivity()
} contentStates: {
    FocusActivityAttributes.ContentState.previewValue(
        taskTitle: "Focus Session",
        remainingTime: 25 * 60,
        isResting: false
    )
    FocusActivityAttributes.ContentState.previewValue(
        taskTitle: "Short Break",
        remainingTime: 5 * 60,
        isResting: true
    )
    FocusActivityAttributes.ContentState.previewValue(
        taskTitle: "Focus Session",
        remainingTime: 10 * 60,
        isResting: false
    )
    FocusActivityAttributes.ContentState.previewValue(
        taskTitle: "Session Complete",
        remainingTime: 0,
        isResting: false
    )
}

// MARK: - Preview Helpers
extension FocusActivityAttributes {
    static var preview: FocusActivityAttributes {
        FocusActivityAttributes(goalName: "Deep Work")
    }
}

extension FocusActivityAttributes.ContentState {
    static func previewValue(taskTitle: String, remainingTime: TimeInterval, isResting: Bool) -> Self {
        .init(remainingTime: remainingTime, taskTitle: taskTitle, isResting: isResting)
    }
}

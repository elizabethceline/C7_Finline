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
            VStack(spacing: 8) {
                HStack{
                    if context.state.isResting {
                        VStack(alignment: .leading){
                            Text("Resting...")
                                .font(.system(size: 42))
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(.gray)
                                .offset(x:-5)
                            
                            if let endTime = context.state.endTime {
                                Text(endTime, style: .timer)
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                    .monospacedDigit()
//                                Text(formattedRemainingTime(from: endTime))
//                                    .font(.title2)
//                                    .monospacedDigit()
//                                    .foregroundColor(.gray)
                                    

                            } else {
                                Text(TimeFormatter.format(seconds: context.state.restRemainingTime ?? 0))
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
//                            Text(TimeFormatter.format(seconds: (context.state.isResting ? context.state.restRemainingTime : context.state.remainingTime) ?? 0))
//                                .font(.title2)
//                                .foregroundColor(.gray)
                        }
                        .padding(.bottom,13)
                    }else{
                        VStack(alignment: .leading){
//                            Text(TimeFormatter.format(seconds: (context.state.isResting ? context.state.restRemainingTime : context.state.remainingTime) ?? 0))
//                                .font(.system(size: 48))
//                                .fontWeight(.bold)
//                                .monospacedDigit()
//                                .foregroundColor(.gray)
//                                .offset(x:-5)
//                                .minimumScaleFactor(0.5)
//                                .layoutPriority(10)
                            if let endTime = context.state.endTime {
                                Text(endTime, style: .timer)
                                    .font(.system(size: 48))
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .foregroundColor(.gray)
                                    .offset(x:-5)
                                    .minimumScaleFactor(0.5)
                                    .layoutPriority(10)
                            } else {
                                Text(TimeFormatter.format(seconds: context.state.remainingTime))
                                    .font(.system(size: 48))
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .foregroundColor(.gray)
                                    .offset(x:-5)
                                    .minimumScaleFactor(0.5)
                                    .layoutPriority(10)
                            }
                            
                            Text(context.state.taskTitle)
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom,13)
                    }
                    
                    Spacer()
                    if context.state.isResting {
                        Image("lockScreenResting")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height:150)
                            .offset(x:20)
                            .padding(.leading, 1)
                    }else{
                        Image("lockScreenTimer")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height:150)
                            .offset(x:20)
                            .padding(.leading, 1)
                    }
                    
                    
                }
                ProgressView(value: progress(for: context), total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(Color(red: 161/255, green: 210/255, blue: 241/255))
                    .frame(height: context.state.isResting ? 0 : 10)
                    .clipShape(Capsule())
                    .animation(.easeInOut(duration: 0.5), value: progress(for: context))
                    .offset(y: -20)
                
            }
            .padding()
            .activityBackgroundTint(Color.secondary)
            .activitySystemActionForegroundColor(Color.secondary)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            if context.state.isResting {
                                ZStack {
                                    Image("compactResting")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 1, height: 1)
                                    Image("expandResting")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 130, height: 130)
                                }
                            }else{
                                ZStack {
                                    Image("compactTimer")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 1, height: 1)
                                    Image("timerExpand")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                }
                            }
                            
                            if context.state.isResting{
                                Spacer()
                                    .frame(width: 10)
                            }
                            VStack(alignment: .leading) {
                                if context.state.isResting{
                                    Text("Resting...")
                                        .font(.system(size: 35))
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    
//                                    Text(TimeFormatter.format(seconds: (context.state.isResting ? context.state.restRemainingTime : context.state.remainingTime) ?? 0))
//                                        .font(.subheadline)
//                                        .foregroundColor(.gray)
//                                        .monospacedDigit()
                                    if let endTime = context.state.endTime {
                                        Text(endTime, style: .timer)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .monospacedDigit()
                                    } else {
                                        Text(TimeFormatter.format(seconds: context.state.restRemainingTime ?? 0))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .monospacedDigit()
                                    }
                                }else{
//                                    Text(TimeFormatter.format(seconds: (context.state.isResting ? context.state.restRemainingTime : context.state.remainingTime) ?? 0))
//                                        .font(.system(size: 35))
//                                        .fontWeight(.bold)
//                                        .monospacedDigit()
//                                        .foregroundColor(.gray)
//                                        .offset(x:-5)
                                    if let endTime = context.state.endTime {
                                        Text(endTime, style: .timer)
                                            .font(.system(size: 35))
                                            .fontWeight(.bold)
                                            .monospacedDigit()
                                            .foregroundColor(.gray)
                                            .offset(x:-5)
                                    } else {
                                        Text(TimeFormatter.format(seconds: context.state.remainingTime))
                                            .font(.system(size: 35))
                                            .fontWeight(.bold)
                                            .monospacedDigit()
                                            .foregroundColor(.gray)
                                            .offset(x:-5)
                                    }
                                    
                                    
                                    
                                    Spacer()
                                        .frame(height: 7)
                                    
                                    
                                    Text(context.state.taskTitle)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                
                                Spacer()
                                    .frame(height: 14)
                                
                                ProgressView(value: progress(for: context), total: 1.0)
                                    .progressViewStyle(.linear)
                                    .tint(context.state.isResting ? .clear : Color(red: 161/255, green: 210/255, blue: 241/255))
                                    .frame(height: context.state.isResting ? 0 : 4)
                                    .clipShape(Capsule())
                                    .animation(.easeInOut(duration: 0.5), value: progress(for: context))


                            }
                        }
                        
                    }
                    .offset(y: context.state.isResting ? -15 : -5)
                }
                
                
            } compactLeading: {
                if context.state.isResting {
                    Image("compactResting")
                        .resizable()
                        .scaledToFit()
                    
                }else{
                    Image("compactTimer")
                        .resizable()
                        .scaledToFit()
                }
            } compactTrailing: {
//                Text(TimeFormatter.format(seconds: (context.state.isResting ? context.state.restRemainingTime : context.state.remainingTime) ?? 0))
//                    .foregroundColor(Color(red: 161/255, green: 210/255, blue: 241/255))
                if let endTime = context.state.endTime {
                    Text(endTime, style: .timer)
                        .foregroundColor(Color(red: 161/255, green: 210/255, blue: 241/255))
                        .monospacedDigit()
                } else {
                    Text(TimeFormatter.format(seconds: context.state.isResting ? (context.state.restRemainingTime ?? 0) : context.state.remainingTime))
                        .foregroundColor(Color(red: 161/255, green: 210/255, blue: 241/255))
                }
            } minimal: {
                if context.state.isResting {
                    Image("compactResting")
                        .resizable()
                        .scaledToFit()
                    
                }else{
                    Image("compactTimer")
                        .resizable()
                        .scaledToFit()
                }
            }
            .widgetURL(URL(string: "finline://"))
            .keylineTint(Color.red)
        }
    }
    
    private func formattedRemainingTime(from endTime: Date) -> String {
        let remaining = max(0, endTime.timeIntervalSince(Date()))
        return TimeFormatter.format(seconds: remaining)
    }

    
    private func progress(for context: ActivityViewContext<FocusActivityAttributes>) -> Double {
        let remaining = max(context.state.remainingTime, 0)
        let total = max(context.attributes.totalDuration, remaining)
        
        let progress = (total - remaining) / total
        return min(max(progress, 0), 1)
    }
}

#Preview("Dynamic Island Preview", as: .content, using: FocusActivityAttributes.preview) {
    FocusLiveActivity()
} contentStates: {
    FocusActivityAttributes.ContentState.previewValue(
        taskTitle: "Focus Session",
        remainingTime: 60 * 60,
        isResting: false
    )
    FocusActivityAttributes.ContentState.previewValue(
        taskTitle: "Short Break",
        remainingTime: 5 * 60,
        isResting: true
    )
    FocusActivityAttributes.ContentState.previewValue(
        taskTitle: "Session Complete",
        remainingTime: 0,
        isResting: true
    )
}

extension FocusActivityAttributes {
    static var preview: FocusActivityAttributes {
        FocusActivityAttributes(goalName: "Deep Work", totalDuration: 60)
    }
}

extension FocusActivityAttributes.ContentState {
    static func previewValue(taskTitle: String, remainingTime: TimeInterval, isResting: Bool) -> Self {
        .init(remainingTime: remainingTime, taskTitle: taskTitle, isResting: isResting)
    }
}


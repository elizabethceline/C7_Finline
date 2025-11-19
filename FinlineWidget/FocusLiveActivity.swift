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
                HStack {
                    if context.state.isCompleted {
                        VStack(alignment: .leading) {
                            Text("Session")
                                .font(.system(size: 32))
                                .fontWeight(.bold)
                                .offset(x: -5)
                            Text("Complete")
                                .font(.system(size: 32))
                                .fontWeight(.bold)
                                .offset(x: -5)
                               

//                            Text(context.state.taskTitle)
//                                .font(.title2)
//                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 13)
                        
                    } else if context.state.isResting {
                        VStack(alignment: .leading){
                            if context.state.isRestOver {
                                Text("Rest Over")
                                    .font(.system(size: 32))
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .offset(x:-5)
                                
                                Text("Time to go back to work!")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                
                            } else {
                                Text("Resting...")
                                    .font(.system(size: 32))
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .foregroundColor(.gray)
                                    .offset(x:-5)
                                
                                if let endTime = context.state.endTime {
                                    Text(endTime, style: .timer)
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                        .monospacedDigit()
                                } else {
                                    Text(TimeFormatter.format(seconds: context.state.restRemainingTime ?? 0))
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.bottom,13)

                    } else {
                        VStack(alignment: .leading) {
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
                    if context.state.isRestOver {
                        Image("restOver")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height:150)
                            .offset(x:20)
                        
                    } else if context.state.isResting {
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
                if !context.state.isResting && !context.state.isCompleted {
                    ProgressView(value: progress(for: context), total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(Color(red: 161/255, green: 210/255, blue: 241/255))
                        .frame(height: 10)
                        .clipShape(Capsule())
                        .offset(y: -20)
                }
            }
            .padding()
//            .activityBackgroundTint(Color.secondary)
            .activityBackgroundTint(
                Color(UIColor { trait in
                    trait.userInterfaceStyle == .dark
                        ? UIColor(Color.darkModeWidget)
                        : UIColor(Color.secondary)
                })
            )

            .activitySystemActionForegroundColor(Color.secondary)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            if context.state.isRestOver {
                                ZStack {
                                    Image("compactDone")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 1, height: 1)
                                    
                                    Image("restOver")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 130, height: 130)
                                }
                            } else if context.state.isResting {
                                ZStack {
                                    Image("compactResting")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 1, height: 1)
                                    Image("expandResting")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 130, height:130)
                                }
                            } else {
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
                            
                            VStack(alignment: .leading) {
                              
                                if context.state.isCompleted {
                                    Text("Session Complete")
                                        .font(.system(size: 35))
                                        .fontWeight(.bold)
                                        .offset(x:-5)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)

//                                    Spacer().frame(height: 7)
//
//                                    Text(context.state.taskTitle)
//                                        .font(.subheadline)
//                                        .foregroundColor(.gray)

                            
                                } else if context.state.isResting {

                                    if context.state.isRestOver {
                                        Text("Rest Over")
                                            .font(.system(size: 35))
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)

                                        Text("Time to get back to work!")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)

                                    } else {
                                        Text("Resting...")
                                            .font(.system(size: 35))
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                    }

                                    if let endTime = context.state.endTime {
                                        Text(endTime, style: .timer)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .monospacedDigit()
                                    }
                                    
                                } else {
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

                                    Spacer().frame(height: 7)

                                    Text(context.state.taskTitle)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                
                                if !context.state.isResting && !context.state.isCompleted {
                                    Spacer()
                                        .frame(height: 14)
                                    
                                    ProgressView(value: progress(for: context), total: 1.0)
                                        .progressViewStyle(.linear)
                                        .tint(Color(red: 161/255, green: 210/255, blue: 241/255))
                                        .frame(height: 4)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                    }
                    .offset(y: context.state.isResting ? -15 : -5)
                }
                
                
            }
            
            compactLeading: {
                if context.state.isCompleted {
                    Image("compactDone")
                        .resizable()
                        .scaledToFit()
                } else if context.state.isRestOver {
                    Image("compactRestOver")
                        .resizable()
                        .scaledToFit()
                } else if context.state.isResting {
                    Image("compactResting")
                        .resizable()
                        .scaledToFit()
                } else {
                    Image("compactTimer")
                        .resizable()
                        .scaledToFit()
                }
            }
            
            compactTrailing: {
                if context.state.isCompleted {
                    Text("Completed")
                        .font(.headline)
                } else if context.state.isRestOver {
                    Text("Rest Over")
                        .font(.headline)
                } else if let endTime = context.state.endTime {
                    Text(endTime, style: .timer)
                        .foregroundColor(Color(red: 161/255, green: 210/255, blue: 241/255))
                        .monospacedDigit()
                } else {
                    Text(TimeFormatter.format(seconds:
                        context.state.isResting ?
                        (context.state.restRemainingTime ?? 0) :
                        context.state.remainingTime
                    ))
                    .foregroundColor(Color(red: 161/255, green: 210/255, blue: 241/255))
                }
            }
            minimal: {
                if context.state.isCompleted {
                    Image("compactDone")
                        .resizable()
                        .scaledToFit()
                } else if context.state.isRestOver {
                    Image("compactRestOver")
                        .resizable()
                        .scaledToFit()
                } else if context.state.isResting {
                    Image("compactResting")
                        .resizable()
                        .scaledToFit()
                } else {
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

    
//    private func progress(for context: ActivityViewContext<FocusActivityAttributes>) -> Double {
//        let remaining = max(context.state.remainingTime, 0)
//        let total = max(context.attributes.totalDuration, remaining)
//        
//        let progress = (total - remaining) / total
//        return min(max(progress, 0), 1)
//    }
    private func progress(for context: ActivityViewContext<FocusActivityAttributes>) -> Double {
        guard
            let endTime = context.state.endTime
        else { return 1.0 }  // Complete

        let total = context.attributes.totalDuration
        let elapsed = total - max(endTime.timeIntervalSinceNow, 0)
        let progress = elapsed / total

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


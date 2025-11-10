//
//  FocusWidgetExtensionLiveActivity.swift
//  FocusWidgetExtension
//
//  Created by Richie Reuben Hermanto on 09/11/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FocusWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FocusWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FocusWidgetExtensionAttributes {
    fileprivate static var preview: FocusWidgetExtensionAttributes {
        FocusWidgetExtensionAttributes(name: "World")
    }
}

extension FocusWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: FocusWidgetExtensionAttributes.ContentState {
        FocusWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FocusWidgetExtensionAttributes.ContentState {
         FocusWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FocusWidgetExtensionAttributes.preview) {
   FocusWidgetExtensionLiveActivity()
} contentStates: {
    FocusWidgetExtensionAttributes.ContentState.smiley
    FocusWidgetExtensionAttributes.ContentState.starEyes
}

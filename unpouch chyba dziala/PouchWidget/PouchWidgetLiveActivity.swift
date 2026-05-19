//
//  PouchWidgetLiveActivity.swift
//  PouchWidget
//
//  Created by dzbanek on 19/05/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PouchWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct PouchWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PouchWidgetAttributes.self) { context in
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

extension PouchWidgetAttributes {
    fileprivate static var preview: PouchWidgetAttributes {
        PouchWidgetAttributes(name: "World")
    }
}

extension PouchWidgetAttributes.ContentState {
    fileprivate static var smiley: PouchWidgetAttributes.ContentState {
        PouchWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: PouchWidgetAttributes.ContentState {
         PouchWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: PouchWidgetAttributes.preview) {
   PouchWidgetLiveActivity()
} contentStates: {
    PouchWidgetAttributes.ContentState.smiley
    PouchWidgetAttributes.ContentState.starEyes
}

//
//  StellaFuelBuddyWidgetLiveActivity.swift
//  StellaFuelBuddyWidget
//
//  Created by William Bradley on 8/21/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StellaFuelBuddyWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct StellaFuelBuddyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StellaFuelBuddyWidgetAttributes.self) { context in
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

extension StellaFuelBuddyWidgetAttributes {
    fileprivate static var preview: StellaFuelBuddyWidgetAttributes {
        StellaFuelBuddyWidgetAttributes(name: "World")
    }
}

extension StellaFuelBuddyWidgetAttributes.ContentState {
    fileprivate static var smiley: StellaFuelBuddyWidgetAttributes.ContentState {
        StellaFuelBuddyWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: StellaFuelBuddyWidgetAttributes.ContentState {
         StellaFuelBuddyWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: StellaFuelBuddyWidgetAttributes.preview) {
   StellaFuelBuddyWidgetLiveActivity()
} contentStates: {
    StellaFuelBuddyWidgetAttributes.ContentState.smiley
    StellaFuelBuddyWidgetAttributes.ContentState.starEyes
}

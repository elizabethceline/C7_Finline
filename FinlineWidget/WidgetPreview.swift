//
//  WidgetPreview.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 16/11/25.
//

import WidgetKit
import SwiftUI

#Preview(as: .systemSmall) {
    FinlineWidget()
} timeline: {
    TaskEntry(date: .now, configuration: ConfigurationAppIntent())
}

#Preview(as: .systemMedium) {
    FinlineWidget()
} timeline: {
    TaskEntry(date: .now, configuration: ConfigurationAppIntent())
}

#Preview(as: .systemLarge) {
    FinlineWidget()
} timeline: {
    TaskEntry(date: .now, configuration: ConfigurationAppIntent())
}

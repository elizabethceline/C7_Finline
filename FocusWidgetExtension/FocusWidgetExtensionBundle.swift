//
//  FocusWidgetExtensionBundle.swift
//  FocusWidgetExtension
//
//  Created by Richie Reuben Hermanto on 09/11/25.
//

import WidgetKit
import SwiftUI

@main
struct FocusWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        FocusWidgetExtension()
        FocusWidgetExtensionControl()
        FocusWidgetExtensionLiveActivity()
    }
}

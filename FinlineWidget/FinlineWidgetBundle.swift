//
//  FinlineWidgetBundle.swift
//  FinlineWidget
//
//  Created by Richie Reuben Hermanto on 10/11/25.
//

import WidgetKit
import SwiftUI

@main
struct FinlineWidgetBundle: WidgetBundle {
    var body: some Widget {
        FinlineWidget()
        FinlineWidgetControl()
        FinlineWidgetLiveActivity()
        FocusLiveActivity()
    }
}

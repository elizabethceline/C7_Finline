//
//  TipKit.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 15/11/25.
//

import SwiftUI
import TipKit

struct TipKit {
    static func configure() {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault),
        ])
    }

    static func resetAllTips() {
        try? Tips.resetDatastore()

        CreateTaskTip.hasCreatedTask = false
        GoalNameTip.hasEnteredGoalName = false
        DeadlineTip.hasSetDeadline = false
        CreateWithAITip.hasClickedCreateWithAI = false
        AIPromptTip.hasEnteredPrompt = false
        TaskCardTip.hasClickedTaskCard = false
        StartFocusTip.hasStartedFocus = false
        StartFocusTip.hasEndedFocus = false
        ProfileButtonTip.hasClickedProfile = false
        ShopButtonTip.hasClickedShop = false
    }
}

struct CreateTaskTip: Tip {
    var title: Text {
        Text("Create your first task")
    }

    var message: Text? {
        Text("Tap the + button to get started.")
    }

    var image: Image? {
        Image(systemName: "plus.circle.fill")
    }

    var rules: [Rule] {
        #Rule(Self.$hasCreatedTask) { $0 == false }
    }

    @Parameter
    static var hasCreatedTask: Bool = false

    var options: [TipOption] {
        [
            Tips.MaxDisplayCount(1)
        ]
    }
}

struct GoalNameTip: Tip {
    var title: Text {
        Text("What's your goal?")
    }

    var message: Text? {
        Text("Describe it in one short sentence.")
    }

    var image: Image? {
        Image(systemName: "target")
    }

    var rules: [Rule] {
        [
            #Rule(CreateTaskTip.$hasCreatedTask) { $0 == true },
            #Rule(Self.$hasEnteredGoalName) { $0 == false },
        ]
    }

    @Parameter
    static var hasEnteredGoalName: Bool = false

    var options: [TipOption] {
        [
            Tips.MaxDisplayCount(1)
        ]
    }
}

struct DeadlineTip: Tip {
    var title: Text {
        Text("Set your deadline")
    }

    var message: Text? {
        Text("Choose when you want to achieve this goal.")
    }

    var image: Image? {
        Image(systemName: "calendar.badge.clock")
    }

    var rules: [Rule] {
        [
            #Rule(GoalNameTip.$hasEnteredGoalName) { $0 == true },
            #Rule(Self.$hasSetDeadline) { $0 == false },
        ]
    }

    @Parameter
    static var hasSetDeadline: Bool = false

    var options: [TipOption] {
        [
            Tips.MaxDisplayCount(1)
        ]
    }
}

struct CreateWithAITip: Tip {
    var title: Text {
        Text("Let AI help you")
    }

    var message: Text? {
        Text("AI automatically breaks down your goal into actionable tasks.")
    }

    var image: Image? {
        Image(systemName: "sparkles")
    }

    var rules: [Rule] {
        [
            #Rule(DeadlineTip.$hasSetDeadline) { $0 == true },
            #Rule(Self.$hasClickedCreateWithAI) { $0 == false },
        ]
    }

    @Parameter
    static var hasClickedCreateWithAI: Bool = false

    var options: [TipOption] {
        [
            Tips.MaxDisplayCount(1)
        ]
    }
}

struct AIPromptTip: Tip {
    var title: Text {
        Text("Describe your goal")
    }

    var message: Text? {
        Text("The more details you give, the better the plan.")
    }

    var image: Image? {
        Image(systemName: "text.bubble.fill")
    }

    var rules: [Rule] {
        [
            #Rule(CreateWithAITip.$hasClickedCreateWithAI) { $0 == true },
            #Rule(Self.$hasEnteredPrompt) { $0 == false },
        ]
    }

    @Parameter
    static var hasEnteredPrompt: Bool = false

    var options: [TipOption] {
        [
            Tips.MaxDisplayCount(1)
        ]
    }
}

struct TaskCardTip: Tip {
    var title: Text {
        Text("Ready to focus?")
    }

    var message: Text? {
        Text("Tap a task to begin.")
    }

    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }

    var rules: [Rule] {
        [
            #Rule(Self.$hasClickedTaskCard) { $0 == false }
        ]
    }

    @Parameter
    static var hasClickedTaskCard: Bool = false

    var options: [TipOption] {
        [
            Tips.MaxDisplayCount(1)
        ]
    }
}

struct StartFocusTip: Tip {
    var title: Text {
        Text("Start your focus session")
    }

    var message: Text? {
        Text("Press the button below to begin.")
    }

    var image: Image? {
        Image(systemName: "play.circle.fill")
    }

    var rules: [Rule] {
        [
            #Rule(TaskCardTip.$hasClickedTaskCard) { $0 == true },
            #Rule(Self.$hasStartedFocus) { $0 == false },
            #Rule(Self.$hasEndedFocus) { $0 == false },
        ]
    }

    @Parameter
    static var hasStartedFocus: Bool = false
    @Parameter
    static var hasEndedFocus: Bool = false

    var options: [TipOption] {
        [
            Tips.MaxDisplayCount(1)
        ]
    }
}

struct ProfileButtonTip: Tip {
    var title: Text {
        Text("Check out your profile")
    }

    var message: Text? {
        Text("Tap your profile icon to see your progress and unlock rewards.")
    }

    var image: Image? {
        Image(systemName: "person.circle.fill")
    }

    var rules: [Rule] {
        [
            #Rule(StartFocusTip.$hasEndedFocus) { $0 == true },
            #Rule(Self.$hasClickedProfile) { $0 == false },
        ]
    }

    @Parameter
    static var hasClickedProfile: Bool = false

    var options: [TipOption] {
        [
            Tips.MaxDisplayCount(1)
        ]
    }
}

struct ShopButtonTip: Tip {
    var title: Text {
        Text("Visit the shop")
    }

    var message: Text? {
        Text("Discover adorable characters to accompany you on your journey!")
    }

    var image: Image? {
        Image(systemName: "hanger")
    }

    var rules: [Rule] {
        [
            #Rule(ProfileButtonTip.$hasClickedProfile) { $0 == true },
            #Rule(Self.$hasClickedShop) { $0 == false },
        ]
    }

    @Parameter
    static var hasClickedShop: Bool = false

    var options: [TipOption] {
        [
            Tips.MaxDisplayCount(1)
        ]
    }
}

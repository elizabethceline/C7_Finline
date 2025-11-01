//
//  HeaderView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 01/11/25.
//

import SwiftUI

struct HeaderView: View {
    @ObservedObject var viewModel: MainViewModel
    let unfinishedTasks: [GoalTask]

    var body: some View {
        HStack(alignment: .bottom) {

            ZStack(alignment: .bottomTrailing) {
                Text(
                    unfinishedTasks.count > 1
                        ? "You have \(unfinishedTasks.count) unfinished tasks! Plan your day wisely."
                        : unfinishedTasks.count == 1
                            ? "You have 1 unfinished task! Plan your day wisely."
                            : "Do your tasks today and earn points!"
                )
                .foregroundColor(.black)
                .font(.body)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 22))

                TriangleTail()
                    .fill(Color.secondary)
                    .frame(width: 25, height: 20)
                    .rotationEffect(.degrees(20))
                    .offset(x: 0, y: 5)

            }

            Spacer()

            Image("finley")
                .resizable()
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .frame(width: 55, height: 55)
                .clipShape(Circle())
        }
        .padding()
    }
}

// tail
struct TriangleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    HeaderView(
        viewModel: MainViewModel(),
        unfinishedTasks: [
            GoalTask(
                id: "task_001",
                name: "Study Math",
                workingTime: Date(),
                focusDuration: 25,
                isCompleted: false,
                goal: Goal(
                    id: "goal_001",
                    name: "Learn Algebra",
                    due: Date().addingTimeInterval(7 * 24 * 60 * 60),
                    goalDescription:
                        "Understand the basics of algebraic expressions and equations."
                )
            ),
            GoalTask(
                id: "task_001",
                name: "Study Math",
                workingTime: Date(),
                focusDuration: 25,
                isCompleted: false,
                goal: Goal(
                    id: "goal_001",
                    name: "Learn Algebra",
                    due: Date().addingTimeInterval(7 * 24 * 60 * 60),
                    goalDescription:
                        "Understand the basics of algebraic expressions and equations."
                )
            ),
        ]
    )
}

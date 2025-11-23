//
//  HeaderView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 01/11/25.
//

import SwiftUI
import TipKit

struct HeaderView: View {
    @ObservedObject var viewModel: MainViewModel
    let unfinishedTasks: [GoalTask]
    @Binding var selectedDate: Date

    @StateObject private var shopVM: ShopViewModel
    @State private var navigateToProfile: Bool = false
    @State private var selectedCharacterImage: Image = ShopItem.finley.image

    init(
        viewModel: MainViewModel,
        unfinishedTasks: [GoalTask],
        selectedDate: Binding<Date>,
        shopVM: ShopViewModel
    ) {
        self.viewModel = viewModel
        self.unfinishedTasks = unfinishedTasks
        self._selectedDate = selectedDate
        self._shopVM = StateObject(wrappedValue: shopVM)
    }

    var body: some View {
        HStack(alignment: .bottom) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 6) {
                    if unfinishedTasks.isEmpty {
                        Text(
                            "You currently have no task, add it if you really need to. Or not..."
                        )
                        .foregroundColor(Color(.label).opacity(0.7))
                        .font(.body)
                    } else {
                        Text(tasksMessage)
                            .foregroundColor(Color(.label).opacity(0.7))
                            .font(.body)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: 18,
                        topTrailingRadius: 0
                    )
                )

                TriangleTail()
                    .fill(Color(.systemBackground))
                    .frame(width: 25, height: 20)
                    .rotationEffect(.degrees(58))
                    .offset(x: 14, y: -4.5)

            }

            Spacer()

            Button {
                navigateToProfile = true
                ProfileButtonTip.hasClickedProfile = true
            } label: {
                selectedCharacterImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70)
            }
            .popoverTip(ProfileButtonTip(), arrowEdge: .top)
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 12)
        .navigationDestination(isPresented: $navigateToProfile) {
            ProfileView(viewModel: ProfileViewModel())
        }
        .onAppear {
            updateSelectedCharacter()
        }
        .onChange(of: shopVM.selectedItem) { _, newItem in
            if let newItem = newItem {
                selectedCharacterImage = newItem.image
            }
        }
    }

    private var unfinishedTaskText: String {
        unfinishedTasks.count == 1
            ? "1 overdue task" : "\(unfinishedTasks.count) overdue tasks"
    }

    private var tasksMessage: AttributedString {
        let attributed = AttributedString(
            "Hey, you have \(unfinishedTaskText).\nPlease start doing your task!"
        )
        //        if let range = attributed.range(of: unfinishedTaskText) {
        //            attributed[range].underlineStyle = .single
        //            attributed[range].foregroundColor = .red
        //            attributed[range].font = .system(.body, design: .default).weight(
        //                .semibold
        //            )
        //        }
        return attributed
    }

    private func updateSelectedCharacter() {
        if let selectedItem = shopVM.selectedItem {
            selectedCharacterImage = selectedItem.image
        } else {
            selectedCharacterImage = ShopItem.finley.image
        }
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
    let networkMonitor = NetworkMonitor.shared
    let shopVM = ShopViewModel(networkMonitor: networkMonitor)

    return HeaderView(
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
            )
        ],
        selectedDate: .constant(Date()),
        shopVM: shopVM
    )
    .background(Color.red)
}

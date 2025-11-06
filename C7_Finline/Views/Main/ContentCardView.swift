//
//  ContentCardView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct ContentCardView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var selectedDate: Date
    let networkMonitor: NetworkMonitor

    @GestureState private var dragOffset: CGFloat = 0
    @State private var contentOffset: CGFloat = 0
    @State private var isAnimating: Bool = false

    private let calendar = Calendar.current

    var tasks: [GoalTask] {
        viewModel.filterTasksByDate(for: selectedDate)
    }

    var goals: [Goal] {
        viewModel.filterGoalsByDate(for: selectedDate)
    }

    private func changeDay(delta: Int, width: CGFloat) {
        if let newDate = calendar.date(
            byAdding: .day,
            value: delta,
            to: selectedDate
        ) {
            isAnimating = true

            // Animate content sliding out
            withAnimation(.easeInOut(duration: 0.3)) {
                contentOffset =
                    delta > 0
                    ? -width : width
            }

            // Change date and reset position after slide out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                selectedDate = calendar.startOfDay(for: newDate)
                contentOffset =
                    delta > 0
                    ? width : -width

                // Slide in from opposite side
                withAnimation(.easeOut(duration: 0.25)) {
                    contentOffset = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isAnimating = false
                }
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let drag = DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if !isAnimating {
                        state = value.translation.width
                    }
                }
                .onEnded { value in
                    if !isAnimating {
                        if value.translation.width < -50 {
                            changeDay(delta: 1, width: geo.size.width)
                        } else if value.translation.width > 50 {
                            changeDay(delta: -1, width: geo.size.width)
                        }
                    }
                }

            VStack(spacing: 0) {
                // Filter indicator
                if viewModel.taskFilter != .unfinished {
                    HStack {
                        Text("Showing: \(viewModel.taskFilter.rawValue)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.label))
                        Spacer()
                        Button("Clear") {
                            withAnimation {
                                viewModel.taskFilter = .unfinished
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Color.primary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .padding(.bottom, 8)
                }
                
                if tasks.isEmpty {
                    ScrollView(showsIndicators: false) {
                        EmptyStateView()
                            .padding(.top, 24)
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                } else {
                    TaskListView(
                        viewModel: viewModel,
                        tasks: tasks,
                        goals: goals,
                        selectedDate: selectedDate,
                        networkMonitor: networkMonitor
                    )
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)
            .offset(x: contentOffset + dragOffset)
            .opacity(
                isAnimating
                    ? (contentOffset == 0 ? 1 : 0.5)
                    : 1 - abs(dragOffset) / geo.size.width * 0.5
            )
            .contentShape(Rectangle())
            .gesture(drag)
        }
        .refreshable {
            await viewModel.fetchGoals()
        }
    }

}

#Preview {
    ContentCardView(
        viewModel: MainViewModel(),
        selectedDate: .constant(Date()),
        networkMonitor: NetworkMonitor()
    )
}

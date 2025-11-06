import SwiftUI
import SwiftData

struct FocusModeView: View {
    @EnvironmentObject var viewModel: FocusSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var onGiveUp: (GoalTask) -> Void

    @State private var isGivingUp = false
    @State private var resultVM: FocusResultViewModel?
    @State private var isShowingGiveUpAlert = false
    @State private var isShowingEarlyFinishAlert = false

    @State private var isShowingTimesUpAlert = false
    @State private var isShowingAddTimeModal = false
    @State private var extraTimeInMinutes: Int = 5
    @State private var hasExtendedTime = false

    @State private var isShowingRestModal = false
    @State private var selectedRestMinutes = 5

    private var totalAllowedRestTime: TimeInterval {
        let blocksOf30Min = viewModel.sessionDuration / (30 * 60)
        return blocksOf30Min * (5 * 60)
    }

    private var isEarlyFinishAllowed: Bool {
        guard viewModel.sessionDuration > 0 else { return false }
        if !hasExtendedTime {
            let fifteenPercentMark = viewModel.sessionDuration * 0.15
            return viewModel.remainingTime <= fifteenPercentMark
        } else {
            return true
        }
    }

    private var buttonLabel: String {
        if resultVM != nil { return "Done" }
        if hasExtendedTime || isEarlyFinishAllowed { return "I'm Done!" }
        return "Give Up"
    }

    var body: some View {
        ZStack {
            backgroundView

            if viewModel.isResting {
                Color.blue.opacity(0.3)
                    .frame(height: 910)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.isResting)
            }

            VStack { // decorative character
                Image("charaSementara")
                    .resizable()
                    .scaledToFit()
            }

            content // <-- broken out into a computed property
                .padding()
        }
        // lifecycle + tasks
        .onChange(of: viewModel.shouldReturnToStart) { oldValue, newValue in
            if newValue && !isGivingUp && resultVM == nil {
                isShowingTimesUpAlert = true
            }
//            if newValue && isGivingUp {
//                dismiss()
//            }
        }
        .task(id: viewModel.isShowingNudgeAlert) {
            if viewModel.isShowingNudgeAlert {
                do {
                    try await Task.sleep(nanoseconds: 15_000_000_000)
                    viewModel.isShowingNudgeAlert = false
                } catch {
                    print("Nudge timer cancelled (likely due to user action).")
                }
            }
        }
        .onAppear {
            isGivingUp = false
            resultVM = nil
        }
        .alert("Do you want to give up?", isPresented: $isShowingGiveUpAlert) {
            Button("Yes", role: .destructive) {
                Task {
                    isGivingUp = true
                    await viewModel.giveUp()
                    if let task = viewModel.task {
                        onGiveUp(task)
                    } else {
                        dismiss()
                    }
                }
            }
            Button("No", role: .cancel) { }
        } message: {
            Text("You haven't finished \"\(viewModel.taskTitle)\" yet. Is it worth giving up? You won't receive any rewards if you stop now.")
        }
        .alert("Are you really done?", isPresented: $isShowingEarlyFinishAlert) {
            Button("Yes I'm done") {
                Task {
                    await viewModel.endSession()
                    resultVM = viewModel.createResult(using: modelContext, didComplete: true)
                }
            }
            Button("Nevermind", role: .cancel) { }
        } message: {
            let formattedTime = TimeFormatter.format(seconds: viewModel.remainingTime)
            
            Text("You still have \(formattedTime) left for this task. Will proceed to reward immediately.")
        }
        .alert("Time's Up!", isPresented: $isShowingTimesUpAlert) {
            Button("Yes, I'm finished") {
                Task {
                    await viewModel.endSession()
                    resultVM = viewModel.createResult(using: modelContext, didComplete: true)
                }
            }
            Button("I need more time") {
                extraTimeInMinutes = 5
                isShowingAddTimeModal = true
            }
        } message: {
            Text("Let’s be real... Did you actually finish the task?")
        }
        .alert("Hey, are you still working?", isPresented: $viewModel.isShowingNudgeAlert) {
            Button("Yes I'm still working") {
                viewModel.userConfirmedNudge()
            }
        } message: {
            Text("You’re totally not doing something else right now, right? Answering this will get 20 points.")
        }
        .sheet(isPresented: $isShowingAddTimeModal) {
            AddTimeView { hours, minutes, seconds in
                Task {
                    await viewModel.addMoreTime(hours: hours, minutes: minutes, seconds: seconds)
                }
                hasExtendedTime = true
            }
        }
        .sheet(isPresented: $isShowingRestModal) {
            AddRestTimeView(
                restMinutes: $selectedRestMinutes,
                maxRestMinutes: max(5, Int(viewModel.remainingRestSeconds / 60)),
                onConfirm: {
                    let restDuration = TimeInterval(selectedRestMinutes * 60)
                    viewModel.startRest(for: restDuration)
                    isShowingRestModal = false
                },
                onCancel: {
                    isShowingRestModal = false
                }
            )
            .presentationDetents([.height(300)])
            .presentationBackground(Color.blue.opacity(0.3))
        }
        .onChange(of: viewModel.isResting) { oldValue, newValue in
            print("isInRestView changed from \(oldValue) to \(newValue)")
        }
    }

    // MARK: - Subviews split for compiler friendliness

    private var backgroundView: some View {
        Image("backgroundSementara")
            .resizable()
            .frame(height: 910)
    }

    private var content: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            VStack(alignment: .leading) {
                if let vm = resultVM {
                    endView(vm: vm)
                } else if viewModel.isResting {
                    restView
                } else {
                    activeView
                }
            }
        }
    }

    private func endView(vm: FocusResultViewModel) -> some View {
        FocusEndView(viewModel: vm)
    }

    private var restView: some View {
        FocusRestView(
            goalName: viewModel.goalName,
            restDuration: viewModel.restRemainingTime
        )
    }


    private var activeView: some View {
        Group {
            // Header
            Text(viewModel.goalName ?? "No Goal")
                .font(.headline)
                .bold()
                .padding(.horizontal)
                .padding(.vertical, 8)
                //.background(Color.secondary)
                //.clipShape(RoundedRectangle(cornerRadius: 20))
               // .shadow(radius: 2)
                //.padding()

            // Task title
            Text(viewModel.taskTitle.isEmpty ? "Focus Session" : viewModel.taskTitle)
                .font(.largeTitle)
                .bold()
                //.foregroundColor(.white)
                .multilineTextAlignment(.leading)
                //.shadow(radius: 6)
                .padding(.horizontal)
                .padding(.bottom)

            Spacer()

            // Timer display + buttons
            timerCard
                //.padding(.vertical)
                .padding(.bottom, 40)
        }
    }

    private var timerCard: some View {
        VStack(spacing: 16) {
            Text(TimeFormatter.format(seconds: viewModel.remainingTime))
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .monospacedDigit()

            HStack {
                Button {
                    Task {
                        if isEarlyFinishAllowed {
                            isShowingEarlyFinishAlert = true
                        } else {
                            isShowingGiveUpAlert = true
                        }
                    }
                } label: {
                    Text(buttonLabel)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                
                if viewModel.canRest && viewModel.isFocusing {
                    Button {
                        isShowingRestModal = true
                    } label: {
                        Text("Rest")
                            .font(.headline)
//                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical)
        .background {
            if #available(iOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.vertical)
    }
}

#Preview {
    let mockSessionVM = FocusSessionViewModel()
    mockSessionVM.taskTitle = "Initiate a Desk Research"
    mockSessionVM.goalName = "Write my Thesis"
    mockSessionVM.remainingTime = 120

    return FocusModeView(
        onGiveUp: { task in print("Preview Give Up Tapped") }
    )
        .environmentObject(mockSessionVM)
        .modelContainer(for: [Goal.self, GoalTask.self], inMemory: true)
}

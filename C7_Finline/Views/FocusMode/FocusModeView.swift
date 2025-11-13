import SwiftUI
import SwiftData

struct FocusModeView: View {
    @EnvironmentObject var viewModel: FocusSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var onGiveUp: (GoalTask) -> Void
    var onSessionEnd: (() -> Void)? = nil
    
    @State private var isShowingEndSessionAlert = false

    @State private var isGivingUp = false
    @State private var resultVM: FocusResultViewModel?

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

    var body: some View {
        ZStack {
            backgroundView

            if viewModel.isResting {
                Color.blue.opacity(0.3)
                    .frame(height: 910)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.isResting)
            }

            content
                .padding()
        }
        // lifecycle + tasks
        .onChange(of: viewModel.isSessionEnded) { oldValue, newValue in
            if newValue && !isGivingUp && resultVM == nil {
                isShowingTimesUpAlert = true
            }
            if newValue && resultVM == nil {
                Task { @MainActor in
                    resultVM = viewModel.createResult(using: modelContext, didComplete: true)
                }
            }
        }
        .onChange(of: viewModel.didTimeRunOut) {
            oldValue, newValue in
            if newValue {
                isShowingTimesUpAlert = true
            }
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
            isShowingTimesUpAlert = false
            hasExtendedTime = false
            viewModel.didTimeRunOut = false
            viewModel.didFinishEarly = false
            viewModel.isSessionEnded = false
            viewModel.errorMessage = nil
        }
        .onDisappear {
            viewModel.resetSession()
        }
        .alert("End Focus Session?", isPresented: $isShowingEndSessionAlert) {
            Button("I'm Done", role: .none) {
                Task {
                    resultVM = viewModel.createResult(using: modelContext, didComplete: true)
                    viewModel.finishEarly() // mark complete early
                }
            }

            Button("Abort Task", role: .destructive) {
                Task {
                    isGivingUp = true
                    await viewModel.giveUp() // mark incomplete
                    if let task = viewModel.task {
                        onGiveUp(task)
                    } else {
                        dismiss()
                    }
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            let formattedTime = TimeFormatter.format(seconds: viewModel.remainingTime)
            
            Text("You still have \(formattedTime) to go. Wrap up now to finish the task, or abort if you’re calling it quits early.")
        }
        
        .alert("Time's Up!", isPresented: $isShowingTimesUpAlert) {
            Button("Yes, I'm finished") {
                Task { @MainActor in
                    resultVM = viewModel.createResult(using: modelContext, didComplete: true)
                    
                    await viewModel.endSession()
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
        Image(viewModel.isResting ? "restmode" : "focusmode")
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
        FocusEndView(viewModel: vm) {
            onSessionEnd?()
        }
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
                    isShowingEndSessionAlert = true
                } label: {
                    Text("End")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                
                Button {
                    isShowingRestModal = true
                } label: {
                    Text("Rest")
                        .font(.headline)
                        //.frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canRest && viewModel.isFocusing ? Color.primary : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .disabled(!(viewModel.canRest && viewModel.isFocusing))
                .animation(.easeInOut(duration: 0.2), value: viewModel.canRest && viewModel.isFocusing)
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

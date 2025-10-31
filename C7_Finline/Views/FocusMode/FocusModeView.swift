import SwiftUI
import SwiftData

struct FocusModeView: View {
    @EnvironmentObject var viewModel: FocusSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var isGivingUp = false
    @State private var resultVM: FishResultViewModel?
    @State private var isShowingGiveUpAlert = false
    @State private var isShowingEarlyFinishAlert = false
    
    @State private var isShowingTimesUpAlert = false
    @State private var isShowingAddTimeModal = false
    @State private var extraTimeInMinutes: Int = 5
    @State private var hasExtendedTime = false
    
    private var isEarlyFinishAllowed: Bool {
        guard viewModel.sessionDuration > 0 else {
            return false
        }
        if hasExtendedTime == false {
            let fifteenPercentMark = viewModel.sessionDuration * 0.15
            return viewModel.remainingTime <= fifteenPercentMark
        } else { return true }
    }
    
    private var buttonLabel: String {
        if resultVM != nil {
            return "Done"
        }
        if hasExtendedTime || isEarlyFinishAllowed {
            return "I'm Done!"
        }
        return "Give Up"
    }
    
    var body: some View {
        ZStack {
            Image("backgroundSementara")
                .resizable()
//                .aspectRatio(contentMode: .fill)
                .frame(height: 910)
            
            VStack {
                Image("charaSementara")
                    .resizable()
                    .scaledToFit()
            }
            
            VStack(spacing: 24) {
                Spacer().frame(height: 40)
                
                VStack(alignment: .leading){
                if let vm = resultVM {
                    FocusEndView(viewModel: vm)
                } else {
                    
                    Text(viewModel.goalName ?? "No Goal")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 2)
                        .padding()
                    
                    
                    
                    // Task title
                    Text(viewModel.taskTitle.isEmpty ? "Focus Session" : viewModel.taskTitle)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .shadow(radius: 6)
                        .padding(.horizontal)
                        .padding(.bottom)
                        //.padding(.horizontal, 40)
                    
                    // Task description
                    //                    if let taskDescription = viewModel.taskDescription, !taskDescription.isEmpty {
                    //                        Text(taskDescription)
                    //                            .font(.body)
                    //                            .foregroundColor(.white.opacity(0.9))
                    //                            .multilineTextAlignment(.center)
                    //                            .shadow(radius: 4)
                    //                            .padding(.horizontal, 40)
                    //                    }
                    
                    Spacer()
                    
                    // Timer display
                    VStack(spacing: 16) {
                        Text(formatTime(viewModel.remainingTime))
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                        
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
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    //.padding(.horizontal)
                    //.padding()
                    .padding(.vertical)
                    .padding(.bottom,40)
                    
                }
                    
//                    Spacer()
//                    
//                    // Timer display
//                    VStack(spacing: 16) {
//                        Text(formatTime(viewModel.remainingTime))
//                            .font(.system(size: 60, weight: .bold, design: .rounded))
//                            .foregroundColor(.primary)
//                            .monospacedDigit()
//                        
//                        Button {
//                            Task {
//                                if isEarlyFinishAllowed {
//                                    isShowingEarlyFinishAlert = true
//                                } else {
//                                    isShowingGiveUpAlert = true
//                                }
//                            }
//                        } label: {
//                            Text(buttonLabel)
//                                .font(.headline)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundColor(.white)
//                                .clipShape(RoundedRectangle(cornerRadius: 24))
//                        }
//                    }
//                    .padding(.horizontal)
//                    .padding(.vertical)
//                    .background(Color.white.opacity(0.8))
//                    .clipShape(RoundedRectangle(cornerRadius: 24))
//                    //.padding(.horizontal)
//                    //.padding()
//                    .padding(.vertical)
//                    .padding(.bottom)
                }
            }
            .padding()
        }
        .onChange(of: viewModel.shouldReturnToStart) { oldValue, newValue in
            if newValue && !isGivingUp && resultVM == nil {
                isShowingTimesUpAlert = true
            }
            if newValue && isGivingUp {
                dismiss()
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
            viewModel.setModelContext(modelContext)
        }
        .alert("Are you sure?", isPresented: $isShowingGiveUpAlert) {
            Button("Yes", role: .destructive) {
                Task {
                    isGivingUp = true
                    await viewModel.endSession()
                    dismiss()
                }
            }
            Button("No", role: .cancel) { }
        } message: {
            Text("You will not receive any rewards if you give up now.")
        }
        .alert("Are you sure you're done?", isPresented: $isShowingEarlyFinishAlert) {
            Button("Yes I'm done") {
                Task {
                    await viewModel.stopSessionForEarlyFinish()
                    saveResult()
                }
            }
            Button("Nevermind", role: .cancel) { }
        } message: {
            Text("Will proceed to reward immediately.")
        }
        .alert("Time's Up!", isPresented: $isShowingTimesUpAlert) {
            Button("Yes, I finished") {
                saveResult()
            }
            Button("I need more time") {
                extraTimeInMinutes = 5
                isShowingAddTimeModal = true
            }
        } message: {
            Text("Did you finish your task?")
        }
        .alert("Just checking, are you still working?", isPresented: $viewModel.isShowingNudgeAlert) {
            Button("Yes I'm still working") {
                viewModel.userConfirmedNudge()
            }
        } message: {
            Text("Answering this will get 20 points")
        }
//        .sheet(isPresented: $isShowingAddTimeModal, onDismiss: {
//            if extraTimeInMinutes > 0 {
//                Task {
//                    await viewModel.addMoreTime(minutes: extraTimeInMinutes)
//                }
//            }
//        }) {
//            AddTimeView(minutes: $extraTimeInMinutes)
//        }
        .sheet(isPresented: $isShowingAddTimeModal) {
            AddTimeView { hours, minutes, seconds in
                Task {
                    await viewModel.addMoreTime(hours: hours, minutes: minutes, seconds: seconds)
                }
                hasExtendedTime = true
            }
        }

    }
    
    private func saveResult() {
        guard resultVM == nil else { return }
        
        print("Saving combined result — showing FocusEndView now")
        let newResultVM = FishResultViewModel(context: modelContext, profileManager: viewModel.userProfileManager)
        
        let bonus = viewModel.bonusPointsFromNudge
        
        newResultVM.recordCombinedResult(fish: viewModel.accumulatedFish, bonusPoints: bonus)
        
        self.resultVM = newResultVM
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}

#Preview {
    let mockSessionVM = FocusSessionViewModel(networkMonitor: NetworkMonitor())
    mockSessionVM.taskTitle = "Initiate a Desk Research"
    mockSessionVM.goalName = "Write my Thesis"
    mockSessionVM.remainingTime = 1
    
    return FocusModeView()
        .environmentObject(mockSessionVM)
        .modelContainer(for: [Goal.self, GoalTask.self], inMemory: true)
}

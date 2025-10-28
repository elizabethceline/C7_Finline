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
    @State private var accumulatedFish: [Fish] = []
    
    private var isEarlyFinishAllowed: Bool {
        guard viewModel.sessionDuration > 0 else {
            return false
        }
        let fifteenPercentMark = viewModel.sessionDuration * 0.15
        return viewModel.remainingTime <= fifteenPercentMark
    }
    
    private var buttonLabel: String {
        if resultVM != nil {
            return "Done"
        }
        if isEarlyFinishAllowed {
            return "I'm Done"
        }
        return "Give Up"
    }
    
    var body: some View {
        ZStack {
            Image("backgroundSementara")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 910)
            
            VStack {
                Image("charaSementara")
                    .resizable()
                    .scaledToFit()
            }
            
            VStack(spacing: 32) {
                Spacer().frame(height: 80)
                
                Text(viewModel.taskTitle.isEmpty ? "Focus Session" : viewModel.taskTitle)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(radius: 6)
                
                if let vm = resultVM {
                    FocusEndView(viewModel: vm)
                } else {
                    Text(formatTime(viewModel.remainingTime))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .shadow(radius: 6)
                }
                
                Spacer()
                
                Button {
                    Task {
                        if resultVM != nil {
                            viewModel.resetSession()
                            dismiss()
                        } else if isEarlyFinishAllowed {
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
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
                .padding(.horizontal, 80)
                .padding(.bottom, 50)
            }
            .padding()
        }
        //        .onChange(of: viewModel.shouldReturnToStart) { shouldReturn in
        //            if shouldReturn && !isGivingUp {
        //                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        //                    saveResult()
        //                }
        //            }
        //        }
        .onChange(of: viewModel.shouldReturnToStart) { oldValue, newValue in
            if newValue && !isGivingUp && resultVM == nil {
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
            
            if viewModel.shouldReturnToStart && !isGivingUp {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    saveResult()
                }
            }
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
                    
                    accumulatedFish.append(contentsOf: viewModel.fishingVM.caughtFish)
                    saveResult()
                }
            }
            Button("Nevermind", role: .cancel) { }
        } message: {
            Text("Will proceed to reward immediately.")
        }
        
        .alert("Time's Up!", isPresented: $isShowingTimesUpAlert) {
            Button("Yes, I finished") {
                accumulatedFish.append(contentsOf: viewModel.fishingVM.caughtFish)
                saveResult()
            }
            Button("I need more time") {
                accumulatedFish.append(contentsOf: viewModel.fishingVM.caughtFish)
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
        
        .sheet(isPresented: $isShowingAddTimeModal, onDismiss: {
            if extraTimeInMinutes > 0 {
                Task {
                    await viewModel.addMoreTime(minutes: extraTimeInMinutes)
                }
            }
        }) {
            AddTimeView(minutes: $extraTimeInMinutes)
        }
        
    }
    
    
    private func saveResult() {
        guard resultVM == nil else { return }
        
        print("Saving combined result — showing FocusEndView now")
        let newResultVM = FishResultViewModel(context: modelContext)
        
        let bonus = viewModel.bonusPointsFromNudge
        
        newResultVM.recordCombinedResult(fish: accumulatedFish, bonusPoints: bonus)
        
        self.resultVM = newResultVM
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    let mockSessionVM = FocusSessionViewModel()
    mockSessionVM.taskTitle = "Practice SwiftUI"
    mockSessionVM.remainingTime = 1
    
    return FocusModeView()
        .environmentObject(mockSessionVM)
}

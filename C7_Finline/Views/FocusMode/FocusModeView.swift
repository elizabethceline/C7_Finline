import SwiftUI
import SwiftData

struct FocusModeView: View {
    @EnvironmentObject var viewModel: FocusSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var isGivingUp = false
    @State private var resultVM: FishResultViewModel?
    @State private var isShowingGiveUpAlert = false

    var body: some View {
        ZStack {
            // MARK: - Background
            Image("backgroundSementara")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 910)
            
            // MARK: - Foreground Character
            VStack {
                Image("charaSementara")
                    .resizable()
                    .scaledToFit()
            }

            // MARK: - Content
            VStack(spacing: 32) {
                Spacer().frame(height: 80)

                // Title
                Text(viewModel.taskTitle.isEmpty ? "Focus Session" : viewModel.taskTitle)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(radius: 6)

                // Timer or End View
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

                // MARK: - Button (Dynamic)
                Button {
                    Task {
                        if resultVM != nil {
                            // "Done" behavior
                            viewModel.resetSession()
                            dismiss()
                        } else {
                            // "Give Up" behavior
//                            isGivingUp = true
//                            await viewModel.endSession()
//                            dismiss()
                            
                            isShowingGiveUpAlert = true
                        }
                    }
                } label: {
                    Text(resultVM != nil ? "Done" : "Give Up")
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
        .onChange(of: viewModel.shouldReturnToStart) { shouldReturn in
            if shouldReturn && !isGivingUp {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    saveResult()
                }
            }
        }
        .onAppear {
            isGivingUp = false
            resultVM = nil

            // Check if the timer already finished
            if viewModel.shouldReturnToStart && !isGivingUp {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    saveResult()
                }
            }
        }
        .alert("Are you sure?", isPresented: $isShowingGiveUpAlert) { // <-- ADD THIS MODIFIER
                    Button("Yes", role: .destructive) {
                        // Put the original "Give Up" logic here
                        Task {
                            isGivingUp = true
                            await viewModel.endSession()
                            dismiss()
                        }
                    }
                    Button("No", role: .cancel) { } // No action needed
                } message: {
                     Text("You will not receive any rewards if you give up now.")
                }

    }

    // MARK: - Helpers
    
    private func saveResult() {
        print("✅ Timer finished — showing FocusEndView now")
        let newResultVM = FishResultViewModel(context: modelContext)
        newResultVM.recordResult(from: viewModel)
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
  //  mockSessionVM.shouldReturnToStart = true // simulate finish

    return FocusModeView()
        .environmentObject(mockSessionVM)
}

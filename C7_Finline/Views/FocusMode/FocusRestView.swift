import SwiftUI
import SwiftData

struct FocusRestView: View {
    @EnvironmentObject var viewModel: FocusSessionViewModel
    
    let goalName: String?
    let restDuration: TimeInterval
    
    @State private var showEarlyFinishAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(goalName ?? "No Goal")
                .font(.headline)
                .bold()
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Text("You may now\nREST for a while.")
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
                .padding(.bottom)
            
            Spacer()
            
            FocusTimerCard(
                mode: .rest,
                timeText: viewModel.restRemainingTime > 0
                ? TimeFormatter.format(seconds: viewModel.restRemainingTime)
                : "Time’s Up!",
                primaryLabel: viewModel.restRemainingTime > 0 ? "I'm done resting" : "Back to Work",
                onPrimaryTap: {
                    if viewModel.restRemainingTime > 0 {
                        HapticManager.shared.playConfirmationHaptic()
                        showEarlyFinishAlert = true
                    } else {
                        HapticManager.shared.playSessionEndHaptic()
                        viewModel.endRest()
                    }
                }
            )
            .padding(.bottom, 40)
        }
        .onAppear{ viewModel.startRest(for: restDuration)}
        .onDisappear{ viewModel.endRest()}
        .alert("Done Resting?", isPresented: $showEarlyFinishAlert) {
            Button("Yes", role: .destructive) {
                HapticManager.shared.playConfirmationHaptic()
                viewModel.endRest()
                    }
                    Button("No", role: .cancel) { }
                } message: {
                    Text("Your focus timer will resume, and this rest period will still be acounted as used.")
                }
    }
}


#Preview {
    let mockSessionVM = FocusSessionViewModel()
    
    ZStack {
        Image("backgroundRest")
            .resizable()
            .frame(height: 910)
        
        VStack {
            Image("charaResting")
                .resizable()
                .scaledToFit()
        }
        
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            
            FocusRestView(
                goalName: mockSessionVM.goalName,
                restDuration: 300,
            )
        }
        .padding()
    }
    .environmentObject(mockSessionVM)
    .modelContainer(for: [Goal.self, GoalTask.self], inMemory: true)
}

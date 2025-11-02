import SwiftUI
import SwiftData

struct FocusRestView: View {
    let goalName: String?
    let restDuration: TimeInterval
    let onFinishRest: () -> Void
    
    @State private var remainingTime: TimeInterval
    @State private var timer: Timer?
    @State private var showEarlyFinishAlert = false
    
    init(goalName: String?, restDuration: TimeInterval, onFinishRest: @escaping () -> Void) {
        self.goalName = goalName
        self.restDuration = restDuration
        self.onFinishRest = onFinishRest
        _remainingTime = State(initialValue: restDuration)
    }
    
    var body: some View {
        // No ZStack - background handled by FocusModeView
        VStack(alignment: .leading) {
            // Goal name pill - MATCHING STYLE
            Text(goalName ?? "No Goal")
                .font(.headline)
                //.foregroundColor(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 2)
                .padding()
            
            // Rest message - MATCHING STYLE
            Text("You may now\nREST for a while.")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .shadow(radius: 6)
                .padding(.horizontal)
                .padding(.bottom)
            
            Spacer()
            
            // Timer display - MATCHING STYLE
            VStack(spacing: 16) {
                if remainingTime > 0 {
                    Text(formatTime(remainingTime))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()
                } else {
                    Text("Time's Up!")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                }
                
                Button(action: {
                    if remainingTime > 0 {
                        // Still have time left - show confirmation
                        showEarlyFinishAlert = true
                    } else {
                        // Time's up - go back immediately
                        stopRest()
                    }
                }) {
                    Text(remainingTime > 0 ? "I'm done resting" : "Back to Work")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.vertical)
            .padding(.bottom, 40)
        }
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
        .alert("Done Resting?", isPresented: $showEarlyFinishAlert) {
            Button("Yes", role: .destructive) {
                        stopRest()
                    }
                    Button("No", role: .cancel) { }
                } message: {
                    Text("Work timer will continue")
                }
    }
    
    // MARK: - Timer helpers
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                stopRest()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func stopRest() {
        stopTimer()
        onFinishRest()
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}


#Preview {
    let mockSessionVM = FocusSessionViewModel(networkMonitor: NetworkMonitor())
    mockSessionVM.taskTitle = "Initiate a Desk Research"
    mockSessionVM.goalName = "Write my Thesis"
    mockSessionVM.remainingTime = 1
    
    return ZStack {
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
                onFinishRest: {
                    print("Preview rest finished.")
                }
            )
        }
        .padding()
    }
    .environmentObject(mockSessionVM)
    .modelContainer(for: [Goal.self, GoalTask.self], inMemory: true)
}

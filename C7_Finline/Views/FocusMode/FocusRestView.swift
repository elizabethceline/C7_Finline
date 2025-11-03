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
                //.foregroundColor(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 2)
                .padding()
            
            Text("You may now\nREST for a while.")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .shadow(radius: 6)
                .padding(.horizontal)
                .padding(.bottom)
            
            Spacer()
            
            VStack(spacing: 16) {
                if viewModel.restRemainingTime > 0 {
                    Text(TimeFormatter.format(seconds: viewModel.restRemainingTime))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()
                } else {
                    Text("Time's Up!")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                }
                
                Button(action: {
                    if viewModel.restRemainingTime > 0 {
                        showEarlyFinishAlert = true
                    } else {
                        viewModel.endRest()
                    }
                }) {
                    Text(viewModel.restRemainingTime > 0 ? "I'm done resting" : "Back to Work")
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
//            .background(.ultraThinMaterial)
//            .background(Color.blue.opacity(0.3))
            .background {
                // Use glassEffect here if supported
                if #available(iOS 26.0, *) {
                    Color.blue.opacity(0.3)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.vertical)
            .padding(.bottom, 40)
        }
        .onAppear{ viewModel.startRest(for: restDuration)}
        .onDisappear{ viewModel.endRest()}
        .alert("Done Resting?", isPresented: $showEarlyFinishAlert) {
            Button("Yes", role: .destructive) {
                viewModel.endRest()
                    }
                    Button("No", role: .cancel) { }
                } message: {
                    Text("Your focus timer will resume, and this rest period will still be counted as used.")
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

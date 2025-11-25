import SwiftData
import SwiftUI
import ConfettiSwiftUI

struct FocusEndView: View {
    @ObservedObject var viewModel: FocusResultViewModel
    var onDismiss: () -> Void
    @State private var confettiTrigger = 0
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
            VStack(alignment: .center, spacing: 8) {
                Text("Focusing Session\nComplete")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    //.padding(.top, 52)
                    .padding(.bottom, 16)
                
                if viewModel.fishCaught.isEmpty {
                    Text("No fish caught this time! Try focusing a bit longer next round.")
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    FishSummaryCard(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity)
           // .padding(.horizontal)
                
                Spacer()
                
                FocusTimerCard(
                    mode: .focus,
                    timeText: "+\(viewModel.grandTotal.formatted(.number))",
                    timeImageName: "fishCoins",
                    primaryLabel: "Back to Main Menu",
                    onPrimaryTap: {
                        onDismiss()
                        StartFocusTip.hasEndedFocus = true
                    }
                )
               //.padding(.bottom, 16)
            }
          
        }
        .confettiCannon(
            trigger: $confettiTrigger,
            num: 40,
            colors: [.yellow, .green, .blue, .pink],
            confettiSize: 12,
            rainHeight: 900,
            fadesOut: true,
            radius: 600,
            repetitions: 3,
            repetitionInterval: 0.1,
            hapticFeedback: true
        )
        .onAppear {
            if !viewModel.fishCaught.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    confettiTrigger += 1
                }
            }
        }
    }
}

#Preview {
    let mockFish = [
        Fish.sample(of: .common),
        Fish.sample(of: .common),
        Fish.sample(of: .common),
        Fish.sample(of: .uncommon),
        Fish.sample(of: .uncommon),
        Fish.sample(of: .rare),
        Fish.sample(of: .superRare),
        Fish.sample(of: .legendary),
    ]
    
    let mockResult = FocusSessionResult(
        caughtFish: mockFish,
        duration: 1800,
        task: nil
    )
    
    let mockVM = FocusResultViewModel(
        context: nil,
        networkMonitor: NetworkMonitor.shared
    )
    mockVM.currentResult = mockResult
    mockVM.bonusPoints = 20
    
    return ZStack {
        Color.gray
            .ignoresSafeArea()
        FocusEndView(viewModel: mockVM) {
            print("Dismiss called in preview")
        }
    }
}

#Preview("No Fish Caught") {
    // Create a mock result with *no fish*
    let emptyResult = FocusSessionResult(
        caughtFish: [],
        duration: 1800,
        task: nil
    )
    
    let mockVM = FocusResultViewModel(
        context: nil,
        networkMonitor: NetworkMonitor.shared
    )
    mockVM.currentResult = emptyResult
    mockVM.bonusPoints = 0  // optional, just to make it clean
    
    return ZStack {
        Color.gray
            .ignoresSafeArea()
        FocusEndView(viewModel: mockVM) {
            print("Dismiss called in preview (no fish)")
        }
    }
}

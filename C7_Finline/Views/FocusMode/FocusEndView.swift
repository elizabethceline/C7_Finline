import SwiftData
import SwiftUI

struct FocusEndView: View {
    @ObservedObject var viewModel: FocusResultViewModel
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            //Spacer()
            // .frame(height: 40)

            Text("Focusing Session\nComplete")
                .font(.largeTitle.bold())
                //.foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 40)

            if viewModel.fishCaught.isEmpty {
                Text(
                    "No fish caught this time! Try focusing a bit longer next round."
                )
                //.foregroundColor(.white.opacity(0.7))
                .padding()
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                FishSummaryCard(viewModel: viewModel)
            }

            Spacer()

            FocusTimerCard(
                mode: .focus,
                timeText: "+\(viewModel.grandTotal.formatted(.number)) pts",
                primaryLabel: "Back to Main Menu",
                onPrimaryTap: {
                    onDismiss()
                    StartFocusTip.hasEndedFocus = true
                }
            )
            .padding(.bottom, 40)
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

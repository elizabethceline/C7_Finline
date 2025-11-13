import SwiftUI
import SwiftData

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
                Text("No fish caught this time! Try focusing a bit longer next round.")
                    //.foregroundColor(.white.opacity(0.7))
                    .padding(.top, 20)
            } else {
                FishSummaryCard(viewModel: viewModel)
            }
            
            Spacer()
            
            // Total points display
            VStack(spacing: 16) {
                Text("+\(viewModel.grandTotal) pts")
                    .font(.system(size: 60, weight: .bold))
                
                Button("Back to main Menu") {
                    onDismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
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
        Fish.sample(of: .legendary)
    ]
    
    let mockResult = FocusSessionResult(
        caughtFish: mockFish,
        duration: 1800,
        task: nil
    )
    
    let mockVM = FocusResultViewModel(context: nil, networkMonitor: NetworkMonitor())
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

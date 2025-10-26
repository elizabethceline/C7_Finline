import SwiftUI
import SwiftData

struct FocusView: View {
    @EnvironmentObject var viewModel: FocusSessionViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var fishResultVM: FishResultViewModel?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                Text(viewModel.taskTitle.isEmpty ? "Focus Session" : viewModel.taskTitle)
                    .font(.largeTitle)
                    .bold()
                
                Text(timeString(from: viewModel.remainingTime))
                    .font(.system(size: 48, weight: .semibold, design: .monospaced))
                    .padding(.horizontal)
                
                Spacer()
                
                Button("Give Up") {
                    Task {
                        await endSessionAndPrepareResult()
                    }
                }
                .buttonStyle(.borderedProminent)
                .font(.title3.bold())
                .padding(.bottom, 40)
            }
            .padding()
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: Binding(
                get: { fishResultVM != nil },
                set: { if !$0 { fishResultVM = nil } }
            )) {
                if let vm = fishResultVM {
                    FocusFishingResultView(viewModel: vm)
                }
            }
            .onChange(of: viewModel.shouldReturnToStart) { _ in
                Task{
                    await endSessionAndPrepareResult()
                }
            }
        }
    }
    
    private func endSessionAndPrepareResult() async {
        await viewModel.endSession()
        let resultVM = FishResultViewModel(context: modelContext)
        resultVM.recordResult(from: viewModel)
        fishResultVM = resultVM
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let i = Int(max(0, interval))
        let m = i / 60
        let s = i % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    let container = try! ModelContainer(for: Fish.self, FishingResult.self)
    FocusView()
        .environmentObject(FocusSessionViewModel())
        .environment(\.modelContext, container.mainContext)
}

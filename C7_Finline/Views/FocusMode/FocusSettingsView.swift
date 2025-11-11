import SwiftUI

struct FocusSettingsView: View {
    @EnvironmentObject var focusVM: FocusSessionViewModel
    @Binding var isNudgeMeOn: Bool
    var onDone: () -> Void 
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section() {
                    VStack(spacing: 16) {
                        ToggleCardView(
                            icon: "moon.fill",
                            title: "Deep Focus",
                            desc: "Finley helps you stay focused by blocking distracting apps.",
                            isOn: $focusVM.authManager.isEnabled
                        )
                        ToggleCardView(
                            icon: "bell.fill",
                            title: "Nudge Me",
                            desc: "Finley will go check on you if you are still working or not!",
                            isOn: $isNudgeMeOn
                        )
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
                .listRowBackground(Color.clear)
                
            }
            .offset(y:-25)
            .navigationTitle("Focus Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onDone()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isNudgeOn = true
    // Create dummy data for the preview
    let mockFocusVM = FocusSessionViewModel()
    
    return FocusSettingsView(
        isNudgeMeOn: $isNudgeOn,
        onDone: { print("Done Tapped!") } // Updated for new closure
    )
    .environmentObject(mockFocusVM)
}

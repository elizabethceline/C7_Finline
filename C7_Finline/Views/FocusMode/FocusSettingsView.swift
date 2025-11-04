import SwiftUI

struct FocusSettingsView: View {
    @EnvironmentObject var focusVM: FocusSessionViewModel
    @Binding var isNudgeMeOn: Bool
    var onDone: () -> Void // Closure to call when checkmark is tapped
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Focus Options") {
                    HStack(spacing: 16) {
                        ToggleCardView(
                            icon: "moon.fill",
                            title: "Deep Focus",
                            isOn: $focusVM.authManager.isEnabled
                        )
                        ToggleCardView(
                            icon: "bell.fill",
                            title: "Nudge Me",
                            isOn: $isNudgeMeOn
                        )
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Focus Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // --- 1. "X" Button (Cancel) ---
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                }
                
                // --- 2. "Checkmark" Button (Done) ---
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onDone()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
            // --- 3. Removed the .safeAreaInset button ---
        }
    }
}

#Preview {
    // Create dummy data for the preview
    let mockFocusVM = FocusSessionViewModel()
    @State var isNudgeOn = true
    
    return FocusSettingsView(
        isNudgeMeOn: $isNudgeOn,
        onDone: { print("Done Tapped!") } // Updated for new closure
    )
    .environmentObject(mockFocusVM)
}

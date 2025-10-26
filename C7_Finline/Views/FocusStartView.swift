//ini sementara sambil nunggu TaskDetailView

import SwiftUI
import FamilyControls

struct FocusStartView: View {
    @EnvironmentObject var viewModel: FocusSessionViewModel
    @State private var duration: Double = 5 // minutes
    @State private var deepFocusEnabled: Bool = true
    @State private var navigateToFocus = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("How many minutes?")
                        .font(.headline)
                    Stepper("\(Int(duration)) minutes",
                            value: $duration,
                            in: 5...120,
                            step: 5)
                        .frame(width: 200)
                }

                Toggle(isOn: $deepFocusEnabled) {
                    Text("Activate Deep Focus?")
                        .font(.title3)
                        .bold()
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .padding(.horizontal)

                if let error = viewModel.authorizationError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    viewModel.sessionDuration = duration * 60
                    viewModel.deepFocusEnabled = deepFocusEnabled
                    viewModel.startSession()
                    navigateToFocus = true // trigger navigation
                } label: {
                    Text("Start Focus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .font(.title3.bold())
                }
                .buttonStyle(.borderedProminent)
                .cornerRadius(12)
                
                // Hidden NavigationLink
                NavigationLink(
                    destination: FocusView()
                        .environmentObject(viewModel),
                    isActive: $navigateToFocus
                ) {
                    EmptyView()
                }
            }
            .padding()
            .onAppear {
                viewModel.configureAuthorizationIfNeeded()
            }
        }
    }
}

#Preview {
    FocusStartView()
        .environmentObject(FocusSessionViewModel())
}

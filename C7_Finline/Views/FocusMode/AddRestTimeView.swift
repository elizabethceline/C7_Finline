import SwiftUI

struct AddRestTimeView: View {
    @Binding var restMinutes: Int
    let maxRestMinutes: Int
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            Text("Set Your Time Rest")
                .font(.largeTitle.bold())
                .padding(.top, 20)
            
            // Stepper Section
            HStack(spacing: 12) {
                Text("\(restMinutes) minute\(restMinutes == 1 ? "" : "s")")
                    .font(.title2)
                
                
                Stepper(value: $restMinutes, in: 5...maxRestMinutes, step: 5) {
                    EmptyView()
                }
                .labelsHidden()
                //.tint(.white)
                //.frame(maxWidth: 200)
            }
            
//           Spacer()
//                .frame(height:5)
            
            // Buttons
            HStack(spacing: 16) {
                Button(action: onConfirm) {
                    Text("Rest Now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background( Color.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        //.padding(.horizontal, 40)
                        .padding(.bottom, 30)
                }
                
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.headline)
                       // .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        //.padding(.horizontal, 40)
                        .padding(.bottom, 30)
                    
                }
            }
            .padding(.horizontal, 40)
            .presentationDetents([.height(400)])
        }
        //.background(Color.blue.opacity(0.3))
        
    }
}

#Preview {
    AddRestTimeView(
        restMinutes: .constant(5),
        maxRestMinutes: 20,
        onConfirm: {},
        onCancel: {}
    )
    // .preferredColorScheme(.dark)
}

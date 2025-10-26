import SwiftUI

struct AddTimeView: View {
    @Binding var minutes: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 40) {
            Text("Add More Time")
                .font(.largeTitle.bold())
                .padding(.top, 20)
            
            Stepper("\(minutes) minutes", value: $minutes, in: 1...60)
                .font(.title2)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button("Add Time") {
                dismiss()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue) // Or any color you prefer
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .presentationDetents([.height(300)])
    }
}

#Preview {
    AddTimeView(minutes: .constant(5))
}

import SwiftUI

struct AddTimeView: View {
    //@Binding var minutes: Int
    var onAddTime: (Int, Int, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedHours = 0
    @State private var selectedMinutes = 5
    @State private var selectedSeconds = 0
    
    private var isTimeValid: Bool {
        selectedHours > 0 || selectedMinutes > 0 || selectedSeconds > 0
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Add More Time")
                .font(.largeTitle.bold())
                .padding(.top, 20)
            
            HStack(spacing: 0) {
                // Hours Picker
                Picker("", selection: $selectedHours) {
                    ForEach(0..<24) { hour in
                        Text("\(hour)")
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                
                Text("hours")
                    .font(.title2)
                    .frame(width: 80, alignment: .leading)
                
                // Minutes Picker
                Picker("", selection: $selectedMinutes) {
                    ForEach(0..<60) { minute in
                        Text("\(minute)")
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                
                Text("min")
                    .font(.title2)
                    .frame(width: 80, alignment: .leading)
                
                // Seconds Picker
                Picker("", selection: $selectedSeconds) {
                    ForEach(0..<60) { second in
                        Text("\(second)")
                            .tag(second)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                
                Text("sec")
                    .font(.title2)
                    .frame(width: 80, alignment: .leading)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button("Add Time") {
                // Convert to total minutes (rounded up if there are seconds)
//                let totalMinutes = selectedHours * 60 + selectedMinutes + (selectedSeconds > 0 ? 1 : 0)
//                minutes = totalMinutes
                onAddTime(selectedHours, selectedMinutes, selectedSeconds)
                dismiss()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isTimeValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
            .disabled(!isTimeValid)
        }
//        .onAppear {
//            // Initialize with the current binding value
//            if minutes >= 60 {
//                selectedHours = minutes / 60
//                selectedMinutes = minutes % 60
//            } else {
//                selectedMinutes = minutes
//            }
//        }
        .presentationDetents([.height(400)])
    }
}
#Preview {
    AddTimeView { hours, minutes, seconds in
        print("Preview Add: \(hours)h \(minutes)m \(seconds)s")
    }
}

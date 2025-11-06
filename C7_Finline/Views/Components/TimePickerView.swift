//
//  TimePickerView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 06/11/25.
//

import SwiftUI
import UIKit

struct TimerPickerSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var hours: Int
    @Binding var minutes: Int
    var onSelectDuration: (Int) -> Void 

    var body: some View {
        NavigationStack {
            VStack {
                TimerPickerView(hours: $hours, minutes: $minutes)
                    .frame(maxHeight: 200)
                    .padding()

                Spacer()
            }
            .navigationTitle("Select Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let totalMinutes = hours * 60 + minutes
                        onSelectDuration(totalMinutes)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct TimerPickerView: UIViewRepresentable {
    @Binding var hours: Int
    @Binding var minutes: Int

    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator

        let hourLabel = UILabel(frame: CGRect(x: picker.bounds.width * 0.25 - 25, y: 0, width: 50, height: 30))
        hourLabel.text = "Hour"
        hourLabel.textAlignment = .center
        picker.addSubview(hourLabel)

        let minuteLabel = UILabel(frame: CGRect(x: picker.bounds.width * 0.75 - 25, y: 0, width: 50, height: 30))
        minuteLabel.text = "Mins"
        picker.addSubview(minuteLabel)

        return picker
    }

    func updateUIView(_ uiView: UIPickerView, context: Context) {
        uiView.selectRow(hours, inComponent: 0, animated: true)
        uiView.selectRow(minutes, inComponent: 1, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: TimerPickerView

        init(_ parent: TimerPickerView) {
            self.parent = parent
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch component {
            case 0: return 24
            case 1: return 60
            default: return 0
            }
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            String(format: "%02d", row)
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch component {
            case 0: parent.hours = row
            case 1: parent.minutes = row
            default: break
            }
        }
    }
}


#Preview {
    TimerPickerSheetView(hours: .constant(1), minutes: .constant(30)) { totalMinutes in
        print("Total duration in minutes: \(totalMinutes)")
    }
    .preferredColorScheme(.light)
}

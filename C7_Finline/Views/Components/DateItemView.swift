//
//  DateItemView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct DateItemView: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void

    private func shortWeekday(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(shortWeekday(from: date))
                    .font(.caption)
                    .foregroundColor(Color(uiColor: .secondaryLabel))

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(uiColor: .label))
            }
            .frame(width: 60, height: 55)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.primary : Color.clear,
                        lineWidth: 2
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

#Preview {
    DateItemView(
        date: Date(),
        isSelected: true,
        action: {}
    )
    .padding()
}

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
    let hasUnfinishedTask: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private func shortWeekday(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    Text(shortWeekday(from: date))
                        .font(.caption)
                        .foregroundColor(Color(uiColor: .secondaryLabel))

                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(uiColor: .label))
                }
                .frame(width: 44, height: 52)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            (colorScheme == .light
                                ? Color(.systemBackground)
                                : Color(.systemGray6))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.primary : Color.clear,
                            lineWidth: 2
                        )
                )

                if hasUnfinishedTask {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                    .offset(x: 5, y: -5)
                    .zIndex(1)

                }
            }
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

#Preview {
    DateItemView(
        date: Date(),
        isSelected: true,
        hasUnfinishedTask: true,
        action: {}
    )
    .padding()
}

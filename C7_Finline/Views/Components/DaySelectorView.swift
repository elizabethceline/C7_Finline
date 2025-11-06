//
//  DaySelectorView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 28/10/25.
//

import SwiftUI

struct DaySelectorView: View {
    @Binding var selectedDay: DayOfWeek

    var body: some View {
        HStack {
            ForEach(DayOfWeek.allCases, id: \.self) { day in
                Button {
                    selectedDay = day
                } label: {
                    Text(day.shortLabel)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Color(uiColor: .systemBackground)
                        )
                        .foregroundColor(
                            Color(uiColor: .label)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    selectedDay == day
                                        ? Color.primary : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .animation(
                            .easeInOut(duration: 0.2),
                            value: selectedDay == day
                        )
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    DaySelectorView(selectedDay: .constant(.wednesday))
        .padding()
        .background(Color.gray.opacity(0.2))
}

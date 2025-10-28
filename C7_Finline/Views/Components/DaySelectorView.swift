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
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedDay == day ? Color.blue : Color.white
                        )
                        .foregroundColor(
                            selectedDay == day ? .white : .primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(
                            color: selectedDay == day ? .blue.opacity(0.2) : .clear,
                            radius: 2, y: 2
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

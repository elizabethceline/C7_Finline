//
//  GoalHeaderView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct GoalHeaderView: View {
    let goalName: String

    var body: some View {
        HStack {
            Text(goalName)
                .font(.headline)
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.title3)
                .padding(8)
                .background(Color(uiColor: .systemBackground))
                .foregroundColor(Color(uiColor: .label))
                .cornerRadius(50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.secondary)
        .cornerRadius(50)
    }
}

#Preview {
    GoalHeaderView(goalName: "Merancang Skripsi")
        .padding()
}

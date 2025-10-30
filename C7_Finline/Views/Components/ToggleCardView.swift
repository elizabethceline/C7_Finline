//
//  ToogleCardView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 31/10/25.
//

import SwiftUI

struct ToggleCardView: View {
    
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.black)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Spacer()
                .frame(height: 16)
            
            HStack {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.black)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct ToggleCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ToggleCardViewPreviewWrapper()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.light)
    }
    
    struct ToggleCardViewPreviewWrapper: View {
        @State private var isOn1 = true
        @State private var isOn2 = false
        
        var body: some View {
            VStack(spacing: 16) {
                ToggleCardView(icon: "moon", title: "Enable Dark Mode", isOn: $isOn1)
                ToggleCardView(icon: "moon", title: "Enable Notifications", isOn: $isOn2)
            }
        }
    }
}


//
//  ToastView.swift
//  selfManager
//
//  Created by AI Assistant on 24.12.25.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let isSuccess: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isSuccess ? .green : .red)
            Text(message)
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }
}

#Preview {
    VStack {
        ToastView(message: "操作成功！", isSuccess: true)
        ToastView(message: "操作失败！", isSuccess: false)
    }
}
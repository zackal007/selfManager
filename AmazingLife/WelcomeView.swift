//
//  WelcomeView.swift
//  selfManager
//
//  Created by zack on 24.8.6.
//

import SwiftUI
import SwiftData

struct WelcomeView: View {
    // 动画状态
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    
    // 加载状态和错误处理
    let loadingError: Error?
    let retryAction: () -> Void
    let isLoading: Bool
    
    // 初始化方法
    init(loadingError: Error? = nil, retryAction: @escaping () -> Void, isLoading: Bool) {
        self.loadingError = loadingError
        self.retryAction = retryAction
        self.isLoading = isLoading
    }
    
    var body: some View {
        ZStack {
            // 纯色背景
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // 应用标语
                Text("成为更好的自己")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .opacity(textOpacity)
                
                Spacer()
                
                // 仅显示错误信息，移除进度条和加载文字
                Group {
                    if loadingError == nil {
                        // 空视图，移除了进度条和加载文字
                        EmptyView()
                    } else {
                        // 错误信息
                        VStack(spacing: 15) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            Text("数据加载失败")
                                .font(.headline)
                            
                            Text(loadingError?.localizedDescription ?? "未知错误")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .foregroundColor(.secondary)
                            
                            Button("重试") {
                                retryAction()
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            // 启动动画序列
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                logoOpacity = 1
                logoScale = 1
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
                textOpacity = 1
            }
        }
    }
}

#Preview {
    WelcomeView(retryAction: {}, isLoading: true)
}
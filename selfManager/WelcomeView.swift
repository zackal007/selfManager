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
    @State private var indicatorOpacity: Double = 0
    @State private var loadingProgress: Double = 0
    
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
            // 背景
            Image("WelcomeBackground")
                .resizable()
                .scaledToFill()
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
                
                // 应用名称
                Text("自我管理")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .opacity(textOpacity)
                
                // 应用标语
                Text("成为更好的自己")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .opacity(textOpacity)
                
                Spacer()
                
                // 加载指示器或错误信息
                Group {
                    if loadingError == nil {
                        VStack(spacing: 15) {
                            // 自定义进度条
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 200, height: 4)
                                    .foregroundColor(Color(.systemGray5))
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 200 * loadingProgress, height: 4)
                                    .foregroundColor(Color("AccentColor"))
                            }
                            
                            Text("正在加载数据...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .opacity(indicatorOpacity)
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
                .opacity(indicatorOpacity)
                
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
            
            withAnimation(.easeOut(duration: 0.8).delay(1.4)) {
                indicatorOpacity = 1
            }
            
            // 模拟加载进度
            if isLoading && loadingError == nil {
                withAnimation(.easeInOut(duration: 2.5)) {
                    loadingProgress = 1.0
                }
            }
        }
    }
}

#Preview {
    WelcomeView(retryAction: {}, isLoading: true)
}
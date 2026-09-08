//
//  GoalDetailHabitDemo.swift
//  selfManager
//
//  目标详情页习惯类型悬浮按钮演示
//

import SwiftUI

struct GoalDetailHabitDemo: View {
    @State private var selectedGoalType: GoalType = .habit
    @State private var showDemo = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("目标详情页悬浮按钮演示")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("功能说明")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    FeatureRow(icon: "flame.fill", text: "仅在类型为\"习惯\"的目标详情页显示悬浮打卡按钮")
                    FeatureRow(icon: "eye.slash", text: "其他类型目标（人生目标、年度目标、短期目标）不显示该按钮")
                    FeatureRow(icon: "checkmark.circle", text: "使用条件判断 goal.goalType == .habit")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                VStack(spacing: 20) {
                    Text("选择目标类型进行测试:")
                        .font(.headline)
                    
                    Picker("目标类型", selection: $selectedGoalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                                .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    Button(action: {
                        showDemo = true
                    }) {
                        HStack {
                            Image(systemName: "eye")
                            Text("查看详情页")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showDemo) {
                DemoGoalDetailView(goalType: selectedGoalType)
            }
        }
    }
}

struct DemoGoalDetailView: View {
    let goalType: GoalType
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // 模拟目标详情页内容
                VStack(spacing: 20) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundColor(goalType.color)
                    
                    Text("示例\(goalType.rawValue)")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("这是一个\(goalType.rawValue)类型的目标")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("目标类型:")
                            .font(.headline)
                        Spacer()
                        Text(goalType.rawValue)
                            .font(.headline)
                            .foregroundColor(goalType.color)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("目标详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .overlay(
                Group {
                    if goalType == .habit {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    // 点击hit按钮的操作
                                }) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 56)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                                }
                                .padding(.trailing, 24)
                                .padding(.bottom, 32)
                            }
                        }
                    }
                }
            )
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct GoalDetailHabitDemo_Previews: PreviewProvider {
    static var previews: some View {
        GoalDetailHabitDemo()
    }
}
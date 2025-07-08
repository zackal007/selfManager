//
//  GoalDetailView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI

struct GoalDetailView: View {
    let goal: Goal
    
    // 状态变量
    @State private var showEditSheet = false
    @State private var showAddTaskSheet = false
    @Environment(\.presentationMode) var presentationMode
    
    // 计算属性
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter.string(from: goal.createTime)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 内容开始
                // 顶部留白
                Color.clear.frame(height: 8) // 增加顶部留白，与首页保持一致
                // 顶部区域（保持原有背景色）
                // 顶部区域：目标名称和进度
                VStack(alignment: .leading, spacing: 8) {
                    // 目标名称和进度
                    HStack {
                        Button(action: { showEditSheet = true }) {
                            Text(goal.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(UIColor.label))
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                        // 进度环形指示器
                        ZStack {
                            Circle()
                                .stroke(Color(UIColor.systemGray5), lineWidth: 4)
                                .frame(width: 40, height: 40)
                            Circle()
                                .trim(from: 0, to: CGFloat(goal.progress))
                                .stroke(
                                    goal.progress > 0.7 ? Color(UIColor.systemGreen) : (goal.progress > 0.3 ? Color(UIColor.systemOrange) : Color(UIColor.systemRed)),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(goal.progress * 100))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(UIColor.label))
                        }
                        .frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    // 设置时间
                    HStack(spacing: 4) {
                        Text("设置时间: ")
                            .font(.system(size: 14))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Button(action: { showEditSheet = true }) {
                            Text(formattedDate)
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    // 目标描述
                    Button(action: { showEditSheet = true }) {
                        Text(goal.description)
                            .font(.system(size: 16))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                    // 标签
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(goal.tags, id: \.self) { tag in
                                Button(action: { showEditSheet = true }) {
                                    HStack(spacing: 4) {
                                        Text("#")
                                            .foregroundColor(Color(UIColor.systemBlue))
                                        Text(tag)
                                            .foregroundColor(Color(UIColor.systemBlue))
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(UIColor.systemBlue).opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            // 添加标签按钮
                            Button(action: { showEditSheet = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .frame(width: 24, height: 24)
                                    .background(Color(UIColor.systemBlue).opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .frame(height: 40)
                }
                .padding(.bottom, 16)
                // 上级目标和子目标
                HStack(spacing: 12) {
                    // 上级目标
                    VStack(alignment: .leading, spacing: 8) {
                        Text("上级目标:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(goal.upperProject, id: \.self) { project in
                                    Button(action: { showEditSheet = true }) {
                                        Text(project)
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(UIColor.systemBlue))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .cornerRadius(12)
                    .frame(width: (UIScreen.main.bounds.width - 16*2 - 12) / 2)
                    .frame(height: 150)
                    // 子目标
                    VStack(alignment: .leading, spacing: 8) {
                        Text("子目标:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(goal.subProject, id: \.self) { project in
                                    Button(action: { showEditSheet = true }) {
                                        Text(project)
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(UIColor.systemBlue))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .cornerRadius(12)
                    .frame(width: (UIScreen.main.bounds.width - 16*2 - 12) / 2)
                    .frame(height: 150)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                // 子任务列表
                VStack(alignment: .leading, spacing: 12) {
                    Text("子任务列表:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    ForEach(goal.tasks) { task in
                        HStack(spacing: 12) {
                            // 复选框（参考备忘录样式）
                            ZStack {
                                Circle()
                                    .stroke(task.isCompleted ? Color.clear : Color(UIColor.systemGray3), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                                
                                if task.isCompleted {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 22, height: 22)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // 任务标题
                            Text(task.title)
                                .font(.system(size: 16))
                                .foregroundColor(Color(UIColor.label))
                                .strikethrough(task.isCompleted)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                    }
                    
                    // 添加任务按钮
                    Button(action: {
                        showAddTaskSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(UIColor.systemBlue))
                            
                            Text("添加任务")
                                .font(.system(size: 16))
                                .foregroundColor(Color(UIColor.systemBlue))
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                    }
                }
                .padding(.bottom, 16)
                
                // 分段控制器
                Picker("选择视图", selection: Binding<Int>(get: { 0 }, set: { _ in })) {
                    Text("人生").tag(0)
                    Text("年度").tag(1)
                    Text("短期").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                // 添加一个实际的View组件替代注释
                VStack {
                    Text("目标进度详情")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(
            trailing: Button(action: {
                showEditSheet = true
            }) {
                Text("编辑")
                    .foregroundColor(Color(UIColor.systemBlue))
            }
        )
        .sheet(isPresented: $showEditSheet) {
            // 编辑目标的表单视图
            Text("编辑目标")
        }
        .sheet(isPresented: $showAddTaskSheet) {
            // 添加任务的表单视图
            Text("添加任务")
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // 点击hit按钮的操作
                    }) {
                        Text("hit")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        )
    }
}


#Preview {
    NavigationView {
        GoalDetailView(goal: Goal(
            id: UUID(),
            name: "目标名称",
            description: "描述一下这个目标的具体内容",
            progress: 0.7,
            tasks: [
                Task(id: 1, title: "子任务1", isCompleted: true),
                Task(id: 2, title: "子任务2", isCompleted: false)
            ],
            backgroundImage: nil,
            tags: ["tag1", "tag2", "tag3"],
            upperProject: ["上级目标1", "上级目标2"],
            subProject: ["子目标1", "子目标2"],
            recordNum: 5,
            category: "技能提升",
            createTime: Date(),
            modifyTime: Date(),
            visitTime: Date()
        ))
    }
}
//
//  RecordView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import UIKit
import Foundation
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 查询记录
    @Query(sort: \Record.createTime, order: .reverse) private var allRecords: [Record]
    
    // 当前显示的记录
    @State private var currentRecord: Record?
    
    // 绑定到TabView的选中标签
    @Binding var selectedTab: Int
    
    // 记录类型选择器
    @State private var selectedRecordType: RecordType = .daily
    
    // 当前日期
    @State private var currentDate = Date()
    
    // 当前年份
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    
    // 当前月份
    @State private var currentMonth = Calendar.current.component(.month, from: Date())
    
    // 当前季度
    @State private var currentQuarter = (Calendar.current.component(.month, from: Date()) - 1) / 3 + 1
    
    // 当前周
    @State private var currentWeek = Calendar.current.component(.weekOfYear, from: Date())
    
    // 年份变化动画
    @State private var dateChangeAnimation = false
    @State private var dateChangeDirection = ""
    @State private var showDateChangeToast = false
    
    // 记录内容
    @State private var recordContent = ""
    @State private var selectedMood: String? = nil
    @State private var selectedWeather: String? = nil
    
    // 显示保存成功提示
    @State private var showSaveSuccessToast = false
    
    // 初始化方法，接收selectedTab绑定
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部标题栏
                HStack {
                    Text("记录")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 记录类型选择器
                Picker("记录类型", selection: $selectedRecordType) {
                    Text("日记").tag(RecordType.daily)
                    Text("周记").tag(RecordType.weekly)
                    Text("月记").tag(RecordType.monthly)
                    Text("季记").tag(RecordType.quarterly)
                    Text("年记").tag(RecordType.yearly)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedRecordType) { _, _ in
                    // 当记录类型变化时，加载对应的记录
                    loadCurrentRecord()
                }
                
                // 日期选择器
                VStack {
                    // 根据选择的记录类型显示不同的日期选择器
                    switch selectedRecordType {
                    case .daily: // 日记
                        HStack(spacing: 12) {
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dateChangeAnimation = true
                                    currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                                    dateChangeDirection = "减少"
                                }
                                // 使用Timer替代DispatchQueue以避免多线程问题
                                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    dateChangeAnimation = false
                                    showDateChangeToast = true
                                    
                                    // 嵌套Timer替代第二个DispatchQueue
                                    Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                        showDateChangeToast = false
                                    }
                                }
                                // 加载选择日期的记录
                                loadCurrentRecord()
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Text(formattedDate)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(minWidth: 120)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.9)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .scaleEffect(dateChangeAnimation ? 0.9 : 1)
                                .opacity(dateChangeAnimation ? 0.7 : 1)
                                .rotationEffect(Angle(degrees: dateChangeAnimation ? 2 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dateChangeAnimation)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dateChangeAnimation = true
                                    currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                                    dateChangeDirection = "增加"
                                }
                                // 使用Timer替代DispatchQueue以避免多线程问题
                                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    dateChangeAnimation = false
                                    showDateChangeToast = true
                                    
                                    // 嵌套Timer替代第二个DispatchQueue
                                    Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                        showDateChangeToast = false
                                    }
                                }
                                // 加载选择日期的记录
                                loadCurrentRecord()
                            }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                    case .weekly: // 周记
                        HStack(spacing: 12) {
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dateChangeAnimation = true
                                    currentWeek -= 1
                                    if currentWeek < 1 {
                                        currentYear -= 1
                                        currentWeek = 52 // 假设一年有52周
                                    }
                                    dateChangeDirection = "减少"
                                }
                                // 使用Timer替代DispatchQueue以避免多线程问题
                                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    dateChangeAnimation = false
                                    showDateChangeToast = true
                                    
                                    // 嵌套Timer替代第二个DispatchQueue
                                    Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                        showDateChangeToast = false
                                    }
                                }
                                // 加载选择日期的记录
                                loadCurrentRecord()
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Text("\(currentYear)年第\(currentWeek)周")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(minWidth: 120)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.9)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .scaleEffect(dateChangeAnimation ? 0.9 : 1)
                                .opacity(dateChangeAnimation ? 0.7 : 1)
                                .rotationEffect(Angle(degrees: dateChangeAnimation ? 2 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dateChangeAnimation)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dateChangeAnimation = true
                                    currentWeek += 1
                                    if currentWeek > 52 { // 假设一年有52周
                                        currentYear += 1
                                        currentWeek = 1
                                    }
                                    dateChangeDirection = "增加"
                                }
                                // 使用Timer替代DispatchQueue以避免多线程问题
                                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    dateChangeAnimation = false
                                    showDateChangeToast = true
                                    
                                    // 嵌套Timer替代第二个DispatchQueue
                                    Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                        showDateChangeToast = false
                                    }
                                }
                                // 加载选择日期的记录
                                loadCurrentRecord()
                            }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                    case .monthly: // 月记
                        HStack(spacing: 12) {
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dateChangeAnimation = true
                                    currentMonth -= 1
                                    if currentMonth < 1 {
                                        currentYear -= 1
                                        currentMonth = 12
                                    }
                                    dateChangeDirection = "减少"
                                }
                                // 使用Timer替代DispatchQueue以避免多线程问题
                                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    dateChangeAnimation = false
                                    showDateChangeToast = true
                                    
                                    // 嵌套Timer替代第二个DispatchQueue
                                    Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                        showDateChangeToast = false
                                    }
                                }
                                // 加载选择日期的记录
                                loadCurrentRecord()
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Text("\(currentYear)年\(currentMonth)月")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(minWidth: 120)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.9)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .scaleEffect(dateChangeAnimation ? 0.9 : 1)
                                .opacity(dateChangeAnimation ? 0.7 : 1)
                                .rotationEffect(Angle(degrees: dateChangeAnimation ? 2 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dateChangeAnimation)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dateChangeAnimation = true
                                    currentMonth += 1
                                    if currentMonth > 12 {
                                        currentYear += 1
                                        currentMonth = 1
                                    }
                                    dateChangeDirection = "增加"
                                }
                                // 使用Timer替代DispatchQueue以避免多线程问题
                                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    dateChangeAnimation = false
                                    showDateChangeToast = true
                                    
                                    // 嵌套Timer替代第二个DispatchQueue
                                    Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                        showDateChangeToast = false
                                    }
                                }
                                // 加载选择日期的记录
                                loadCurrentRecord()
                            }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                    case .quarterly: // 季记
                        HStack(spacing: 12) {
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dateChangeAnimation = true
                                    currentQuarter -= 1
                                    if currentQuarter < 1 {
                                        currentYear -= 1
                                        currentQuarter = 4
                                    }
                                    dateChangeDirection = "减少"
                                }
                                // 使用Timer替代DispatchQueue以避免多线程问题
                                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    dateChangeAnimation = false
                                    showDateChangeToast = true
                                    
                                    // 嵌套Timer替代第二个DispatchQueue
                                    Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                        showDateChangeToast = false
                                    }
                                }
                                // 加载选择日期的记录
                                loadCurrentRecord()
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Text("\(currentYear)年第\(currentQuarter)季度")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(minWidth: 120)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.9)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .scaleEffect(dateChangeAnimation ? 0.9 : 1)
                                .opacity(dateChangeAnimation ? 0.7 : 1)
                                .rotationEffect(Angle(degrees: dateChangeAnimation ? 2 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dateChangeAnimation)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dateChangeAnimation = true
                                    currentQuarter += 1
                                    if currentQuarter > 4 {
                                        currentYear += 1
                                        currentQuarter = 1
                                    }
                                    dateChangeDirection = "增加"
                                }
                                // 使用Timer替代DispatchQueue以避免多线程问题
                                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    dateChangeAnimation = false
                                    showDateChangeToast = true
                                    
                                    // 嵌套Timer替代第二个DispatchQueue
                                    Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                        showDateChangeToast = false
                                    }
                                }
                                // 加载选择日期的记录
                                loadCurrentRecord()
                            }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                    case .yearly: // 年记
                        HStack(spacing: 12) {
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dateChangeAnimation = true
                                    currentYear -= 1
                                    dateChangeDirection = "减少"
                                }
                                // 使用Timer替代DispatchQueue以避免多线程问题
                                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    dateChangeAnimation = false
                                    showDateChangeToast = true
                                    
                                    // 嵌套Timer替代第二个DispatchQueue
                                    Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                        showDateChangeToast = false
                                    }
                                }
                                // 加载选择日期的记录
                                loadCurrentRecord()
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Text("\(currentYear)年")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(minWidth: 60)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.9)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .scaleEffect(dateChangeAnimation ? 0.9 : 1)
                                .opacity(dateChangeAnimation ? 0.7 : 1)
                                .rotationEffect(Angle(degrees: dateChangeAnimation ? 2 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dateChangeAnimation)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dateChangeAnimation = true
                                    currentYear += 1
                                    dateChangeDirection = "增加"
                                }
                                // 使用Timer替代DispatchQueue以避免多线程问题
                                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    dateChangeAnimation = false
                                    showDateChangeToast = true
                                    
                                    // 嵌套Timer替代第二个DispatchQueue
                                    Timer.scheduledTimer(withTimeInterval: 1.7, repeats: false) { _ in
                                        showDateChangeToast = false
                                    }
                                }
                                // 加载选择日期的记录
                                loadCurrentRecord()
                            }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                    default:
                        EmptyView()
                    }
                }
                .padding(.bottom, 8)
                
                // 记录内容区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 显示记录内容
                        VStack(alignment: .leading, spacing: 12) {
                            Text(recordTitle)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            TextEditor(text: $recordContent)
                                .frame(minHeight: UIScreen.main.bounds.height * 0.4) // 使用屏幕高度的40%作为最小高度
                                .padding(8)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.horizontal)
                                .onAppear {
                                    // 加载当前选择日期的记录
                                    loadCurrentRecord()
                                }
                        }
                        
                        // 心情选择（只在日记页签中显示）
                        if selectedRecordType == .daily {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("心情")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(["😊", "😢", "😡", "😴", "🤔", "😎"], id: \.self) { mood in
                                            Button(action: {
                                                selectedMood = mood
                                            }) {
                                                Text(mood)
                                                    .font(.system(size: 30))
                                                    .padding(8)
                                                    .background(
                                                        Circle()
                                                            .fill(selectedMood == mood ? Color.blue.opacity(0.2) : Color.clear)
                                                    )
                                                    .overlay(
                                                        Circle()
                                                            .stroke(selectedMood == mood ? Color.blue : Color.clear, lineWidth: 2)
                                                    )
                                            }
                                            .buttonStyle(ScaleButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // 保存按钮
                        Button(action: {
                            // 保存记录
                            saveRecord()
                        }) {
                            Text("保存记录")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.9)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .padding()
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.bottom, 20)
                    
                    // 保存成功提示
                    if showSaveSuccessToast {
                        VStack {
                            Text("保存成功")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(radius: 3)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .background(Color.black.opacity(0.2))
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        .onAppear {
                            // 使用计时器替代异步队列
                            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                                withAnimation {
                                    showSaveSuccessToast = false
                                }
                            }
                        }
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(16)
            }
            .navigationBarHidden(true)
            .onAppear {
                // 视图首次加载时加载当前记录
                loadCurrentRecord()
            }
        }
    }
    
    // 格式化日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: currentDate)
    }
    
    // 记录标题
    var recordTitle: String {
        switch selectedRecordType {
        case .daily:
            return "\(formattedDate) 日记"
        case .weekly:
            return "\(currentYear)年第\(currentWeek)周 周记"
        case .monthly:
            return "\(currentYear)年\(currentMonth)月 月记"
        case .quarterly:
            return "\(currentYear)年第\(currentQuarter)季度 季记"
        case .yearly:
            return "\(currentYear)年 年记"
        }
    }
    
    // 保存记录方法
    private func saveRecord() {
        // 检查内容是否为空
        guard !recordContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // 根据记录类型获取对应的日期
        var recordDate = currentDate
        var recordTypeString = "日记"
        
        switch selectedRecordType {
        case .daily: // 日记
            recordTypeString = "日记"
            // 使用当前选择的日期
        case .weekly: // 周记
            recordTypeString = "周记"
            // 获取所选周的第一天
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = currentYear
            components.weekOfYear = currentWeek
            components.weekday = 1 // 周日
            if let date = calendar.date(from: components) {
                recordDate = date
            }
        case .monthly: // 月记
            recordTypeString = "月记"
            // 获取所选月的第一天
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = currentYear
            components.month = currentMonth
            components.day = 1
            if let date = calendar.date(from: components) {
                recordDate = date
            }
        case .quarterly: // 季记
            recordTypeString = "季记"
            // 获取所选季度的第一天
            let calendar = Calendar.current
            let month = (currentQuarter - 1) * 3 + 1
            var components = DateComponents()
            components.year = currentYear
            components.month = month
            components.day = 1
            if let date = calendar.date(from: components) {
                recordDate = date
            }
        case .yearly: // 年记
            recordTypeString = "年记"
            // 获取所选年的第一天
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = currentYear
            components.month = 1
            components.day = 1
            if let date = calendar.date(from: components) {
                recordDate = date
            }
        default:
            break
        }
        
        // 创建新记录
        let newRecord = Record(
            title: recordTitle,
            content: recordContent,
            recordType: selectedRecordType,
            year: currentYear,
            month: selectedRecordType == .daily || selectedRecordType == .monthly ? currentMonth : nil,
            day: selectedRecordType == .daily ? Calendar.current.component(.day, from: currentDate) : nil,
            week: selectedRecordType == .weekly ? currentWeek : nil,
            quarter: selectedRecordType == .quarterly ? currentQuarter : nil,
            mood: selectedRecordType == .daily ? selectedMood : nil,
            weather: nil // 不再保存天气信息
        )
        
        // 保存到数据库
        modelContext.insert(newRecord)
        
        // 不再清空输入，保留当前内容
        // 只清空心情选择（如果是日记）
        if selectedRecordType == .daily {
            selectedMood = nil
        }
        
        // 显示保存成功提示
        withAnimation {
            showSaveSuccessToast = true
        }
        
        // 更新当前记录
        currentRecord = newRecord
    }
    
    // 加载当前选择日期的记录
    private func loadCurrentRecord() {
        // 根据记录类型和日期查找记录
        var filteredRecords: [Record] = []
        
        switch selectedRecordType {
        case .daily: // 日记
            // 查找当前日期的日记
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let day = calendar.component(.day, from: currentDate)
            
            filteredRecords = allRecords.filter { record in
                record.recordType == .daily &&
                record.year == year &&
                record.month == month &&
                record.day == day
            }
            
        case .weekly: // 周记
            // 查找当前年份和周数的周记
            filteredRecords = allRecords.filter { record in
                record.recordType == .weekly &&
                record.year == currentYear &&
                record.week == currentWeek
            }
            
        case .monthly: // 月记
            // 查找当前年份和月份的月记
            filteredRecords = allRecords.filter { record in
                record.recordType == .monthly &&
                record.year == currentYear &&
                record.month == currentMonth
            }
            
        case .quarterly: // 季记
            // 查找当前年份和季度的季记
            filteredRecords = allRecords.filter { record in
                record.recordType == .quarterly &&
                record.year == currentYear &&
                record.quarter == currentQuarter
            }
            
        case .yearly: // 年记
            // 查找当前年份的年记
            filteredRecords = allRecords.filter { record in
                record.recordType == .yearly &&
                record.year == currentYear
            }
        }
        
        // 如果找到记录，则显示最新的一条
        if let latestRecord = filteredRecords.first {
            currentRecord = latestRecord
            recordContent = latestRecord.content
            selectedMood = latestRecord.mood
        } else {
            // 如果没有找到记录，则清空内容
            currentRecord = nil
            recordContent = ""
            selectedMood = nil
        }
    }
}

// 预览
struct RecordView_Previews: PreviewProvider {
    static var previews: some View {
        RecordView(selectedTab: .constant(2))
    }
}

// 使用项目中已有的 ScaleButtonStyle
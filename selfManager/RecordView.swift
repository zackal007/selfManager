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
    
    // 当前日
    @State private var currentDay = Calendar.current.component(.day, from: Date())
    
    // 当前季度
    @State private var currentQuarter = (Calendar.current.component(.month, from: Date()) - 1) / 3 + 1
    
    // 当前周
    @State private var currentWeek = Calendar.current.component(.weekOfYear, from: Date())
    
    // 控制日期选择器显示
    @State private var showDatePicker = false
    
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
    
    // 日期格式化器 - 用于显示年月
    private let yearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter
    }()
    
    // 初始化方法，接收selectedTab绑定
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    // 日历日期结构体
    struct CalendarDay: Identifiable {
        let id = UUID()
        let date: Date?
        let dayNumber: String
        let isSelected: Bool
        let isToday: Bool
        let isCurrentMonth: Bool
    }
    
    // 生成当前月份的日期数组
    private func daysInMonth(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        
        // 获取当前月的第一天
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = 1
        guard let firstDayOfMonth = calendar.date(from: components) else { return [] }
        
        // 获取当前月第一天是星期几（1是星期日，2是星期一...）
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // 获取上个月的最后几天（用于填充当前月第一周的前几天）
        var daysInPreviousMonth = [CalendarDay]()
        if firstWeekday > 1 {
            guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth) else { return [] }
            let daysInMonth = calendar.range(of: .day, in: .month, for: previousMonth)?.count ?? 30
            let startDay = daysInMonth - firstWeekday + 2
            
            for i in startDay...daysInMonth {
                var dateComponents = calendar.dateComponents([.year, .month], from: previousMonth)
                dateComponents.day = i
                let dayDate = calendar.date(from: dateComponents)
                
                // 检查是否在当前选中日期的同一周内（针对周记）
                let isInSelectedWeek = selectedRecordType == .weekly && dayDate != nil && 
                    calendar.isDate(dayDate!, equalTo: currentDate, toGranularity: .weekOfYear)
                
                daysInPreviousMonth.append(CalendarDay(
                    date: dayDate,
                    dayNumber: "\(i)",
                    isSelected: isInSelectedWeek,
                    isToday: false,
                    isCurrentMonth: false
                ))
            }
        }
        
        // 获取当前月的天数
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30
        
        // 当前选中的日期
        let selectedDateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
        
        // 今天的日期
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        
        // 添加当月的天数
        var days = [CalendarDay]()
        for day in 1...daysInMonth {
            var dateComponents = components
            dateComponents.day = day
            let dayDate = calendar.date(from: dateComponents)
            
            let isToday = components.year == todayComponents.year &&
                          components.month == todayComponents.month &&
                          day == todayComponents.day
            
            // 根据记录类型决定选中逻辑
            var isSelected = false
            if selectedRecordType == .weekly && dayDate != nil {
                // 周记：如果日期在当前选中日期的同一周内，则标记为选中
                isSelected = calendar.isDate(dayDate!, equalTo: currentDate, toGranularity: .weekOfYear)
            } else {
                // 其他记录类型：只有当天被选中
                isSelected = components.year == selectedDateComponents.year &&
                             components.month == selectedDateComponents.month &&
                             day == selectedDateComponents.day
            }
            
            days.append(CalendarDay(
                date: dayDate,
                dayNumber: "\(day)",
                isSelected: isSelected,
                isToday: isToday,
                isCurrentMonth: true
            ))
        }
        
        // 计算需要显示的下个月的天数（填充最后一行）
        let totalDaysShown = daysInPreviousMonth.count + days.count
        let remainingDays = 42 - totalDaysShown // 6行7列 = 42个日期单元格
        
        // 添加下个月的天数
        if remainingDays > 0 {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth) else { return [] }
            
            for day in 1...remainingDays {
                var dateComponents = calendar.dateComponents([.year, .month], from: nextMonth)
                dateComponents.day = day
                let dayDate = calendar.date(from: dateComponents)
                
                // 检查是否在当前选中日期的同一周内（针对周记）
                let isInSelectedWeek = selectedRecordType == .weekly && dayDate != nil && 
                    calendar.isDate(dayDate!, equalTo: currentDate, toGranularity: .weekOfYear)
                
                days.append(CalendarDay(
                    date: dayDate,
                    dayNumber: "\(day)",
                    isSelected: isInSelectedWeek,
                    isToday: false,
                    isCurrentMonth: false
                ))
            }
        }
        
        return daysInPreviousMonth + days
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
                
                // 日期选择器 - 只在下拉时显示
                if showDatePicker {
                    VStack {
                        // 根据选择的记录类型显示不同的日期选择器
                        switch selectedRecordType {
                    // 日记
                    case .daily: // 日记
                        VStack(spacing: 8) {
                            // 年月选择器
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                
                                Spacer()
                                
                                Text(yearMonthFormatter.string(from: currentDate))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal, 8)
                            
                            // 星期标题行
                            HStack(spacing: 0) {
                                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { weekday in
                                    Text(weekday)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 8)
                            
                            // 日历网格
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                                ForEach(daysInMonth(for: currentDate), id: \ .id) { day in
                                    Button(action: {
                                        if day.date != nil {
                                            withAnimation {
                                                currentDate = day.date!
                                                updateDateComponents()
                                                loadCurrentRecord()
                                            }
                                        }
                                    }) {
                                        Text(day.dayNumber)
                                            .font(.system(size: 16, weight: day.isSelected ? .bold : .regular))
                                            .foregroundColor(day.isSelected ? .white : (day.isToday ? Color.purple : (day.isCurrentMonth ? .primary : .secondary)))
                                            .frame(width: 36, height: 36)
                                            .background(
                                                ZStack {
                                                    if day.isSelected {
                                                        Circle()
                                                            .fill(Color.purple)
                                                    } else if day.isToday {
                                                        Circle()
                                                            .stroke(Color.purple, lineWidth: 2)
                                                    }
                                                }
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(day.date == nil)
                                }
                            }
                            .padding(.horizontal, 8)
                            
                            // 移除当前选中日期显示
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                    case .weekly: // 周记
                        VStack(spacing: 8) {
                            // 年月选择器
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                
                                Spacer()
                                
                                Text(yearMonthFormatter.string(from: currentDate))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal, 8)
                            
                            // 星期标题行
                            HStack(spacing: 0) {
                                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { weekday in
                                    Text(weekday)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.horizontal, 8)
                            
                            // 周选择器 - 使用日历网格样式
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                                ForEach(daysInMonth(for: currentDate), id: \ .id) { day in
                                    Button(action: {
                                        if day.date != nil {
                                            withAnimation {
                                                currentDate = day.date!
                                                updateDateComponents()
                                                loadCurrentRecord()
                                            }
                                        }
                                    }) {
                                        Text(day.dayNumber)
                                            .font(.system(size: 16, weight: day.isSelected ? .bold : .regular))
                                            .foregroundColor(day.isSelected ? .white : (day.isToday ? Color.purple : (day.isCurrentMonth ? .primary : .secondary)))
                                            .frame(width: 36, height: 36)
                                            .background(
                                                ZStack {
                                                    if day.isSelected {
                                                        Circle()
                                                            .fill(Color.purple)
                                                    } else if day.isToday {
                                                        Circle()
                                                            .stroke(Color.purple, lineWidth: 2)
                                                    }
                                                }
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(day.date == nil)
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                    case .monthly: // 月记
                        VStack(spacing: 8) {
                            // 年份选择器
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .year, value: -1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                Spacer()
                                Text("\(Calendar.current.component(.year, from: currentDate))年")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .year, value: 1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal, 8)
                            // 月份网格
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 24) {
                                ForEach(1...12, id: \ .self) { month in
                                    Button(action: {
                                        let calendar = Calendar.current
                                        var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
                                        components.month = month
                                        components.day = 1
                                        if let newDate = calendar.date(from: components) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }) {
                                        ZStack {
                                            if Calendar.current.component(.month, from: currentDate) == month {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.purple)
                                                    .frame(height: 56)
                                            }
                                            Text("\(month)月")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(Calendar.current.component(.month, from: currentDate) == month ? .white : .primary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                    case .quarterly: // 季记
                        VStack(spacing: 16) {
                            // 年份选择器
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .year, value: -1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                Spacer()
                                let year = Calendar.current.component(.year, from: currentDate)
                                Text("\(year)年")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .year, value: 1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal, 8)
                            // 季度选择器
                            HStack(spacing: 32) {
                                ForEach(1...4, id: \ .self) { q in
                                    Button(action: {
                                        let calendar = Calendar.current
                                        let year = calendar.component(.year, from: currentDate)
                                        let month = (q - 1) * 3 + 1
                                        var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
                                        components.year = year
                                        components.month = month
                                        components.day = 1
                                        if let newDate = calendar.date(from: components) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(getCurrentQuarter(currentDate) == q ? Color.purple : Color.clear)
                                                .frame(width: 80, height: 48)
                                            Text("Q\(q)")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(getCurrentQuarter(currentDate) == q ? .white : .primary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.top, 16)
                        }
                        .padding(.vertical, 16)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                    case .yearly: // 年记
                        VStack(spacing: 8) {
                            // 年份选择器
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .year, value: -5, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.left.2")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .year, value: -1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                
                                Spacer()
                                
                                let year = Calendar.current.component(.year, from: currentDate)
                                Text("\(year)年")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .year, value: 1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        if let newDate = Calendar.current.date(byAdding: .year, value: 5, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.right.2")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal, 8)
                            
                            // 年份快速选择器 - 使用网格布局
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                                let currentYear = Calendar.current.component(.year, from: currentDate)
                                ForEach(-10...10, id: \.self) { offset in
                                    let year = currentYear + offset
                                    Button(action: {
                                        withAnimation {
                                            var components = Calendar.current.dateComponents([.month, .day], from: currentDate)
                                            components.year = year
                                            if let newDate = Calendar.current.date(from: components) {
                                                currentDate = newDate
                                                updateDateComponents()
                                                loadCurrentRecord()
                                            }
                                        }
                                    }) {
                                        Text("\(year)")
                                            .font(.system(size: 16))
                                            .fontWeight(currentYear == year ? .bold : .regular)
                                            .foregroundColor(currentYear == year ? .white : .primary)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(currentYear == year ? Color.purple : Color.clear)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(currentYear == year ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                    default:
                        EmptyView()
                    }
                    }
                    .padding(.bottom, 8)
                }
                
                // 记录内容区域
                ScrollView {
                    // 下拉区域 - 用于显示/隐藏日期选择器
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text(recordTitle)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .onTapGesture {
                            withAnimation {
                                showDatePicker.toggle()
                            }
                        }
                        
                        Spacer()
                    }
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    VStack(alignment: .leading, spacing: 16) {
                        // 显示记录内容
                        VStack(alignment: .leading, spacing: 12) {
                            // 移除记录标题
                            
                            TextEditor(text: $recordContent)
                                .frame(minHeight: UIScreen.main.bounds.height * 0.5) // 使用屏幕高度的50%作为最小高度
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
    
    // 注意：yearMonthFormatter 已在文件顶部声明
    
    // 更新日期组件
    private func updateDateComponents() {
        let calendar = Calendar.current
        currentYear = calendar.component(.year, from: currentDate)
        currentMonth = calendar.component(.month, from: currentDate)
        currentDay = calendar.component(.day, from: currentDate)
        currentWeek = calendar.component(.weekOfYear, from: currentDate)
        currentQuarter = (calendar.component(.month, from: currentDate) - 1) / 3 + 1
    }
    
    // 记录标题
    var recordTitle: String {
        switch selectedRecordType {
        case .daily:
            return "\(formattedDate) 日记"
        case .weekly:
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            let week = calendar.component(.weekOfYear, from: currentDate)
            return "\(year)年第\(week)周 周记"
        case .monthly:
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            return "\(year)年\(month)月 月记"
        case .quarterly:
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let quarter = (month - 1) / 3 + 1
            return "\(year)年第\(quarter)季度 季记"
        case .yearly:
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            return "\(year)年 年记"
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
            // 使用当前选择的日期，但获取该日期所在周的第一天（周日）
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: currentDate)
            // 计算到本周第一天（周日）的偏移量
            let daysToSubtract = weekday - 1
            if let weekStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: currentDate) {
                recordDate = weekStartDate
            }
        case .monthly: // 月记
            recordTypeString = "月记"
            // 使用当前选择的日期，但获取该日期所在月的第一天
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            if let date = calendar.date(from: components) {
                recordDate = date
            }
        case .quarterly: // 季记
            recordTypeString = "季记"
            // 获取当前日期所在季度的第一天
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let quarter = (month - 1) / 3 + 1
            let firstMonthOfQuarter = (quarter - 1) * 3 + 1
            
            var components = DateComponents()
            components.year = year
            components.month = firstMonthOfQuarter
            components.day = 1
            if let date = calendar.date(from: components) {
                recordDate = date
            }
        case .yearly: // 年记
            recordTypeString = "年记"
            // 获取当前日期所在年份的第一天
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            var components = DateComponents()
            components.year = year
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
            // 查找当前日期所在周的周记
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            let week = calendar.component(.weekOfYear, from: currentDate)
            
            filteredRecords = allRecords.filter { record in
                record.recordType == .weekly &&
                record.year == year &&
                record.week == week
            }
            
        case .monthly: // 月记
            // 查找当前日期所在月的月记
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            
            filteredRecords = allRecords.filter { record in
                record.recordType == .monthly &&
                record.year == year &&
                record.month == month
            }
            
        case .quarterly: // 季记
            // 查找当前日期所在季度的季记
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let quarter = (month - 1) / 3 + 1
            
            filteredRecords = allRecords.filter { record in
                record.recordType == .quarterly &&
                record.year == year &&
                record.quarter == quarter
            }
            
        case .yearly: // 年记
            // 查找当前日期所在年份的年记
            let calendar = Calendar.current
            let year = calendar.component(.year, from: currentDate)
            
            filteredRecords = allRecords.filter { record in
                record.recordType == .yearly &&
                record.year == year
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
// 工具函数：获取当前日期所在季度
    private func getCurrentQuarter(_ date: Date) -> Int {
        let month = Calendar.current.component(.month, from: date)
        return (month - 1) / 3 + 1
    }
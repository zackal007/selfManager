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
    
    // 查询所有目标和联系人（用于链接导航）
    @Query private var allGoals: [Goal]
    @Query private var allContacts: [Contact]
    
    // 当前显示的记录
    @State private var currentRecord: Record?
    
    // 绑定到TabView的选中标签
    @Binding var selectedTab: Int
    
    // 导航管理器
    @StateObject private var navigationManager = NavigationManager.shared
    
    // 清理重复记录的标志
    @State private var hasCleanedDuplicates = false
    
    // 侧边栏状态
    @State private var showSidebar = false
    
    // 记录类型选择器
    @State private var selectedRecordType: RecordType = .recent
    
    // 记录类型数组和当前索引（用于TabView滑动）
    private let recordTypes: [RecordType] = [.recent, .daily, .weekly, .monthly, .quarterly, .yearly]
    @State private var currentRecordTypeIndex: Int = 0
    
    // 添加键盘失焦状态管理
    @FocusState private var isAnyFieldFocused: Bool
    
    // 同步记录类型索引
    private func syncRecordTypeIndex() {
        if let index = recordTypes.firstIndex(of: selectedRecordType) {
            currentRecordTypeIndex = index
        }
    }
    
    // 获取记录类型对应的标题
    private func getRecordTitle(for recordType: RecordType) -> String {
        let calendar = self.calendar
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        let day = calendar.component(.day, from: currentDate)
        let week = calendar.component(.weekOfYear, from: currentDate)
        let quarter = (month - 1) / 3 + 1
        
        switch recordType {
        case .recent:
            return "近期"
        case .daily:
            return "\(year)年\(month)月\(day)日"
        case .weekly:
            return "\(year)年第\(week)周"
        case .monthly:
            return "\(year)年\(month)月"
        case .quarterly:
            return "\(year)年第\(quarter)季度"
        case .yearly:
            return "\(year)年"
        }
    }
    
    // 当前日期
    @State private var currentDate = Date()
    
    // 当前年份
    @State private var currentYear: Int = 0
    
    // 当前月份
    @State private var currentMonth: Int = 0
    
    // 当前日
    @State private var currentDay: Int = 0
    
    // 当前季度
    @State private var currentQuarter: Int = 0
    
    // 当前周
    @State private var currentWeek: Int = 0
    
    // 年份列表的基准年份（用于控制年份选择器显示的年份范围）
    @State private var yearListBaseYear: Int = 0
    
    // 初始化日期组件
    private func initDateComponents() {
        let cal = self.calendar
        currentYear = cal.component(.year, from: currentDate)
        currentMonth = cal.component(.month, from: currentDate)
        currentDay = cal.component(.day, from: currentDate)
        currentQuarter = (cal.component(.month, from: currentDate) - 1) / 3 + 1
        currentWeek = cal.component(.weekOfYear, from: currentDate)
        // 设置年份列表的基准年份，使当前年份位于年份列表的中间位置（第2行中间）
        yearListBaseYear = max(1, currentYear - 7) // 确保年份不小于1
    }
    
    // 控制日期选择器显示
    @State private var showDatePicker = false
    
    // 年份变化动画
    @State private var dateChangeAnimation = false
    @State private var dateChangeDirection = ""
    @State private var showDateChangeToast = false
    
    // 记录内容
    @State private var recordContent = ""
    @State private var selectedImages: [Data] = []
    @State private var selectedMood: String? = nil
    @State private var selectedWeather: String? = nil
    
    // 用于跟踪内容是否已修改
    @State private var contentModified = false
    
    // 显示保存成功提示
    @State private var showSaveSuccessToast = false
    
    // 导航相关状态
    @State private var selectedGoalId: UUID? = nil
    @State private var selectedContactId: UUID? = nil
    @State private var selectedRecordId: UUID? = nil
    @State private var showGoalDetail = false
    @State private var showContactDetail = false
    @State private var showRecordDetail = false
    
    // 近期页签相关状态
    @State private var displayedRecordsCount = 20 // 初始显示的记录数量
    private let recordsPerPage = 20 // 每次加载的记录数量
    
    // 过滤后的非空记录（按创建时间降序排列）
    private var filteredRecords: [Record] {
        // 只显示特定类型的记录：日记、周记、月记、季记、年记
        let allowedTypes: Set<RecordType> = [.daily, .weekly, .monthly, .quarterly, .yearly]
        
        let filtered = allRecords.filter { record in
            // 过滤空内容和不允许的记录类型
            !record.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            allowedTypes.contains(record.recordType)
        }
        
        // 按记录类型和时间进行去重，每种类型的每个时间段只保留最新的一条记录
        var uniqueRecords: [String: Record] = [:]
        
        for record in filtered {
            let key = generateUniqueKey(for: record)
            
            // 如果该key不存在，或者当前记录更新，则保留当前记录
            if let existingRecord = uniqueRecords[key] {
                if record.createTime > existingRecord.createTime {
                    uniqueRecords[key] = record
                }
            } else {
                uniqueRecords[key] = record
            }
        }
        
        return Array(uniqueRecords.values).sorted { $0.createTime > $1.createTime }
    }
    
    // 清理重复记录
    private func cleanDuplicateRecords() {
        let allowedTypes: Set<RecordType> = [.daily, .weekly, .monthly, .quarterly, .yearly]
        
        // 获取所有有效记录
        let validRecords = allRecords.filter { record in
            !record.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            allowedTypes.contains(record.recordType)
        }
        
        // 按唯一key分组
        var uniqueRecords: [String: Record] = [:]
        var recordsToDelete: [Record] = []
        
        for record in validRecords {
            let key = generateUniqueKey(for: record)
            
            if let existingRecord = uniqueRecords[key] {
                // 如果已存在相同key的记录，保留创建时间较新的
                if record.createTime > existingRecord.createTime {
                    recordsToDelete.append(existingRecord)
                    uniqueRecords[key] = record
                } else {
                    recordsToDelete.append(record)
                }
            } else {
                uniqueRecords[key] = record
            }
        }
        
        // 删除重复记录
        for record in recordsToDelete {
            modelContext.delete(record)
        }
        
        // 保存更改
        if !recordsToDelete.isEmpty {
            do {
                try modelContext.save()
                print("已清理 \(recordsToDelete.count) 条重复记录")
            } catch {
                print("清理重复记录失败: \(error)")
            }
        }
    }
    
    // 生成记录的唯一标识key
    private func generateUniqueKey(for record: Record) -> String {
        switch record.recordType {
        case .daily:
            // 日记必须有年月日信息才能去重
            guard let month = record.month, let day = record.day else {
                return "daily_invalid_\(record.id.uuidString)"
            }
            return "daily_\(record.year)_\(month)_\(day)"
        case .weekly:
            // 周记必须有年和周信息才能去重
            guard let week = record.week else {
                return "weekly_invalid_\(record.id.uuidString)"
            }
            return "weekly_\(record.year)_\(week)"
        case .monthly:
            // 月记必须有年月信息才能去重
            guard let month = record.month else {
                return "monthly_invalid_\(record.id.uuidString)"
            }
            return "monthly_\(record.year)_\(month)"
        case .quarterly:
            // 季记必须有年和季度信息才能去重
            guard let quarter = record.quarter else {
                return "quarterly_invalid_\(record.id.uuidString)"
            }
            return "quarterly_\(record.year)_\(quarter)"
        case .yearly:
            return "yearly_\(record.year)"
        default:
            return "other_\(record.id.uuidString)"
        }
    }
    
    // 当前显示的记录（支持分页）
    private var displayedRecords: [Record] {
        Array(filteredRecords.prefix(displayedRecordsCount))
    }
    
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
    
    // 自定义日历配置，设置每周从周日开始
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // 1表示周日，2表示周一
        return calendar
    }
    
    // 生成当前月份的日期数组
    private func daysInMonth(for date: Date) -> [CalendarDay] {
        let calendar = self.calendar
        
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
                let isInSameWeek = dayDate != nil ? calendar.isDate(dayDate!, equalTo: currentDate, toGranularity: .weekOfYear) : false
                let isInSelectedWeek = selectedRecordType == .weekly && isInSameWeek
                
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
                let isInSameWeek = dayDate != nil ? calendar.isDate(dayDate!, equalTo: currentDate, toGranularity: .weekOfYear) : false
                let isInSelectedWeek = selectedRecordType == .weekly && isInSameWeek
                
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
        // 页面导航容器（记录页的 NavigationStack）
        NavigationStack(path: navigationManager.getNavigationPath(for: 2)) {
            // 顶层布局容器（承载顶部栏、日期选择器与内容区域）
            VStack(spacing: 0) {
                // 悬浮的顶部标题栏（整合记录类型筛选器）
                VStack(spacing: 0) {
                    // 第一行：标题和按钮
                    HStack(alignment: .center) {
                        // 侧边栏按钮
                        Button(action: {
                            dismissKeyboard()
                            showSidebar = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(UIColor.systemGray5).opacity(0.8))
                                    .frame(width: 38, height: 38)
                                
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(UIColor.label))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("  记录")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(Color(UIColor.label))
                        }
                        
                        Spacer()
                        
                        // 菜单按钮
                        MenuButton {
                            // 视图模式菜单内容
                            Button(action: {
                                dismissKeyboard()
                                // 日期选择器显示/隐藏
                                withAnimation {
                                    showDatePicker.toggle()
                                }
                            }) {
                                Label(showDatePicker ? "隐藏日期选择器" : "显示日期选择器", systemImage: showDatePicker ? "calendar.badge.minus" : "calendar.badge.plus")
                            }
                            
                            Divider()
                            
                            // 跳转到今天
                            Button(action: {
                                dismissKeyboard()
                                // 如果内容已修改，先保存当前记录
                                if contentModified {
                                    autoSaveRecord(recordType: selectedRecordType)
                                }
                                // 重置为当前日期
                                currentDate = Date()
                                updateDateComponents()
                                loadCurrentRecord()
                                // 重置修改状态
                                contentModified = false
                            }) {
                                Label("跳转到今天", systemImage: "arrow.uturn.backward.circle")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .padding(.top, 44) // 使用固定值代替弃用的API
                    
                    // 第二行：记录类型筛选器（页签选择器）
                    VStack(alignment: .leading, spacing: 8) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                // 自定义页签顺序：近期、日记、周记、月记、季记、年记
                                let orderedTypes: [RecordType] = [.recent, .daily, .weekly, .monthly, .quarterly, .yearly]
                                ForEach(orderedTypes, id: \.self) { type in
                                    FilterChip(title: type.displayName, isSelected: selectedRecordType == type) {
                                        dismissKeyboard()
                                        // 如果内容已修改，先保存当前记录
                                        if contentModified {
                                            autoSaveRecord(recordType: selectedRecordType)
                                        }
                                        selectedRecordType = type
                                        syncRecordTypeIndex()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
                .background(BlurView(style: .systemMaterial))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 3)
                .ignoresSafeArea(.all, edges: .top)
                .onChange(of: selectedRecordType) { oldValue, newValue in
                    // 切换记录类型时收起键盘
                    dismissKeyboard()
                    
                    // 如果内容已修改，先保存当前记录
                    if contentModified {
                        autoSaveRecord(recordType: oldValue)
                    }
                    
                    // 如果切换到年记，重置为当前系统时间并设置年份列表的基准年份
                    if newValue == .yearly {
                        currentDate = Date() // 重置为当前系统时间
                        updateDateComponents() // 更新日期组件
                        yearListBaseYear = max(1, currentYear - 7) // 确保年份不小于1
                    }
                    
                    // 当记录类型变化时，加载对应的记录
                    loadCurrentRecord()
                    // 重置修改状态
                    contentModified = false
                }
                
                // 日期选择器 - 只在下拉时显示
                if showDatePicker {
                    VStack {
                        // 根据选择的记录类型显示不同的日期选择器
                        switch selectedRecordType {
                    case .recent: // 近期 - 不显示日期选择器
                        EmptyView()
                        
                    case .daily: // 日记
                        VStack(spacing: 8) {
                            // 年月选择器
                            HStack {
                                Button(action: {
                                        // 如果内容已修改，先保存当前记录
                                        if contentModified {
                                            autoSaveRecord(recordType: selectedRecordType)
                                        }
                                        if let newDate = self.calendar.date(byAdding: .month, value: -1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
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
                                        // 如果内容已修改，先保存当前记录
                                        if contentModified {
                                            autoSaveRecord(recordType: selectedRecordType)
                                        }
                                        if let newDate = self.calendar.date(byAdding: .month, value: 1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
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
                                ForEach(daysInMonth(for: currentDate), id: \.id) { day in
                                    Button(action: {
                                        if day.date != nil {
                                            // 强制保存当前记录（防止内容丢失）
                                            autoSaveRecord(recordType: selectedRecordType, forceCheck: true)
                                            
                                            currentDate = day.date!
                                            updateDateComponents()
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
                                        }
                                    }) {
                                        Text(day.dayNumber)
                                            .font(.system(size: 16))
                                            .fontWeight(day.isSelected ? .bold : .regular)
                                            .foregroundColor(day.isSelected ? .white : (day.isToday ? .blue : (day.isCurrentMonth ? .primary : .secondary)))
                                            .frame(height: 36)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                ZStack {
                                                    if day.isSelected {
                                                        Circle()
                                                            .fill(Color.blue)
                                                            .frame(width: 36, height: 36)
                                                    } else if day.isToday {
                                                        Circle()
                                                            .stroke(Color.blue, lineWidth: 2)
                                                            .frame(width: 36, height: 36)
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
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                    case .weekly: // 周记
                        VStack(spacing: 8) {
                            // 年月选择器
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        // 强制保存当前记录（防止内容丢失）
                                        autoSaveRecord(recordType: selectedRecordType, forceCheck: true)
                                        
                                        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
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
                                        // 强制保存当前记录（防止内容丢失）
                                        autoSaveRecord(recordType: selectedRecordType, forceCheck: true)
                                        
                                        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
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
                                ForEach(daysInMonth(for: currentDate), id: \.id) { day in
                                    Button(action: {
                                        if day.date != nil {
                                            withAnimation {
                                                // 强制保存当前记录（防止内容丢失）
                                                autoSaveRecord(recordType: selectedRecordType, forceCheck: true)
                                                
                                                currentDate = day.date!
                                                updateDateComponents()
                                                loadCurrentRecord()
                                                // 重置修改状态
                                                contentModified = false
                                            }
                                        }
                                    }) {
                                        Text(day.dayNumber)
                                            .font(.system(size: 16))
                                            .fontWeight(day.isSelected ? .bold : .regular)
                                            .foregroundColor(day.isSelected ? .white : (day.isToday ? .blue : (day.isCurrentMonth ? .primary : .secondary)))
                                            .frame(height: 36)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                ZStack {
                                                    if day.isSelected {
                                                        Circle()
                                                            .fill(Color.blue)
                                                            .frame(width: 36, height: 36)
                                                    } else if day.isToday {
                                                        Circle()
                                                            .stroke(Color.blue, lineWidth: 2)
                                                            .frame(width: 36, height: 36)
                                                    }
                                                }
                                            )
                                    .font(.system(size: 16, weight: day.isSelected ? .bold : .regular))
                                    .foregroundColor(day.isSelected ? .white : .primary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(day.date == nil)
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                    case .monthly: // 月记
                        VStack(spacing: 8) {
                            // 年份选择器
                            HStack {
                                Button(action: {
                                    // 如果内容已修改，先保存当前记录
                                    if contentModified {
                                        autoSaveRecord(recordType: selectedRecordType)
                                    }
                                    if let newDate = self.calendar.date(byAdding: .year, value: -1, to: currentDate) {
                                        currentDate = newDate
                                        updateDateComponents()
                                        loadCurrentRecord()
                                        // 重置修改状态
                                        contentModified = false
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                Spacer()
                                Text("\(self.calendar.component(.year, from: currentDate))年")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    // 如果内容已修改，先保存当前记录
                                    if contentModified {
                                        autoSaveRecord(recordType: selectedRecordType)
                                    }
                                    if let newDate = self.calendar.date(byAdding: .year, value: 1, to: currentDate) {
                                        currentDate = newDate
                                        updateDateComponents()
                                        loadCurrentRecord()
                                        // 重置修改状态
                                        contentModified = false
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
                                        var components = self.calendar.dateComponents([.year, .month, .day], from: currentDate)
                                        components.month = month
                                        components.day = 1
                                        if let newDate = self.calendar.date(from: components) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                        }
                                    }) {
                                        ZStack {
                                            if self.calendar.component(.month, from: currentDate) == month {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.blue)
                                                    .frame(height: 36)
                                            } else if self.calendar.component(.month, from: Date()) == month && 
                                                     self.calendar.component(.year, from: currentDate) == self.calendar.component(.year, from: Date()) {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.blue, lineWidth: 2)
                                                    .frame(height: 36)
                                            }
                                            Text("\(month)月")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(self.calendar.component(.month, from: currentDate) == month ? .white : .primary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                    case .quarterly: // 季记
                        VStack(spacing: 16) {
                            // 年份选择器
                            HStack {
                                Button(action: {
                                    // 如果内容已修改，先保存当前记录
                                    if contentModified {
                                        autoSaveRecord(recordType: selectedRecordType)
                                    }
                                    if let newDate = self.calendar.date(byAdding: .year, value: -1, to: currentDate) {
                                        currentDate = newDate
                                        updateDateComponents()
                                        loadCurrentRecord()
                                        // 重置修改状态
                                        contentModified = false
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                Spacer()
                                let year = self.calendar.component(.year, from: currentDate)
                                Text("\(year)年")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    // 如果内容已修改，先保存当前记录
                                    if contentModified {
                                        autoSaveRecord(recordType: selectedRecordType)
                                    }
                                    if let newDate = self.calendar.date(byAdding: .year, value: 1, to: currentDate) {
                                        currentDate = newDate
                                        updateDateComponents()
                                        loadCurrentRecord()
                                        // 重置修改状态
                                        contentModified = false
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal, 8)
                            // 季度选择器
                            HStack(spacing: 24) {
                                ForEach(1...4, id: \ .self) { q in
                                    Button(action: {
                                        // 如果内容已修改，先保存当前记录
                                        if contentModified {
                                            autoSaveRecord(recordType: selectedRecordType)
                                        }
                                        let year = self.calendar.component(.year, from: currentDate)
                                        let month = (q - 1) * 3 + 1
                                        var components = self.calendar.dateComponents([.year, .month, .day], from: currentDate)
                                        components.year = year
                                        components.month = month
                                        components.day = 1
                                        if let newDate = self.calendar.date(from: components) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
                                        }
                                    }) {
                                        ZStack {
                                            if getCurrentQuarter(currentDate) == q {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.blue)
                                                    .frame(width: 70, height: 36)
                                            } else if getCurrentQuarter(Date()) == q && 
                                                     self.calendar.component(.year, from: currentDate) == self.calendar.component(.year, from: Date()) {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.blue, lineWidth: 2)
                                                    .frame(width: 70, height: 36)
                                            }
                                            Text("Q\(q)")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(getCurrentQuarter(currentDate) == q ? .white : .primary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                    case .yearly: // 年记
                        VStack(spacing: 16) {
                            // 年份选择器
                            HStack {
                                Button(action: {
                                        // 如果内容已修改，先保存当前记录
                                        if contentModified {
                                            autoSaveRecord(recordType: selectedRecordType)
                                        }
                                        if let newDate = self.calendar.date(byAdding: .year, value: -5, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
                                            // 调整年份列表的基准年份
                                            yearListBaseYear = max(1, yearListBaseYear - 5) // 确保年份不小于1
                                        }
                                }) {
                                    Image(systemName: "chevron.left.2")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                
                                Button(action: {
                                        // 如果内容已修改，先保存当前记录
                                        if contentModified {
                                            autoSaveRecord(recordType: selectedRecordType)
                                        }
                                        if let newDate = self.calendar.date(byAdding: .year, value: -1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
                                            // 调整年份列表的基准年份
                                            yearListBaseYear = max(1, yearListBaseYear - 1) // 确保年份不小于1
                                        }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                
                                Spacer()
                                
                                let year = self.calendar.component(.year, from: currentDate)
                                Text("\(year)年")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                        // 如果内容已修改，先保存当前记录
                                        if contentModified {
                                            autoSaveRecord(recordType: selectedRecordType)
                                        }
                                        if let newDate = self.calendar.date(byAdding: .year, value: 1, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
                                            // 调整年份列表的基准年份
                                            yearListBaseYear += 1
                                        }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                                
                                Button(action: {
                                        // 如果内容已修改，先保存当前记录
                                        if contentModified {
                                            autoSaveRecord(recordType: selectedRecordType)
                                        }
                                        if let newDate = self.calendar.date(byAdding: .year, value: 5, to: currentDate) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
                                            // 调整年份列表的基准年份
                                            yearListBaseYear += 5
                                        }
                                }) {
                                    Image(systemName: "chevron.right.2")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal, 8)
                            
                            // 年份快速选择器 - 使用网格布局（3行，每行5个年份）
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 24), count: 5), spacing: 24) {
                                let currentYear = self.calendar.component(.year, from: currentDate)
                                // 使用基于 yearListBaseYear 的范围，显示3行年份（共15个）
                                ForEach(yearListBaseYear...(yearListBaseYear+14), id: \.self) { year in
                                    Button(action: {
                                            // 如果内容已修改，先保存当前记录
                                            if contentModified {
                                                autoSaveRecord(recordType: selectedRecordType)
                                            }
                                            var components = self.calendar.dateComponents([.month, .day], from: currentDate)
                                            components.year = year
                                            if let newDate = self.calendar.date(from: components) {
                                                currentDate = newDate
                                                updateDateComponents()
                                                loadCurrentRecord()
                                                // 重置修改状态
                                                contentModified = false
                                                // 注意：点击年份按钮时不改变 yearListBaseYear 的值
                                            }
                                    }) {
                                        ZStack {
                                            if currentYear == year {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.blue)
                                                    .frame(height: 36)
                                            } else if self.calendar.component(.year, from: Date()) == year && 
                                                     self.calendar.component(.year, from: Date()) != currentYear {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.blue, lineWidth: 2)
                                                    .frame(height: 36)
                                            }
                                            Text("\(year)")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(currentYear == year ? .white : .primary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                    default:
                        EmptyView()
                    }
                    }
                    .padding(.bottom, 8)
                }
                
                // 记录内容区域 - 使用TabView实现左右滑动
                TabView(selection: $currentRecordTypeIndex) {
                    ForEach(recordTypes.indices, id: \.self) { index in
                        ScrollView {
                            VStack(spacing: 0) {
                                // 下拉区域 - 用于显示/隐藏日期选择器
                                // 仅在非"近期"页签时显示标题区域
                                if recordTypes[index] != .recent {
                                    HStack {
                                        Spacer()
                                        
                                        VStack(spacing: 4) {
                                            Text(getRecordTitle(for: recordTypes[index]))
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
                                    .background(Color(UIColor.systemGroupedBackground))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                }
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    // 根据记录类型显示不同内容
                                    if recordTypes[index] == .recent {
                                        // 近期页签显示记录列表
                                        LazyVStack(spacing: 12) {
                                            ForEach(displayedRecords, id: \.id) { record in
                                                RecordCardView(record: record) {
                                                    // 点击记录卡片的处理逻辑
                                                    navigateToRecord(record)
                                                }
                                            }
                                            
                                            // 加载更多按钮
                                            if displayedRecordsCount < filteredRecords.count {
                                                Button(action: loadMoreRecords) {
                                                    HStack {
                                                        Text("加载更多")
                                                            .font(.body)
                                                            .foregroundColor(.blue)
                                                        Image(systemName: "chevron.down")
                                                            .font(.caption)
                                                            .foregroundColor(.blue)
                                                    }
                                                    .padding(.vertical, 12)
                                                    .frame(maxWidth: .infinity)
                                                    .background(Color(UIColor.secondarySystemBackground))
                                                    .cornerRadius(8)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                            
                                            // 如果没有记录，显示空状态
                                            if filteredRecords.isEmpty {
                                                VStack(spacing: 16) {
                                                    Image(systemName: "doc.text")
                                                        .font(.system(size: 48))
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text("暂无记录")
                                                        .font(.headline)
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text("开始写下你的第一篇记录吧")
                                                        .font(.body)
                                                        .foregroundColor(.secondary)
                                                        .multilineTextAlignment(.center)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 60)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .frame(minHeight: UIScreen.main.bounds.height * 0.5)
                                    } else {
                                        // 其他页签显示正常记录内容
                                        VStack(alignment: .leading, spacing: 12) {
                                            // 移除记录标题
                                            
                                            // 记录正文编辑器（富文本与图片），绑定到 recordContent
                                            NotesStyleRecordEditor(
                                                text: $recordContent,
                                                images: $selectedImages,
                                                minHeight: UIScreen.main.bounds.height * 0.6,
                                                onImagesChanged: { images in
                                                    selectedImages = images
                                                    contentModified = true
                                                },
                                                onTextChanged: {
                                                    contentModified = true
                                                }
                                            )
                                            .frame(maxHeight: .infinity)
                                            .padding(.horizontal)
                                            .onChange(of: recordContent) { _, _ in
                                                // 标记内容已修改
                                                contentModified = true
                                            }
                                            .onAppear {
                                                // 加载当前选择日期的记录
                                                loadCurrentRecord()
                                                // 重置修改状态
                                                contentModified = false
                                            }
                                        }
                                        
                                        // 心情选择（只在日记页签中显示）
                                        if recordTypes[index] == .daily {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("心情")
                                                    .font(.headline)
                                                    .padding(.horizontal)
                                                
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack(spacing: 16) {
                                                        ForEach(["😊", "😢", "😡", "😴", "🤔", "😎"], id: \.self) { mood in
                                                            Button(action: {
                                                                selectedMood = mood
                                                                // 标记内容已修改
                                                                contentModified = true
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
                                        
                                        // 自动保存已启用，不再需要保存按钮
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentRecordTypeIndex) { newIndex in
                    // 切换页签时收起键盘
                    dismissKeyboard()
                    
                    // 如果内容已修改，先保存当前记录
                    if contentModified {
                        autoSaveRecord(recordType: selectedRecordType)
                    }
                    // 同步更新selectedRecordType
                    selectedRecordType = recordTypes[newIndex]
                    // 加载对应的记录内容
                    loadCurrentRecord()
                    // 重置修改状态
                    contentModified = false
                }
                    
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
                        .background(Color(UIColor.label).opacity(0.2))
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
            .onTapGesture {
                dismissKeyboard()
            }
            // 隐式导航链接容器（跳转目标/联系人/记录详情）
            .background(
                Group {
                    // 目标详情页导航
                    NavigationLink(
                        destination: Group {
                            if let goalId = selectedGoalId,
                               let goal = allGoals.first(where: { $0.id == goalId }) {
                                GoalDetailView(goal: goal)
                            } else {
                                EmptyView()
                            }
                        },
                        isActive: $showGoalDetail
                    ) {
                        EmptyView()
                    }
                    
                    // 联系人详情页导航
                    NavigationLink(
                        destination: Group {
                            if let contactId = selectedContactId,
                               let contact = allContacts.first(where: { $0.id == contactId }) {
                                ContactDetailView(contact: contact)
                            } else {
                                EmptyView()
                            }
                        },
                        isActive: $showContactDetail
                    ) {
                        EmptyView()
                    }
                    
                    // 记录详情页导航（如果需要的话）
                    NavigationLink(
                        destination: Group {
                            if let recordId = selectedRecordId,
                               let record = allRecords.first(where: { $0.id == recordId }) {
                                // 这里可以创建一个记录详情视图，或者直接跳转到对应日期
                                RecordView(selectedTab: .constant(2))
                            } else {
                                EmptyView()
                            }
                        },
                        isActive: $showRecordDetail
                    ) {
                        EmptyView()
                    }
                }
            )
            .onAppear {
                // 同步记录类型索引
                syncRecordTypeIndex()
                // 视图首次加载时加载当前记录
                loadCurrentRecord()
                // 重置修改状态
                contentModified = false
                // 只在第一次加载时清理重复记录
                if !hasCleanedDuplicates {
                    cleanDuplicateRecords()
                    hasCleanedDuplicates = true
                }
            }
            .onDisappear {
                // 离开页面时自动保存记录
                if contentModified {
                    autoSaveRecord(recordType: selectedRecordType)
                }
            }
            .onChange(of: selectedTab) { _, newValue in
                // 切换标签页时自动保存记录
                if contentModified {
                    autoSaveRecord(recordType: selectedRecordType)
                    // 重置修改状态
                    contentModified = false
                }
            }
            // 侧边栏覆盖层（应用全局导航）
            .overlay(
                SidebarView(
                    isPresented: $showSidebar,
                    selectedTab: $selectedTab
                )
            )
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
        let calendar = self.calendar
        currentYear = calendar.component(.year, from: currentDate)
        currentMonth = calendar.component(.month, from: currentDate)
        currentDay = calendar.component(.day, from: currentDate)
        currentWeek = calendar.component(.weekOfYear, from: currentDate)
        currentQuarter = (calendar.component(.month, from: currentDate) - 1) / 3 + 1
    }
    
    // 工具函数：获取当前日期所在季度
    private func getCurrentQuarter(_ date: Date) -> Int {
        let month = self.calendar.component(.month, from: date)
        return (month - 1) / 3 + 1
    }
    
    // 记录标题
    var recordTitle: String {
        switch selectedRecordType {
        case .recent:
            return "近期"
        case .daily:
            return "\(formattedDate) 日记"
        case .weekly:
            let calendar = self.calendar
            let year = calendar.component(.year, from: currentDate)
            let week = calendar.component(.weekOfYear, from: currentDate)
            return "\(year)年第\(week)周 周记"
        case .monthly:
            let calendar = self.calendar
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            return "\(year)年\(month)月 月记"
        case .quarterly:
            let calendar = self.calendar
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let quarter = (month - 1) / 3 + 1
            return "\(year)年第\(quarter)季度 季记"
        case .yearly:
            let calendar = self.calendar
            let year = calendar.component(.year, from: currentDate)
            return "\(year)年 年记"
        }
    }
    
    // 保存记录方法
    private func saveRecord() {
        // 提取用户输入的内容（排除归拢内容）
        let userContent = extractUserContent(from: recordContent, recordType: selectedRecordType)
        
        // 检查内容是否为空
        guard !userContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // 检查是否已存在同一日期的记录，如果存在则更新，否则创建新记录
        if let existingRecord = findExistingRecord(for: selectedRecordType, date: currentDate) {
            // 更新现有记录
            existingRecord.title = recordTitle
            existingRecord.content = userContent
            existingRecord.createTime = Date() // 更新创建时间为当前时间
            existingRecord.images = selectedImages.isEmpty ? nil : selectedImages
            if selectedRecordType == .daily {
                existingRecord.mood = selectedMood
            }
            currentRecord = existingRecord
        } else {
            // 创建新记录
            createNewRecord(userContent: userContent)
        }
        
        // 不再清空输入，保留当前内容
        // 只清空心情选择（如果是日记）
        if selectedRecordType == .daily {
            selectedMood = nil
        }
        
        // 显示保存成功提示
        withAnimation {
            showSaveSuccessToast = true
        }
        
        // 重新加载记录，以显示归拢内容
        loadCurrentRecord()
    }
    
    // 查找已存在的同日期记录
    private func findExistingRecord(for recordType: RecordType, date: Date) -> Record? {
        let calendar = self.calendar
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        switch recordType {
        case .daily:
            return allRecords.first { record in
                record.recordType == .daily &&
                record.year == year &&
                record.month == month &&
                record.day == day
            }
        case .weekly:
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            return allRecords.first { record in
                record.recordType == .weekly &&
                record.year == year &&
                record.week == weekOfYear
            }
        case .monthly:
            return allRecords.first { record in
                record.recordType == .monthly &&
                record.year == year &&
                record.month == month
            }
        case .quarterly:
            let quarter = (month - 1) / 3 + 1
            return allRecords.first { record in
                record.recordType == .quarterly &&
                record.year == year &&
                record.quarter == quarter
            }
        case .yearly:
            return allRecords.first { record in
                record.recordType == .yearly &&
                record.year == year
            }
        default:
            return nil
        }
    }
    
    // 创建新记录的辅助方法
    private func createNewRecord(userContent: String) {
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
            let calendar = self.calendar
            let weekday = calendar.component(.weekday, from: currentDate)
            // 计算到本周第一天（周日）的偏移量
            let daysToSubtract = weekday - 1
            if let weekStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: currentDate) {
                recordDate = weekStartDate
            }
        case .monthly: // 月记
            recordTypeString = "月记"
            // 使用当前选择的日期，但获取该日期所在月的第一天
            let calendar = self.calendar
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
            let calendar = self.calendar
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
            let calendar = self.calendar
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
        let calendar = self.calendar
        let recordYear = calendar.component(.year, from: currentDate)
        let recordMonth = calendar.component(.month, from: currentDate)
        let recordWeek = calendar.component(.weekOfYear, from: currentDate)
        let recordQuarter = getCurrentQuarter(currentDate)
        
        let newRecord = Record(
            title: recordTitle,
            content: userContent, // 只保存用户输入的内容
            recordType: selectedRecordType,
            year: recordYear,
            month: selectedRecordType == .daily || selectedRecordType == .monthly ? recordMonth : nil,
            day: selectedRecordType == .daily ? calendar.component(.day, from: currentDate) : nil,
            week: selectedRecordType == .weekly ? recordWeek : nil,
            quarter: selectedRecordType == .quarterly ? recordQuarter : nil,
            mood: selectedRecordType == .daily ? selectedMood : nil,
            weather: nil, // 不再保存天气信息
            images: selectedImages.isEmpty ? nil : selectedImages
        )
        
        // 保存到数据库
        modelContext.insert(newRecord)
        
        // 更新当前记录
        currentRecord = newRecord
    }
    
    // 从记录内容中提取用户输入的部分（排除归拢内容）
    private func extractUserContent(from content: String, recordType: RecordType) -> String {
        // 如果是日记，直接返回全部内容
        if recordType == .daily {
            return content
        }
        
        // 对于其他类型的记录，查找归拢标记
        var userContent = content
        
        // 根据记录类型查找对应的归拢标记
        let markers = [
            "--- 本周日记归纳 ---",
            "--- 本月周记归纳 ---",
            "--- 本季度月记归纳 ---",
            "--- 本年季记归纳 ---"
        ]
        
        // 查找第一个出现的归拢标记
        for marker in markers {
            if let range = userContent.range(of: marker) {
                // 只保留标记之前的内容（用户输入的部分）
                userContent = String(userContent[..<range.lowerBound])
                break
            }
        }
        
        return userContent
    }
    
    // 自动保存记录，不显示保存成功提示
    private func autoSaveRecord(recordType: RecordType, forceCheck: Bool = false) {
        // 近期类型不执行任何保存操作
        guard recordType != .recent else {
            return
        }
        
        // 提取用户输入的内容（排除归拢内容）
        let userContent = extractUserContent(from: recordContent, recordType: recordType)
        
        // 如果是强制检查模式，即使内容为空也要检查是否需要保存（防止内容丢失）
        // 正常模式下，检查内容是否为空
        if !forceCheck {
            guard !userContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
        }
        
        // 检查是否已存在同一日期的记录，如果存在则更新，否则创建新记录
        if let existingRecord = findExistingRecord(for: recordType, date: currentDate) {
            // 更新现有记录
            existingRecord.title = recordTitle
            existingRecord.content = userContent
            existingRecord.createTime = Date() // 更新创建时间为当前时间
            existingRecord.images = selectedImages.isEmpty ? nil : selectedImages
            if recordType == .daily {
                existingRecord.mood = selectedMood
            }
            currentRecord = existingRecord
        } else {
            // 创建新记录
            createNewRecordForAutoSave(userContent: userContent, recordType: recordType)
        }
    }
    
    // 为自动保存创建新记录的辅助方法
    private func createNewRecordForAutoSave(userContent: String, recordType: RecordType) {
        // 创建新记录
        let calendar = self.calendar
        let recordYear = calendar.component(.year, from: currentDate)
        let recordMonth = calendar.component(.month, from: currentDate)
        let recordWeek = calendar.component(.weekOfYear, from: currentDate)
        let recordQuarter = getCurrentQuarter(currentDate)
        
        let newRecord = Record(
            title: recordTitle,
            content: userContent, // 只保存用户输入的内容
            recordType: recordType,
            year: recordYear,
            month: recordType == .daily || recordType == .monthly ? recordMonth : nil,
            day: recordType == .daily ? calendar.component(.day, from: currentDate) : nil,
            week: recordType == .weekly ? recordWeek : nil,
            quarter: recordType == .quarterly ? recordQuarter : nil,
            mood: recordType == .daily ? selectedMood : nil,
            weather: nil, // 不再保存天气信息
            images: selectedImages.isEmpty ? nil : selectedImages
        )
        
        // 保存到数据库
        modelContext.insert(newRecord)
        
        // 更新当前记录
        currentRecord = newRecord
    }
    
    // 获取下一级记录内容
    private func getLowerLevelRecordsContent(recordType: RecordType, year: Int, month: Int? = nil, week: Int? = nil, quarter: Int? = nil) -> String {
        var lowerLevelRecords: [Record] = []
        var contentBuilder = ""
        
        switch recordType {
        case .weekly: // 获取周记对应的日记
            guard let week = week else { return "" }
            
            // 获取该周的所有日记
            lowerLevelRecords = allRecords.filter { record in
                record.recordType == .daily &&
                record.year == year &&
                record.week == week
            }
            
            if !lowerLevelRecords.isEmpty {
                contentBuilder += "\n\n--- 本周日记归纳 ---\n"
                
                // 按日期排序
                let sortedRecords = lowerLevelRecords.sorted { record1, record2 in
                    guard let day1 = record1.day, let day2 = record2.day else { return false }
                    return day1 < day2
                }
                
                for record in sortedRecords {
                    if let day = record.day, let month = record.month {
                        contentBuilder += "\n【\(month)月\(day)日】\(record.title)\n"
                        contentBuilder += record.content
                        contentBuilder += "\n"
                    }
                }
            }
            
        case .monthly: // 获取月记对应的周记
            guard let month = month else { return "" }
            
            // 获取该月的所有周记
            lowerLevelRecords = allRecords.filter { record in
                record.recordType == .weekly &&
                record.year == year &&
                calendar.component(.month, from: calendar.date(from: DateComponents(year: year, weekday: 1, weekOfYear: record.week)) ?? Date()) == month
            }
            
            if !lowerLevelRecords.isEmpty {
                contentBuilder += "\n\n--- 本月周记归纳 ---\n"
                
                // 按周排序
                let sortedRecords = lowerLevelRecords.sorted { record1, record2 in
                    guard let week1 = record1.week, let week2 = record2.week else { return false }
                    return week1 < week2
                }
                
                for record in sortedRecords {
                    if let week = record.week {
                        contentBuilder += "\n【第\(week)周】\(record.title)\n"
                        contentBuilder += record.content
                        contentBuilder += "\n"
                    }
                }
            }
            
        case .quarterly: // 获取季记对应的月记
            guard let quarter = quarter else { return "" }
            
            // 计算季度对应的月份范围
            let startMonth = (quarter - 1) * 3 + 1
            let endMonth = startMonth + 2
            
            // 获取该季度的所有月记
            lowerLevelRecords = allRecords.filter { record in
                record.recordType == .monthly &&
                record.year == year &&
                record.month != nil &&
                record.month! >= startMonth &&
                record.month! <= endMonth
            }
            
            if !lowerLevelRecords.isEmpty {
                contentBuilder += "\n\n--- 本季度月记归纳 ---\n"
                
                // 按月份排序
                let sortedRecords = lowerLevelRecords.sorted { record1, record2 in
                    guard let month1 = record1.month, let month2 = record2.month else { return false }
                    return month1 < month2
                }
                
                for record in sortedRecords {
                    if let month = record.month {
                        contentBuilder += "\n【\(month)月】\(record.title)\n"
                        contentBuilder += record.content
                        contentBuilder += "\n"
                    }
                }
            }
            
        case .yearly: // 获取年记对应的季记
            // 获取该年的所有季记
            lowerLevelRecords = allRecords.filter { record in
                record.recordType == .quarterly &&
                record.year == year
            }
            
            if !lowerLevelRecords.isEmpty {
                contentBuilder += "\n\n--- 本年季记归纳 ---\n"
                
                // 按季度排序
                let sortedRecords = lowerLevelRecords.sorted { record1, record2 in
                    guard let quarter1 = record1.quarter, let quarter2 = record2.quarter else { return false }
                    return quarter1 < quarter2
                }
                
                for record in sortedRecords {
                    if let quarter = record.quarter {
                        contentBuilder += "\n【第\(quarter)季度】\(record.title)\n"
                        contentBuilder += record.content
                        contentBuilder += "\n"
                    }
                }
            }
            
        default:
            break
        }
        
        return contentBuilder
    }
    
    // 加载当前选择日期的记录
    private func loadCurrentRecord() {
        // 根据记录类型和日期查找记录
        var filteredRecords: [Record] = []
        let calendar = self.calendar
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        let day = calendar.component(.day, from: currentDate)
        let week = calendar.component(.weekOfYear, from: currentDate)
        let quarter = (month - 1) / 3 + 1
        
        switch selectedRecordType {
        case .recent: // 近期 - 不执行任何数据加载操作
            return
            
        case .daily: // 日记
            // 查找当前日期的日记
            filteredRecords = allRecords.filter { record in
                record.recordType == .daily &&
                record.year == year &&
                record.month == month &&
                record.day == day
            }
            
        case .weekly: // 周记
            // 查找当前日期所在周的周记
            filteredRecords = allRecords.filter { record in
                record.recordType == .weekly &&
                record.year == year &&
                record.week == week
            }
            
        case .monthly: // 月记
            // 查找当前日期所在月的月记
            filteredRecords = allRecords.filter { record in
                record.recordType == .monthly &&
                record.year == year &&
                record.month == month
            }
            
        case .quarterly: // 季记
            // 查找当前日期所在季度的季记
            filteredRecords = allRecords.filter { record in
                record.recordType == .quarterly &&
                record.year == year &&
                record.quarter == quarter
            }
            
        case .yearly: // 年记
            // 查找当前日期所在年份的年记
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
            selectedImages = latestRecord.images ?? []
            
            // 根据记录类型，添加下一级记录内容
            var lowerLevelContent = ""
            switch selectedRecordType {
            case .weekly:
                lowerLevelContent = getLowerLevelRecordsContent(recordType: .weekly, year: year, week: week)
            case .monthly:
                lowerLevelContent = getLowerLevelRecordsContent(recordType: .monthly, year: year, month: month)
            case .quarterly:
                lowerLevelContent = getLowerLevelRecordsContent(recordType: .quarterly, year: year, quarter: quarter)
            case .yearly:
                lowerLevelContent = getLowerLevelRecordsContent(recordType: .yearly, year: year)
            default:
                break
            }
            
            // 如果有下一级记录内容，添加到当前记录内容中
            if !lowerLevelContent.isEmpty {
                recordContent += lowerLevelContent
            }
        } else {
            // 如果没有找到记录，则清空内容，但仍然可以显示下一级记录内容
            currentRecord = nil
            recordContent = ""
            selectedMood = nil
            selectedImages = []
            
            // 根据记录类型，添加下一级记录内容作为参考
            var lowerLevelContent = ""
            switch selectedRecordType {
            case .weekly:
                lowerLevelContent = getLowerLevelRecordsContent(recordType: .weekly, year: year, week: week)
            case .monthly:
                lowerLevelContent = getLowerLevelRecordsContent(recordType: .monthly, year: year, month: month)
            case .quarterly:
                lowerLevelContent = getLowerLevelRecordsContent(recordType: .quarterly, year: year, quarter: quarter)
            case .yearly:
                lowerLevelContent = getLowerLevelRecordsContent(recordType: .yearly, year: year)
            default:
                break
            }
            
            // 如果有下一级记录内容，添加到当前记录内容中
            if !lowerLevelContent.isEmpty {
                recordContent = lowerLevelContent
            }
        }
    }
    
    // 加载更多记录
    private func loadMoreRecords() {
        displayedRecordsCount += recordsPerPage
    }
    
    // 导航到记录详情
    private func navigateToRecord(_ record: Record) {
        // 设置选中的记录类型和日期
        selectedRecordType = record.recordType
        currentYear = record.year
        currentMonth = record.month ?? 1
        currentDay = record.day ?? 1
        currentWeek = record.week ?? 1
        currentQuarter = record.quarter ?? 1
        
        // 根据记录的日期创建对应的Date对象
        var dateComponents = DateComponents()
        dateComponents.year = record.year
        dateComponents.month = record.month
        dateComponents.day = record.day
        
        if let date = calendar.date(from: dateComponents) {
            currentDate = date
        }
        
        // 同步页签索引，确保TabView内容更新
        syncRecordTypeIndex()
        
        // 加载对应的记录
        loadCurrentRecord()
    }
    
    // MARK: - 键盘管理
    private func dismissKeyboard() {
        DispatchQueue.main.async {
            isAnyFieldFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
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
    @Query private var allUsers: [User]
    
    // 当前显示的记录
    @State private var currentRecord: Record?
    
    // 绑定到TabView的选中标签
    @Binding var selectedTab: Int
    
    // 导航管理器
    @StateObject private var navigationManager = NavigationManager.shared
    
    // 清理重复记录的标志
    @State private var hasCleanedDuplicates = false
    
    // 防止清空后自动重新加载的标志
    @State private var isClearingRecord = false
    
    // 侧边栏使用全局管理：移除本地状态，统一为全局覆盖层
    
    // 记录类型选择器
    @State private var selectedRecordType: RecordType = .recent
    
    // 记录类型数组和当前索引（用于TabView滑动）
    private let recordTypes: [RecordType] = [.recent, .daily, .weekly, .monthly, .quarterly, .yearly]
    @State private var currentRecordTypeIndex: Int = 0
    
    // 添加键盘失焦状态管理
    @FocusState private var isAnyFieldFocused: Bool
    
    // 顶栏动态高度（用于同步透明占位的高度，防止内容被遮挡）
    @State private var headerHeight: CGFloat = 120
    // 抽取顶栏视图：迁移到安全区顶部叠加
    private var headerView: some View {
        VStack(spacing: 0) {
            // 第一行：标题和按钮
            HStack(alignment: .center) {
                // 替换标题为：日期选择器显示/隐藏按钮（仅非“近期”显示）
                if selectedRecordType != .recent {
                    HStack(spacing: 8) {
                        Button(action: {
                            dismissKeyboard()
                            // 添加触觉反馈
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            withAnimation {
                                showDatePicker.toggle()
                            }
                        }) {
                            HStack(spacing: 8) {
                                // 显示具体时间文本
                                Text(headerInlineDateText)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(UIColor.label))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                                
                                // 下拉箭头图标
                                Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color(UIColor.label))
                                    .rotationEffect(.degrees(showDatePicker ? 0 : 0))
                                    .animation(.easeInOut(duration: 0.2), value: showDatePicker)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(showDatePicker ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: showDatePicker)
                        .contextMenu {
                            if !headerFullDateText.isEmpty {
                                Button(action: {}) {
                                    Label(headerFullDateText, systemImage: "calendar")
                                }
                                .disabled(true)
                            }
                        }
                    }
                    .padding(.leading, 8)
                } else {
                    // 近期页签：显示静态标题“最近记录”
                    Text("最近记录")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.label))
                        .padding(.leading, 8)
                }
                
                Spacer()
                
                // 近期页签：显示排序按钮
                if selectedRecordType == .recent {
                    Button(action: {
                        dismissKeyboard()
                        sortRecordsByTime()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(UIColor.systemGray5).opacity(0.8))
                                .frame(width: 34, height: 34)
                            
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(UIColor.label))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 手动保存按钮 - 仅在非"近期"页签且内容已修改时显示
                if selectedRecordType != .recent {
                    if contentModified {
                        Button(action: {
                            dismissKeyboard()
                            // 添加触觉反馈
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // 执行手动保存
                            saveRecord()
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.blue)
                                .scaleEffect(1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: contentModified)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                
                // 菜单按钮（仅在非近期页签显示）
                if selectedRecordType != .recent {
                    MenuButton {
                        // 非近期页签：显示日期选择器相关按钮
                        // 跳转到今天/本周/本月/本季/本年
                        Button(action: {
                            dismissKeyboard()
                            // 禁用自动保存 - 改为手动保存
                            // 如果内容已修改，先保存当前记录
                            // if contentModified {
                            //     autoSaveRecord(recordType: selectedRecordType)
                            // }
                            // 重置为当前日期
                            currentDate = Date()
                            updateDateComponents()
                            loadCurrentRecord()
                            // 重置修改状态
                            contentModified = false
                        }) {
                            Label(
                                selectedRecordType == .daily ? "跳转到今天" :
                                selectedRecordType == .weekly ? "跳转到本周" :
                                selectedRecordType == .monthly ? "跳转到本月" :
                                selectedRecordType == .quarterly ? "跳转到本季" : "跳转到本年",
                                systemImage: "arrow.uturn.backward.circle"
                            )
                        }

                        // 仅在"日记"页签显示：汇总今日目标完成情况
                        if selectedRecordType == .daily {
                            Divider()
                            Button(action: {
                                dismissKeyboard()
                                GoalActivityManager.shared.syncDailyCompletionSummaryToDiary(for: currentDate, modelContext: modelContext)
                                // 重新加载当日记录以展示汇总内容
                                loadCurrentRecord()
                            }) {
                                Label("汇总今日目标完成情况", systemImage: "doc.on.doc")
                            }
                        }

                        // 根据当前记录类型，提供汇总按钮
                        if selectedRecordType == .weekly || selectedRecordType == .monthly || selectedRecordType == .quarterly || selectedRecordType == .yearly {
                            Divider()
                            Button(action: {
                                dismissKeyboard()
                                refreshAggregationForCurrentPeriod()
                            }) {
                                Label(
                                    selectedRecordType == .weekly ? "汇总本周" :
                                    selectedRecordType == .monthly ? "汇总本月" :
                                    selectedRecordType == .quarterly ? "汇总本季" : "汇总本年",
                                    systemImage: "text.append"
                                )
                            }
                        }
                        
                        // 根据当前记录类型，提供清空按钮
                        Divider()
                        Button(action: {
                            dismissKeyboard()
                            clearCurrentRecord()
                        }) {
                            Label(
                                selectedRecordType == .daily ? "清空日记" :
                                selectedRecordType == .weekly ? "清空周记" :
                                selectedRecordType == .monthly ? "清空月记" :
                                selectedRecordType == .quarterly ? "清空季记" : "清空年记",
                                systemImage: "trash"
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)

            // 第二行：记录类型筛选器（页签选择器）
            VStack(alignment: .leading, spacing: 6) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // 自定义页签顺序：近期、日记、周记、月记、季记、年记
                        let orderedTypes: [RecordType] = [.recent, .daily, .weekly, .monthly, .quarterly, .yearly]
                        ForEach(orderedTypes, id: \.self) { type in
                            TopTabChip(title: type.displayName, isSelected: selectedRecordType == type) {
                                dismissKeyboard()
                                // 禁用自动保存 - 改为手动保存
                                // 如果内容已修改，先保存当前记录
                                // if contentModified {
                                //     autoSaveRecord(recordType: selectedRecordType)
                                // }
                                selectedRecordType = type

                                // 如果切换到年记页签，确保默认展示今年
                                if type == .yearly {
                                    let currentYear = self.calendar.component(.year, from: Date())
                                    let selectedYear = self.calendar.component(.year, from: currentDate)

                                    // 如果当前选中的不是今年，则切换到今年
                                    if currentYear != selectedYear {
                                        var components = self.calendar.dateComponents([.month, .day], from: currentDate)
                                        components.year = currentYear
                                        if let newDate = self.calendar.date(from: components) {
                                            currentDate = newDate
                                            updateDateComponents()
                                            // 重新设置年份列表基准，确保当前年份在可见范围内
                                            yearListBaseYear = max(1, currentYear + 10)
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
                                        }
                                    } else {
                                        // 即使已经是今年，也确保年份列表基准正确
                                        yearListBaseYear = max(1, currentYear + 10)
                                    }
                                }

                                syncRecordTypeIndex()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 7)
        }
        .frame(maxWidth: .infinity)
        .safeAreaPadding(.top)
        .background(
            // 更通透的顶栏材质
            BlurView(style: .systemUltraThinMaterial)
                .ignoresSafeArea(.all, edges: .top)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 3)
        .zIndex(10)
        .overlay(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: HeaderHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(HeaderHeightPreferenceKey.self) { height in
            headerHeight = height
        }
    }

    // 顶栏页签按钮（仅用于本文件顶部页签）：选中加粗，未选中灰色
private struct TopTabChip: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? Color(UIColor.systemBlue) : Color(UIColor.secondaryLabel))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected
                              ? Color(UIColor.systemBlue).opacity(0.15)
                              : Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
    
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
        // 设置年份列表的基准年份，使当前年份位于年份列表的中间位置
        yearListBaseYear = max(1, currentYear + 10) // 确保年份不小于1，当前年份位于第11个位置
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
    @State private var isRecentSortAscending: Bool = false // 近期排序：默认按时间倒序
    
    // 过滤后的非空记录（近期页签使用，按创建时间升/降序排列）
    private var filteredRecords: [Record] {
        // 只显示特定类型的记录：日记、周记、月记、季记、年记
        let allowedTypes: Set<RecordType> = [.daily, .weekly, .monthly, .quarterly, .yearly]
        
        let filtered = allRecords.filter { record in
            // 过滤空内容和不允许的记录类型
            !record.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            allowedTypes.contains(record.recordType)
        }
        
        // 近期页签显示所有记录，不进行去重，让用户看到完整的历史记录
        // 根据 isRecentSortAscending 动态切换升/降序
        return filtered.sorted { lhs, rhs in
            if isRecentSortAscending {
                return lhs.createTime < rhs.createTime
            } else {
                return lhs.createTime > rhs.createTime
            }
        }
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
        NavigationStack(path: $navigationManager.recordNavigationPath) {
            // 顶层布局容器（承载顶部栏、日期选择器与内容区域）
            VStack(spacing: 0) {
                // 顶栏后的内容容器（插入透明占位，避免覆盖层挡住内容）
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: max(0, headerHeight - 30 + 8))

                    // 内部内容容器：移除背景与圆角，避免灰色块延伸至顶栏下方
                    VStack(spacing: 0) {
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
                                    // 禁用自动保存 - 改为手动保存
                                    // 如果内容已修改，先保存当前记录
                                    // if contentModified {
                                    //     autoSaveRecord(recordType: selectedRecordType)
                                    // }
                                    if let newDate = self.calendar.date(byAdding: .month, value: -1, to: currentDate) {
                                        currentDate = newDate
                                        adjustDateToRecordType(selectedRecordType)
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
                                        // 禁用自动保存 - 改为手动保存
                                        // 如果内容已修改，先保存当前记录
                                        // if contentModified {
                                        //     autoSaveRecord(recordType: selectedRecordType)
                                        // }
                                        if let newDate = self.calendar.date(byAdding: .month, value: 1, to: currentDate) {
                                            currentDate = newDate
                                            adjustDateToRecordType(selectedRecordType)
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
                                        if let newDate = day.date {
                                            // 禁用自动保存 - 改为手动保存
                                            // 强制保存当前记录（防止内容丢失）
                                            // autoSaveRecord(recordType: selectedRecordType, forceCheck: true)
                                            
                                            // 根据记录类型调整新日期到对应的时间维度
                                            currentDate = newDate
                                            adjustDateToRecordType(selectedRecordType)
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
                                        }
                                    }) {
                                        Text(day.dayNumber)
                                            .font(.system(size: 16))
                                            .fontWeight(day.isSelected ? .bold : .regular)
                                            .foregroundColor(day.isSelected ? .white : (day.isToday ? Color("AppBlue") : (day.isCurrentMonth ? .primary : .secondary)))
                                            .frame(height: 36)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                ZStack {
                                                    if day.isSelected {
                                                        Circle()
                                                            .fill(Color("AppBlue"))
                                                            .frame(width: 36, height: 36)
                                                    } else if day.isToday {
                                                        Circle()
                                                            .stroke(Color("AppBlue"), lineWidth: 2)
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
                        
                    case .weekly: // 周记
                        VStack(spacing: 8) {
                            // 年月选择器
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        // 禁用自动保存 - 改为手动保存
                                        // 强制保存当前记录（防止内容丢失）
                                        // autoSaveRecord(recordType: selectedRecordType, forceCheck: true)
                                        
                                        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
                                            currentDate = newDate
                                            adjustDateToRecordType(selectedRecordType)
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
                                        // 禁用自动保存 - 改为手动保存
                                        // 强制保存当前记录（防止内容丢失）
                                        // autoSaveRecord(recordType: selectedRecordType, forceCheck: true)
                                        
                                        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
                                            currentDate = newDate
                                            adjustDateToRecordType(selectedRecordType)
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
                                        if let newDate = day.date {
                                            // 禁用自动保存 - 改为手动保存
                                            // 强制保存当前记录（防止内容丢失）
                                            // autoSaveRecord(recordType: selectedRecordType, forceCheck: true)
                                            
                                            // 根据记录类型调整新日期到对应的时间维度
                                            currentDate = newDate
                                            adjustDateToRecordType(selectedRecordType)
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
                                        }
                                    }) {
                                        Text(day.dayNumber)
                                            .monospacedDigit()
                                            .font(.system(size: 16))
                                            .fontWeight(day.isSelected ? .bold : .regular)
                                            .foregroundColor(day.isSelected ? .white : (day.isToday ? Color("AppBlue") : (day.isCurrentMonth ? .primary : .secondary)))
                                            .frame(height: 36)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                ZStack {
                                                    if day.isSelected {
                                                        Circle()
                                                            .fill(Color("AppBlue"))
                                                            .frame(width: 36, height: 36)
                                                    } else if day.isToday {
                                                        Circle()
                                                            .stroke(Color("AppBlue"), lineWidth: 2)
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
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(12)
                        
                    case .monthly: // 月记
                        VStack(spacing: 8) {
                            // 年份选择器
                            HStack {
                                Button(action: {
                                    // 禁用自动保存 - 改为手动保存
                                    // 如果内容已修改，先保存当前记录
                                    // if contentModified {
                                    //     autoSaveRecord(recordType: selectedRecordType)
                                    // }
                                    if let newDate = self.calendar.date(byAdding: .year, value: -1, to: currentDate) {
                                        currentDate = newDate
                                        adjustDateToRecordType(selectedRecordType)
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
                                    // 禁用自动保存 - 改为手动保存
                                    // 如果内容已修改，先保存当前记录
                                    // if contentModified {
                                    //     autoSaveRecord(recordType: selectedRecordType)
                                    // }
                                    if let newDate = self.calendar.date(byAdding: .year, value: 1, to: currentDate) {
                                        currentDate = newDate
                                        adjustDateToRecordType(selectedRecordType)
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
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 16) {
                                ForEach(1...12, id: \.self) { month in
                                    Button(action: {
                                        var components = self.calendar.dateComponents([.year, .month, .day], from: currentDate)
                                        components.month = month
                                        components.day = 1
                                        if let newDate = self.calendar.date(from: components) {
                                            currentDate = newDate
                                            adjustDateToRecordType(selectedRecordType)
                                            loadCurrentRecord()
                                        }
                                    }) {
                                        ZStack {
                                            // 预留固定尺寸，避免选中时行高跳变
                                            Rectangle()
                                                .fill(Color.clear)
                                                .frame(width: 36, height: 36)
                                            if self.calendar.component(.month, from: currentDate) == month {
                                                Circle()
                                                    .fill(Color.blue)
                                                    .frame(width: 36, height: 36)
                                            } else if self.calendar.component(.month, from: Date()) == month && 
                                                     self.calendar.component(.year, from: currentDate) == self.calendar.component(.year, from: Date()) {
                                                Circle()
                                                    .stroke(Color.blue, lineWidth: 2)
                                                    .frame(width: 36, height: 36)
                                            }
                                            Text("\(month)")
                                                .monospacedDigit()
                                                .font(.system(size: 16))
                                                .fontWeight(self.calendar.component(.month, from: currentDate) == month ? .bold : .regular)
                                                .foregroundColor(self.calendar.component(.month, from: currentDate) == month ? .white : .primary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 6)
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(12)
                        
                    case .quarterly: // 季记
                        VStack(spacing: 16) {
                            // 年份选择器
                            HStack {
                                Button(action: {
                                    // 禁用自动保存 - 改为手动保存
                                    // 如果内容已修改，先保存当前记录
                                    // if contentModified {
                                    //     autoSaveRecord(recordType: selectedRecordType)
                                    // }
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
                                    // 禁用自动保存 - 改为手动保存
                                    // 如果内容已修改，先保存当前记录
                                    // if contentModified {
                                    //     autoSaveRecord(recordType: selectedRecordType)
                                    // }
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
                                ForEach(1...4, id: \.self) { q in
                                    Button(action: {
                                        // 禁用自动保存 - 改为手动保存
                                        // 如果内容已修改，先保存当前记录
                                        // if contentModified {
                                        //     autoSaveRecord(recordType: selectedRecordType)
                                        // }
                                        let year = self.calendar.component(.year, from: currentDate)
                                        let month = (q - 1) * 3 + 1
                                        var components = self.calendar.dateComponents([.year, .month, .day], from: currentDate)
                                        components.year = year
                                        components.month = month
                                        components.day = 1
                                        if let newDate = self.calendar.date(from: components) {
                                            currentDate = newDate
                                            adjustDateToRecordType(selectedRecordType)
                                            loadCurrentRecord()
                                            // 重置修改状态
                                            contentModified = false
                                        }
                                    }) {
                                        ZStack {
                                            // 预留固定尺寸，避免加粗时尺寸变化
                                            Rectangle()
                                                .fill(Color.clear)
                                                .frame(width: 36, height: 36)
                                            if getCurrentQuarter(currentDate) == q {
                                                Circle()
                                                    .fill(Color("AppBlue"))
                                                    .frame(width: 36, height: 36)
                                            } else if getCurrentQuarter(Date()) == q && 
                                                     self.calendar.component(.year, from: currentDate) == self.calendar.component(.year, from: Date()) {
                                                Circle()
                                                    .stroke(Color("AppBlue"), lineWidth: 2)
                                                    .frame(width: 36, height: 36)
                                            }
                                            Text("Q\(q)")
                                                .font(.system(size: 16))
                                                .fontWeight(getCurrentQuarter(currentDate) == q ? .bold : .regular)
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
                            
                            // 年份快速选择器 - 横向滚动列表形式
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    let currentYear = self.calendar.component(.year, from: currentDate)
                                    // 显示更多年份，提供连续的横向滚动体验
                                    ForEach(max(1, yearListBaseYear-10)...(yearListBaseYear+30), id: \.self) { year in
                                        Button(action: {
                                                // 禁用自动保存 - 改为手动保存
                                                // 如果内容已修改，先保存当前记录
                                                // if contentModified {
                                                //     autoSaveRecord(recordType: selectedRecordType)
                                                // }
                                                var components = self.calendar.dateComponents([.month, .day], from: currentDate)
                                                components.year = year
                                                if let newDate = self.calendar.date(from: components) {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        currentDate = newDate
                                                        // 不调用adjustDateToRecordType，保持用户选择的年份
                                                        loadCurrentRecord()
                                                        // 重置修改状态
                                                        contentModified = false
                                                    }
                                                }
                                        }) {
                                            ZStack {
                                                if currentYear == year {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color("AppBlue"))
                                                        .frame(width: 60, height: 36)
                                                } else if self.calendar.component(.year, from: Date()) == year && 
                                                         self.calendar.component(.year, from: Date()) != currentYear {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color("AppBlue"), lineWidth: 2)
                                                        .frame(width: 60, height: 36)
                                                } else {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color(UIColor.systemGray6))
                                                        .frame(width: 60, height: 36)
                                                        .opacity(0.6)
                                                }
                                                Text("\(year)")
                                                    .monospacedDigit()
                                                    .font(.system(size: 16))
                                                    .fontWeight(currentYear == year ? .bold : .regular)
                                                    .foregroundColor(currentYear == year ? .white : .primary)
                                                    .frame(width: 60, height: 36)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.8)
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                            .padding(.horizontal, -8) // 抵消父容器padding，实现边缘到边缘的滚动
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemGroupedBackground))
                        .cornerRadius(12)
                        
                    default:
                        EmptyView()
                    }
                            }
                            .padding(.bottom, 8)
                        }
                        
                        // 记录内容区域 - 使用TabView实现左右滑动
                        TabView(selection: $currentRecordTypeIndex) {
                    ForEach(recordTypes.indices, id: \.self) { index in
                        ZStack(alignment: .top) {
                            // "近期"页签使用可滚动的ScrollView，其他页签使用固定尺寸不可滚动的VStack
                            if recordTypes[index] == .recent {
                                ScrollView {
                                    VStack(spacing: 0) {
                                        // 移除页签顶部的下拉标题栏占位，避免与悬浮顶栏产生视觉叠层
                                        
                                        VStack(alignment: .leading, spacing: 16) {
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
                                                                .foregroundColor(Color("AppBlue"))
                                                            Image(systemName: "chevron.down")
                                                                .font(.caption)
                                                                .foregroundColor(Color("AppBlue"))
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
                                            .frame(minHeight: UIScreen.main.bounds.height * 0.5, alignment: .top)
                                        }
                                        .padding(.top, 8)
                                        .padding(.bottom, 30)
                                    }
                                }
                            } else {
                                // 其他页签使用ScrollView包装，支持键盘适应
                                ScrollView {
                                    VStack(spacing: 0) {
                                        // 移除页签顶部的下拉标题栏占位，避免与悬浮顶栏产生视觉叠层
                                        
                                        VStack(alignment: .leading, spacing: 16) {
                                            // 其他页签显示正常记录内容
                                            VStack(alignment: .leading, spacing: 12) {
                                                // 移除记录标题
                                                
                                                // 记录正文编辑器（富文本与图片），绑定到 recordContent
                                                NotesStyleRecordEditor(
                                                    text: $recordContent,
                                                    images: $selectedImages,
                                                    minHeight: 120,
                                                    onImagesChanged: { images in
                                                        selectedImages = images
                                                        contentModified = true
                                                    },
                                                    onTextChanged: {
                                                        contentModified = true
                                                        // 禁用自动保存 - 改为手动保存
                                                        // 文本变更时即时自动保存，强制检查避免丢失
                                                        // autoSaveRecord(recordType: recordTypes[index], forceCheck: true)
                                                    }
                                                )
                                                .frame(minHeight: 120)
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
                                            
                                            // 占位空间，确保工具栏悬浮效果
                                            Spacer()
                                                .frame(height: 100)
                                        }
                                        .padding(.top, 8)
                                        .padding(.bottom, 30)
                                    }
                                }
                                .ignoresSafeArea(.keyboard, edges: .bottom)
                            }
                            
                            // 工具栏 - 整合添加图片、字数统计和心情选择功能
                            // 使用ZStack实现真正的悬浮效果，不随页面滚动而移动
                            // "近期"页签不显示工具栏
                            if recordTypes[index] != .recent {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        FloatingToolbarView(
                                            text: $recordContent,
                                            images: $selectedImages,
                                            selectedMood: $selectedMood,
                                            showMoodSelector: recordTypes[index] == .daily,
                                            goals: allGoals,
                                            contacts: allContacts,
                                            onImagesChanged: { images in
                                                selectedImages = images
                                                contentModified = true
                                            },
                                            onMoodChanged: { mood in
                                                selectedMood = mood
                                                contentModified = true
                                            }
                                        )
                                        .frame(width: recordTypes[index] == .daily ? 340 : 300) // 日记页签加宽，避免字数换行
                                    }
                                    .padding(.trailing, 12) // 贴近屏幕右侧，对齐
                                    .padding(.bottom, 8) // 与底部保持合适间距
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .tag(index)
                    }
                    }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .onChange(of: currentRecordTypeIndex) { _, newIndex in
                    // 切换页签时收起键盘
                    dismissKeyboard()
                    
                    // 获取新的记录类型
                    let newRecordType = recordTypes[newIndex]
                    
                    // 禁用自动保存 - 改为手动保存
                    // 如果内容已修改，先保存当前记录（使用当前的记录类型和日期）
                    // if contentModified {
                    //     autoSaveRecord(recordType: selectedRecordType)
                    // }
                    
                    // 同步更新selectedRecordType
                    selectedRecordType = newRecordType
                    
                    // 根据记录类型跳转到今天对应的时间段
                    let today = Date()
                    let calendar = self.calendar
                    
                    switch newRecordType {
                    case .daily:
                        // 日记：跳转到今天
                        currentDate = today
                    case .weekly:
                        // 周记：跳转到本周（周日作为周起始）
                        let weekday = calendar.component(.weekday, from: today)
                        let daysToSubtract = weekday - 1 // 周日是第1天
                        if let weekStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) {
                            currentDate = weekStartDate
                        }
                    case .monthly:
                        // 月记：跳转到本月第一天
                        let year = calendar.component(.year, from: today)
                        let month = calendar.component(.month, from: today)
                        var components = DateComponents()
                        components.year = year
                        components.month = month
                        components.day = 1
                        if let monthStartDate = calendar.date(from: components) {
                            currentDate = monthStartDate
                        }
                    case .quarterly:
                        // 季记：跳转到本季度第一天
                        let year = calendar.component(.year, from: today)
                        let month = calendar.component(.month, from: today)
                        let quarter = (month - 1) / 3 + 1
                        let firstMonthOfQuarter = (quarter - 1) * 3 + 1
                        
                        var components = DateComponents()
                        components.year = year
                        components.month = firstMonthOfQuarter
                        components.day = 1
                        if let quarterStartDate = calendar.date(from: components) {
                            currentDate = quarterStartDate
                        }
                    case .yearly:
                        // 年记：跳转到本年第一天
                        let year = calendar.component(.year, from: today)
                        var components = DateComponents()
                        components.year = year
                        components.month = 1
                        components.day = 1
                        if let yearStartDate = calendar.date(from: components) {
                            currentDate = yearStartDate
                        }
                        // 设置年份列表基准年份
                        yearListBaseYear = max(1, year + 10)
                    case .recent:
                        // 近期：保持当前日期不变
                        break
                    }
                    
                    // 更新日期组件
                    updateDateComponents()
                    
                    // 加载对应的记录内容
                    loadCurrentRecord()
                    // 重置修改状态
                    contentModified = false
                        }
                    }
                    // 移除背景与圆角，保持外层列表卡片自身样式
                

                }
            }
            // 顶栏改为覆盖层，保持与目标模块一致的布局关系
            .overlay(alignment: .top) {
                headerView
                    .offset(y: -20)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .tags:
                    TagsView()
                        .navigationBarBackButtonHidden(true)
                        .navigationTitle("我的标签")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("返回") {
                                    navigationManager.pop(for: selectedTab)
                                }
                            }
                        }
                case .settings:
                    SettingsView()
                        .navigationBarBackButtonHidden(true)
                        .navigationTitle("设置")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("返回") {
                                    navigationManager.pop(for: selectedTab)
                                }
                            }
                        }
                case .userEdit:
                    Group {
                        if let user = allUsers.first {
                            UserEditView(user: user)
                                .navigationBarBackButtonHidden(true)
                                .navigationTitle("个人信息")
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button("返回") {
                                            navigationManager.pop(for: selectedTab)
                                        }
                                    }
                                }
                        } else {
                            EmptyView()
                        }
                    }
                default:
                    EmptyView()
                }
            }
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
                // 默认收起所有时间选择器
                showDatePicker = false
                // 只在第一次加载时清理重复记录
                if !hasCleanedDuplicates {
                    cleanDuplicateRecords()
                    hasCleanedDuplicates = true
                }
            }
            .onDisappear {
                // 禁用自动保存 - 改为手动保存
                // 离开页面时自动保存记录
                // if contentModified {
                //     autoSaveRecord(recordType: selectedRecordType)
                // }
            }
            .onChange(of: selectedTab) { _, newValue in
                // 禁用自动保存 - 改为手动保存
                // 切换标签页时自动保存记录
                // if contentModified {
                //     autoSaveRecord(recordType: selectedRecordType)
                //     // 重置修改状态
                //     contentModified = false
                // }
            }
            .onChange(of: selectedRecordType) { oldValue, newValue in
                // 切换记录类型时收起键盘
                dismissKeyboard()
                
                // 禁用自动保存 - 改为手动保存
                // 如果内容已修改，先保存当前记录
                // if contentModified {
                //     autoSaveRecord(recordType: oldValue)
                // }
                
                // 切换记录类型时保持日期选择器收起
                showDatePicker = false
                
                // 检查是否是从"全部"页签点击记录导致的记录类型切换
                // 如果是通过navigateToRecord函数设置的记录类型，则不自动跳转到今天
                if !UserDefaults.standard.bool(forKey: "isNavigatingFromRecordCard") {
                    print("📅 记录类型切换 - 从: \(oldValue) 到: \(newValue) - 自动跳转到今天")
                    
                    // 根据记录类型跳转到今天对应的时间段
                    let today = Date()
                    let calendar = self.calendar
                    
                    switch newValue {
                    case .daily:
                        // 日记：跳转到今天
                        currentDate = today
                    case .weekly:
                        // 周记：跳转到本周（周日作为周起始）
                        let weekday = calendar.component(.weekday, from: today)
                        let daysToSubtract = weekday - 1 // 周日是第1天
                        if let weekStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) {
                            currentDate = weekStartDate
                        }
                    case .monthly:
                        // 月记：跳转到本月第一天
                        let year = calendar.component(.year, from: today)
                        let month = calendar.component(.month, from: today)
                        var components = DateComponents()
                        components.year = year
                        components.month = month
                        components.day = 1
                        if let monthStartDate = calendar.date(from: components) {
                            currentDate = monthStartDate
                        }
                    case .quarterly:
                        // 季记：跳转到本季度第一天
                        let year = calendar.component(.year, from: today)
                        let month = calendar.component(.month, from: today)
                        let quarter = (month - 1) / 3 + 1
                        let firstMonthOfQuarter = (quarter - 1) * 3 + 1
                        
                        var components = DateComponents()
                        components.year = year
                        components.month = firstMonthOfQuarter
                        components.day = 1
                        if let quarterStartDate = calendar.date(from: components) {
                            currentDate = quarterStartDate
                        }
                    case .yearly:
                        // 年记：跳转到本年第一天
                        let year = calendar.component(.year, from: today)
                        var components = DateComponents()
                        components.year = year
                        components.month = 1
                        components.day = 1
                        if let yearStartDate = calendar.date(from: components) {
                            currentDate = yearStartDate
                        }
                        // 设置年份列表基准年份
                        yearListBaseYear = max(1, year + 10)
                    case .recent:
                        // 近期：保持当前日期不变
                        break
                    }
                    
                    // 更新日期组件
                    updateDateComponents()
                } else {
                    print("📅 记录类型切换 - 从: \(oldValue) 到: \(newValue) - 跳过自动跳转到今天（从记录卡片导航）")
                    // 重置标志
                    UserDefaults.standard.set(false, forKey: "isNavigatingFromRecordCard")
                }
                
                // 同步页签索引
                syncRecordTypeIndex()
                
                // 当记录类型变化时，加载对应的记录
                // 使用 DispatchQueue.main.async 确保在下一次渲染周期加载记录，避免并发问题
                DispatchQueue.main.async {
                    loadCurrentRecord()
                    // 重置修改状态
                    contentModified = false
                }
            }
            // 侧边栏移至应用根层，由全局 SidebarManager 控制
            // 统一页面级背景为系统分组背景，以与其他模块一致
            .background(
                Color(UIColor.systemGroupedBackground)
            )
        }
        
        // 关闭 body
        }
    
    // 格式化日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: currentDate)
    }

    // 顶栏内联日期文本：根据记录类型显示不同格式（简洁版）
    var headerInlineDateText: String {
        switch selectedRecordType {
        case .recent:
            return ""
        case .daily:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.string(from: currentDate)
        case .weekly:
            let calendar = self.calendar
            let year = calendar.component(.yearForWeekOfYear, from: currentDate)
            let week = calendar.component(.weekOfYear, from: currentDate)
            return "\(year)年第\(week)周"
        case .monthly:
            let calendar = self.calendar
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            return "\(year)年\(month)月"
        case .quarterly:
            let calendar = self.calendar
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let quarter = (month - 1) / 3 + 1
            return "\(year)年Q\(quarter)"
        case .yearly:
            let calendar = self.calendar
            let year = calendar.component(.year, from: currentDate)
            return "\(year)年"
        }
    }
    
    // 完整日期文本：用于按钮提示或长按菜单
    var headerFullDateText: String {
        switch selectedRecordType {
        case .recent:
            return ""
        case .daily:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.string(from: currentDate)
        case .weekly:
            let calendar = self.calendar
            let year = calendar.component(.yearForWeekOfYear, from: currentDate)
            let week = calendar.component(.weekOfYear, from: currentDate)
            return "\(year)年第\(week)周"
        case .monthly:
            let calendar = self.calendar
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            return "\(year)年\(month)月"
        case .quarterly:
            let calendar = self.calendar
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let quarter = (month - 1) / 3 + 1
            return "\(year)年第\(quarter)季度"
        case .yearly:
            let calendar = self.calendar
            let year = calendar.component(.year, from: currentDate)
            return "\(year)年"
        }
    }
    
    // 注意：yearMonthFormatter 已在文件顶部声明
    
    // 更新日期组件
    private func updateDateComponents() {
        let calendar = self.calendar
        currentYear = selectedRecordType == .weekly ? calendar.component(.yearForWeekOfYear, from: currentDate) : calendar.component(.year, from: currentDate)
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
            let year = calendar.component(.yearForWeekOfYear, from: currentDate)
            let week = calendar.component(.weekOfYear, from: currentDate)
            return "\(year)年第\(week)周 周记"
        case .monthly:
            let calendar = self.calendar
            let year = calendar.component(.yearForWeekOfYear, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            return "\(year)年\(month)月 月记"
        case .quarterly:
            let calendar = self.calendar
            let year = calendar.component(.yearForWeekOfYear, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let quarter = (month - 1) / 3 + 1
            return "\(year)年第\(quarter)季度 季记"
        case .yearly:
            let calendar = self.calendar
            let year = calendar.component(.year, from: currentDate)
            return "\(year)年 年记"
        }
    }

    // 刷新当前周期的归纳内容，仅更新显示，不持久化归纳块
    private func refreshAggregationForCurrentPeriod() {
        // 同步当前日期组件
        updateDateComponents()
        let year = currentYear
        let month = currentMonth
        let week = currentWeek
        let quarter = currentQuarter

        // 仅保留用户输入部分，避免重复归纳块
        let userContent = extractUserContent(from: recordContent, recordType: selectedRecordType)

        // 计算下一级记录的归纳内容
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

        // 只在用户主动点击汇总按钮时才更新显示内容
        // 避免在页面切换等操作时意外覆盖用户内容
        if !lowerLevelContent.isEmpty {
            recordContent = userContent + lowerLevelContent
            // 标记为需要保存，因为内容已更改
            contentModified = true
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
        
        // 保存成功后不再重新加载记录，保持当前显示的内容不变
        // 这样可以避免保存后内容"消失"的问题
        contentModified = false
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
                record.year == calendar.component(.yearForWeekOfYear, from: date) &&
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
        // 周记需要使用 ISO 周基年（yearForWeekOfYear），避免跨年周显示错误
        let recordYear = selectedRecordType == .weekly
            ? calendar.component(.yearForWeekOfYear, from: currentDate)
            : calendar.component(.year, from: currentDate)
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
            week: selectedRecordType == .weekly || selectedRecordType == .daily ? recordWeek : nil,
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
        
        // 根据记录类型查找对应的归拢标记 - 只在内容实际包含这些标记时才进行提取
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
        
        // 获取当前显示的内容
        let currentContent = recordContent
        
        // 检查内容是否为空（去除空白字符）
        let trimmedContent = currentContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果是强制检查模式，即使内容为空也要检查是否需要保存（防止内容丢失）
        // 正常模式下，检查内容是否为空
        if !forceCheck {
            guard !trimmedContent.isEmpty else {
                return
            }
        }
        
        // 检查是否已存在同一日期的记录，如果存在则更新，否则创建新记录
        if let existingRecord = findExistingRecord(for: recordType, date: currentDate) {
            // 更新现有记录 - 保存用户输入的完整内容
            existingRecord.title = recordTitle
            existingRecord.content = currentContent  // 保存完整内容，不提取
            existingRecord.createTime = Date() // 更新创建时间为当前时间
            existingRecord.images = selectedImages.isEmpty ? nil : selectedImages
            if recordType == .daily {
                existingRecord.mood = selectedMood
            }
            currentRecord = existingRecord
        } else if !trimmedContent.isEmpty {
            // 只有在内容不为空时才创建新记录
            createNewRecordForAutoSave(userContent: currentContent, recordType: recordType)
        }
        
        // 立即保存到数据库，不再使用异步方式
        do {
            try modelContext.save()
            // 保存成功后重置修改状态
            contentModified = false
        } catch {
            print("自动保存记录失败: \(error)")
        }
    }
    
    // 为自动保存创建新记录的辅助方法
    private func createNewRecordForAutoSave(userContent: String, recordType: RecordType) {
        // 创建新记录
        let calendar = self.calendar
        // 周记需要使用 ISO 周基年（yearForWeekOfYear），避免跨年周显示错误
        let recordYear = recordType == .weekly
            ? calendar.component(.yearForWeekOfYear, from: currentDate)
            : calendar.component(.year, from: currentDate)
        let recordMonth = calendar.component(.month, from: currentDate)
        let recordWeek = calendar.component(.weekOfYear, from: currentDate)
        let recordQuarter = getCurrentQuarter(currentDate)
        
        let newRecord = Record(
            title: recordTitle,
            content: userContent, // 保存完整内容
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
    
    // 获取下一级记录内容（仅向前做一级汇总）
    private func getLowerLevelRecordsContent(recordType: RecordType, year: Int, month: Int? = nil, week: Int? = nil, quarter: Int? = nil) -> String {
        var lowerLevelRecords: [Record] = []
        var contentBuilder = ""
        
        switch recordType {
        case .weekly: // 周记：仅汇总本周所有日记内已记录的内容
            guard let week = week else { return "" }
            
            // 获取该周的所有日记
            lowerLevelRecords = allRecords.filter { record in
                record.recordType == .daily &&
                record.year == year &&
                record.week == week
            }
            
            if !lowerLevelRecords.isEmpty {
                contentBuilder += "\n\n【本周日记汇总】：\n"
                
                // 按日期排序
                let sortedRecords = lowerLevelRecords.sorted { record1, record2 in
                    guard let day1 = record1.day, let day2 = record2.day else { return false }
                    return day1 < day2
                }
                
                for record in sortedRecords {
                    if let day = record.day {
                        // 获取星期几（周一到周日）
                        let weekday = getWeekdayName(for: day, in: month ?? 1, year: year, week: week)
                        contentBuilder += "\(weekday)：\(record.content.trimmingCharacters(in: .whitespacesAndNewlines))\n"
                    }
                }
            }
            
        case .monthly: // 月记：仅汇总本月所有周记内已记录的内容
            guard let month = month else { return "" }
            
            // 获取该月的所有周记
            lowerLevelRecords = allRecords.filter { record in
                record.recordType == .weekly &&
                record.year == year &&
                calendar.component(.month, from: calendar.date(from: DateComponents(year: year, weekday: 1, weekOfYear: record.week)) ?? Date()) == month
            }
            
            if !lowerLevelRecords.isEmpty {
                contentBuilder += "\n\n【本月周记汇总】：\n"
                
                // 按周排序
                let sortedRecords = lowerLevelRecords.sorted { record1, record2 in
                    guard let week1 = record1.week, let week2 = record2.week else { return false }
                    return week1 < week2
                }
                
                for record in sortedRecords {
                    if let week = record.week {
                        // 只提取用户内容，不包含下级汇总信息
                        let userContent = extractUserContent(from: record.content, recordType: .weekly).trimmingCharacters(in: .whitespacesAndNewlines)
                        contentBuilder += "第\(week)周：\(userContent)\n"
                    }
                }
            }
            
        case .quarterly: // 季记：仅汇总本季所有月记内已记录的内容
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
                contentBuilder += "\n\n【本季度月记汇总】：\n"
                
                // 按月份排序
                let sortedRecords = lowerLevelRecords.sorted { record1, record2 in
                    guard let month1 = record1.month, let month2 = record2.month else { return false }
                    return month1 < month2
                }
                
                for record in sortedRecords {
                    if let month = record.month {
                        // 只提取用户内容，不包含下级汇总信息
                        let userContent = extractUserContent(from: record.content, recordType: .monthly).trimmingCharacters(in: .whitespacesAndNewlines)
                        contentBuilder += "\(month)月：\(userContent)\n"
                    }
                }
            }
            
        case .yearly: // 年记：仅汇总本年所有季记内已记录的内容
            // 获取该年的所有季记
            lowerLevelRecords = allRecords.filter { record in
                record.recordType == .quarterly &&
                record.year == year
            }
            
            if !lowerLevelRecords.isEmpty {
                contentBuilder += "\n\n【本年季记汇总】：\n"
                
                // 按季度排序
                let sortedRecords = lowerLevelRecords.sorted { record1, record2 in
                    guard let quarter1 = record1.quarter, let quarter2 = record2.quarter else { return false }
                    return quarter1 < quarter2
                }
                
                for record in sortedRecords {
                    if let quarter = record.quarter {
                        // 只提取用户内容，不包含下级汇总信息
                        let userContent = extractUserContent(from: record.content, recordType: .quarterly).trimmingCharacters(in: .whitespacesAndNewlines)
                        contentBuilder += "第\(quarter)季度：\(userContent)\n"
                    }
                }
            }
            
        default:
            break
        }
        
        return contentBuilder
    }
    
    // 根据记录类型调整日期到对应的时间维度
    private func adjustDateToRecordType(_ recordType: RecordType) {
        let calendar = self.calendar
        
        switch recordType {
        case .daily:
            // 日记：保持当前日期不变
            break
            
        case .weekly:
            // 周记：调整到当前日期所在周的周日（周记的起始日）
            let weekday = calendar.component(.weekday, from: currentDate)
            let daysToSubtract = weekday - 1 // 周日是第1天
            if let weekStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: currentDate) {
                currentDate = weekStartDate
            }
            
        case .monthly:
            // 月记：调整到当月第一天
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            if let monthStartDate = calendar.date(from: components) {
                currentDate = monthStartDate
            }
            
        case .quarterly:
            // 季记：调整到当季度第一天
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            let quarter = (month - 1) / 3 + 1
            let firstMonthOfQuarter = (quarter - 1) * 3 + 1
            
            var components = DateComponents()
            components.year = year
            components.month = firstMonthOfQuarter
            components.day = 1
            if let quarterStartDate = calendar.date(from: components) {
                currentDate = quarterStartDate
            }
            
        case .yearly:
            // 年记：调整到当年第一天
            let year = calendar.component(.year, from: currentDate)
            var components = DateComponents()
            components.year = year
            components.month = 1
            components.day = 1
            if let yearStartDate = calendar.date(from: components) {
                currentDate = yearStartDate
            }
            
        case .recent:
            // 近期：不调整日期
            break
        }
        
        // 更新日期组件
        updateDateComponents()
    }
    
    // 加载当前选择日期的记录
    private func loadCurrentRecord() {
        // 如果正在清空记录，跳过加载以防止内容重新出现
        if isClearingRecord {
            return
        }
        
        // 根据记录类型和日期查找记录
        var filteredRecords: [Record] = []
        let calendar = self.calendar
        let year = calendar.component(.year, from: currentDate)
        // 周视图需要使用 ISO 周基年，避免跨年周无法匹配
        let weekBasedYear = calendar.component(.yearForWeekOfYear, from: currentDate)
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
            // 查找当前日期所在周的周记（使用周基年）
            filteredRecords = allRecords.filter { record in
                record.recordType == .weekly &&
                record.year == weekBasedYear &&
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
            
            // 关闭自动汇总功能 - 不再自动添加下级记录内容
            // 仅显示用户保存的原始内容
        } else {
            // 如果没有找到记录，则清空内容
            currentRecord = nil
            recordContent = ""
            selectedMood = nil
            selectedImages = []
            
            // 关闭自动汇总功能 - 不再自动添加下级记录内容作为参考
        }
    }
    
    // 加载更多记录
    private func loadMoreRecords() {
        displayedRecordsCount += recordsPerPage
    }
    
    // 导航到记录详情
    private func navigateToRecord(_ record: Record) {
        print("⏱️ 记录跳转开始 - ID: \(record.id), 类型: \(record.recordType), 年: \(record.year), 月: \(record.month ?? 0), 日: \(record.day ?? 0), 周: \(record.week ?? 0), 季度: \(record.quarter ?? 0)")
        
        // 设置标志，表示正在从记录卡片导航，防止记录类型切换时自动跳转到今天
        UserDefaults.standard.set(true, forKey: "isNavigatingFromRecordCard")
        
        // 1. 设置选中的记录类型 - 确保先设置记录类型，避免被其他onChange事件覆盖
        selectedRecordType = record.recordType
        
        // 2. 验证日期参数有效性
        let validYear = record.year > 0 ? record.year : calendar.component(.year, from: Date())
        let validMonth = max(1, min(record.month ?? 1, 12))
        let validDay = max(1, min(record.day ?? 1, 31))
        let validWeek = max(1, min(record.week ?? 1, 53))
        let validQuarter = max(1, min(record.quarter ?? 1, 4))
        
        print("⏱️ 记录跳转 - 验证后参数: 年: \(validYear), 月: \(validMonth), 日: \(validDay), 周: \(validWeek), 季度: \(validQuarter)")
        
        // 3. 根据记录类型和记录中的日期信息创建正确的Date对象
        var dateComponents = DateComponents()
        dateComponents.year = validYear
        
        switch record.recordType {
        case .daily:
            // 日记：使用完整的年月日
            dateComponents.month = validMonth
            dateComponents.day = validDay
        case .weekly:
            // 周记：使用年和周数
            dateComponents.weekOfYear = validWeek
            dateComponents.weekday = 1  // 从周日开始
            // 使用基于周的年份，避免周数跨年导致的日期计算错误
            dateComponents.yearForWeekOfYear = validYear
        case .monthly:
            // 月记：使用年月，日设为1号
            dateComponents.month = validMonth
            dateComponents.day = 1
        case .quarterly:
            // 季记：使用年和季度的第一个月
            let firstMonthOfQuarter = (validQuarter - 1) * 3 + 1
            dateComponents.month = firstMonthOfQuarter
            dateComponents.day = 1
        case .yearly:
            // 年记：使用年份，月日设为1月1日
            dateComponents.month = 1
            dateComponents.day = 1
        default:
            // 其他情况使用默认值
            dateComponents.month = validMonth
            dateComponents.day = validDay
        }
        
        // 4. 更新当前日期 - 确保日期有效
        if let date = calendar.date(from: dateComponents) {
            // 禁用自动跳转到今天的逻辑
            DispatchQueue.main.async {
                self.currentDate = date
                print("⏱️ 记录跳转 - 设置日期成功: \(date)")
                
                // 5. 直接设置日期组件为记录的实际值，不依赖updateDateComponents重新计算
                self.currentYear = validYear
                self.currentMonth = validMonth
                self.currentDay = validDay
                self.currentWeek = validWeek
                self.currentQuarter = validQuarter
                
                // 6. 强制更新UI
                self.updateDateComponents()
                
                print("⏱️ 记录跳转完成 - 当前日期组件: 年: \(self.currentYear), 月: \(self.currentMonth), 日: \(self.currentDay), 周: \(self.currentWeek), 季度: \(self.currentQuarter)")
            }
        } else {
            print("⚠️ 记录跳转失败 - 无法创建有效日期")
        }
        
        // 注意：不调用updateDateComponents()，因为它会根据currentDate重新计算组件
        // 而我们需要保持记录的原始日期信息
        
        // 同步页签索引，确保TabView内容更新
        syncRecordTypeIndex()
        
        // 强制更新TabView的当前索引，确保切换到正确的页签
        if let index = recordTypes.firstIndex(of: record.recordType) {
            currentRecordTypeIndex = index
        }
        
        // 加载对应的记录
        loadCurrentRecord()
    }
    
    // MARK: - 记录排序功能
    
    private func sortRecordsByTime() {
        // 切换近期页签的排序方向（时间升/降序）
        withAnimation(.easeInOut(duration: 0.2)) {
            isRecentSortAscending.toggle()
            // 重置分页计数，避免旧的分页限制导致列表不刷新完整
            displayedRecordsCount = recordsPerPage
        }
        // 日志输出，便于调试
        print("🗂️ 切换近期排序：\(isRecentSortAscending ? "升序" : "降序")，当前显示数量：\(displayedRecordsCount)")
    }
    
    // MARK: - 清空当前记录
    private func clearCurrentRecord() {
        // 设置清空标志，防止自动重新加载
        isClearingRecord = true
        
        // 查找当前记录
        if let existingRecord = findExistingRecord(for: selectedRecordType, date: currentDate) {
            // 删除数据库中的记录
            modelContext.delete(existingRecord)
            
            // 保存更改
            do {
                try modelContext.save()
                
                // 清空当前显示的内容
                currentRecord = nil
                recordContent = ""
                selectedMood = nil
                selectedImages = []
                contentModified = false
                
            } catch {
                print("清空记录失败: \(error)")
            }
        } else {
            // 如果没有找到记录，只清空显示的内容
            currentRecord = nil
            recordContent = ""
            selectedMood = nil
            selectedImages = []
            contentModified = false
        }
        
        // 延迟重置标志，确保SwiftData的自动更新完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isClearingRecord = false
        }
    }
    
    // MARK: - 辅助方法
    
    // 获取星期几的名称（周一到周日）
    private func getWeekdayName(for day: Int, in month: Int, year: Int, week: Int) -> String {
        let calendar = self.calendar
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        // 尝试创建日期
        if let date = calendar.date(from: components) {
            let weekday = calendar.component(.weekday, from: date)
            // weekday: 1 = 周日, 2 = 周一, ..., 7 = 周六
            let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
            return weekdays[weekday - 1]
        }
        
        // 如果无法创建日期，返回默认格式
        return "\(month)月\(day)日"
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

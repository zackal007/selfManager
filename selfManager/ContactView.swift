//
//  ContactView.swift
//  selfManager
//
//  Created by AI Assistant on 24.12.25.
//

import SwiftUI
import UIKit
import Foundation
import SwiftData

struct ContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.modifyTime, order: .reverse) private var allContacts: [Contact]
    @Query private var allGoals: [Goal]
    @Query private var allRecords: [Record]
    @Query private var allUsers: [User]
    @StateObject private var navigationManager = NavigationManager.shared
    
    // 绑定到TabView的选中标签
    @Binding var selectedTab: Int
    
    // 侧边栏使用全局管理：移除本地状态，统一为全局覆盖层
    
    // 分段控制器选择
    @State private var selectedSegment = 0
    
    // 视图模式：画廊视图或列表视图（默认优先展示卡片视图）
    @State private var viewMode: ViewMode = .gallery
    
    // 分类和排序选项
    @State private var categoryOption: CategoryOption = .type
    @State private var sortOption: SortOption = .name
    
    // 添加联系人的状态变量
    @State private var showAddContactSheet = false
    
    // 搜索相关
    @State private var searchText = ""
    @State private var showSearchBar = false
    
    // 导航状态
    @State private var selectedGoalId: UUID? = nil
    @State private var selectedContactId: UUID? = nil
    @State private var selectedRecordId: UUID? = nil
    @State private var showGoalDetail = false
    @State private var showContactDetail = false
    @State private var showRecordDetail = false
    // 顶栏动态高度（用于透明占位，避免内容被遮挡）
    @State private var headerHeight: CGFloat = 120
    
    // 初始化方法，接收selectedTab绑定
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    // 根据分类和排序选项处理后的联系人数据
    private var processedAllContacts: [Contact] {
        return sortContacts(categorizeContacts(allContacts))
    }
    
    private var processedFamilyContacts: [Contact] {
        let familyContacts = allContacts.filter { $0.contactType == .family }
        return sortContacts(categorizeContacts(familyContacts))
    }
    
    private var processedFriendContacts: [Contact] {
        let friendContacts = allContacts.filter { $0.contactType == .intimateFriend }
        return sortContacts(categorizeContacts(friendContacts))
    }
    
    private var processedWorkContacts: [Contact] {
        let workContacts = allContacts.filter { $0.contactType == .workplace }
        return sortContacts(categorizeContacts(workContacts))
    }
    
    private var processedExampleContacts: [Contact] {
        let exampleContacts = allContacts.filter { $0.contactType == .roleModel }
        return sortContacts(categorizeContacts(exampleContacts))
    }
    
    // 搜索过滤后的联系人
    private var filteredContacts: [Contact] {
        let contacts = contactsForSelectedSegment()
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText) ||
                (contact.company?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (contact.position?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                contact.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    // 根据选中的分段返回对应的联系人数据
    private func contactsForSelectedSegment() -> [Contact] {
        let base: [Contact]
        switch selectedSegment {
        case 0:
            base = allContacts
        case 1:
            base = allContacts.filter { $0.contactType == .family }
        case 2:
            base = allContacts.filter { $0.contactType == .intimateFriend }
        case 3:
            base = allContacts.filter { $0.contactType == .workplace }
        case 4:
            base = allContacts.filter { $0.contactType == .roleModel }
        case 5:
            base = allContacts.filter { $0.contactType == .other }
        case 6:
            base = allContacts.filter { [.doctor, .lawyer, .rich, .official, .gangster].contains($0.contactType) }
        default:
            base = allContacts
        }
        return sortContacts(categorizeContacts(base))
    }
    
    // 根据分类选项对联系人进行分类
    private func categorizeContacts(_ contacts: [Contact]) -> [Contact] {
        switch categoryOption {
        case .time:
            return contacts.sorted { $0.modifyTime > $1.modifyTime }
        case .type:
            return contacts.sorted { $0.contactType.rawValue < $1.contactType.rawValue }
        }
    }
    
    // 根据排序选项对联系人进行排序
    private func sortContacts(_ contacts: [Contact]) -> [Contact] {
        switch sortOption {
        case .name:
            return contacts.sorted { $0.name < $1.name }
        case .createTime:
            return contacts.sorted { $0.createTime > $1.createTime }
        case .modifyTime:
            return contacts.sorted { $0.modifyTime > $1.modifyTime }
        case .visitTime:
            // 使用最后联系时间作为访问时间
            return contacts.sorted { (contact1, contact2) in
                let date1 = contact1.lastContactDate ?? Date.distantPast
                let date2 = contact2.lastContactDate ?? Date.distantPast
                return date1 > date2
            }
        case .importance:
            // 按重要性排序，从高到低
            return contacts.sorted { $0.importance.rawValue > $1.importance.rawValue }
        }
    }
    
    var body: some View {
        // 页面导航容器：管理人脉页面的导航栈
        NavigationStack(path: $navigationManager.contactNavigationPath) {
            // 页面框架容器：承载顶栏、搜索栏与列表内容
            ZStack {
                // 主内容
                // 顶栏：页面标题与操作菜单（侧边栏、搜索、添加、筛选）
                VStack(spacing: 0) {
                    // 搜索输入框：用于搜索联系人
                    if showSearchBar {
                        searchBarView
                            .zIndex(9)
                    }
                    
                    contentView
                }
                .background(Color(.systemGroupedBackground))
                .navigationBarHidden(true)
                // 导航目的地：进入目标详情
                .navigationDestination(isPresented: $showGoalDetail) {
                    if let goalId = selectedGoalId,
                       let goal = allGoals.first(where: { $0.id == goalId }) {
                        GoalDetailView(goal: goal)
                    }
                }
                // 导航目的地：进入联系人详情
                .navigationDestination(isPresented: $showContactDetail) {
                    if let contactId = selectedContactId,
                       let contact = allContacts.first(where: { $0.id == contactId }) {
                        ContactDetailView(contact: contact)
                    }
                }
                // 导航目的地：进入记录详情
                .navigationDestination(isPresented: $showRecordDetail) {
                    if let recordId = selectedRecordId,
                       let record = allRecords.first(where: { $0.id == recordId }) {
                        RecordView(selectedTab: .constant(2))
                    }
                }
                // 导航目的地：进入设置与标签管理（使用当前选项卡的导航栈）
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
                // 弹窗：添加联系人表单
                .sheet(isPresented: $showAddContactSheet) {
                    AddContactView(isPresented: $showAddContactSheet, selectedSegment: $selectedSegment)
                }
                .safeAreaInset(edge: .top) {
                    headerView
                }
                
                // 侧边栏移至应用根层，由全局 SidebarManager 控制
            }
        }
        // 与首页一致：在顶层隐藏系统导航栏，统一顶部外观
        .navigationBarHidden(true)
    }
    
    // 分段控制器视图
    private var segmentedControlView: some View {
        EmptyView() // 已整合到headerView中，保留空视图以避免编译错误
    }
    
    // 内容视图
    private var contentView: some View {
        TabView(selection: $selectedSegment) {
            /*
            ForEach(0..<5, id: \.self) { index in
                contactListView
                    .tag(index)
            }
            */
            ForEach(0..<7) { index in
                contactListView
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
    
    // 顶部标题栏
    private var headerView: some View {
        // 悬浮的顶部标题栏（整合联系人类型筛选器）
        VStack(spacing: 0) {
            // 第一行：标题和按钮
            HStack(alignment: .center) {
                // 侧边栏按钮
                Button(action: {
                    SidebarManager.shared.showSidebar()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemGray5).opacity(0.8))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(UIColor.label))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("  人脉")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // 搜索按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSearchBar.toggle()
                        if !showSearchBar {
                            searchText = ""
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemBlue).opacity(0.1))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: showSearchBar ? "xmark.circle.fill" : "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 添加联系人按钮
                Button(action: {
                    showAddContactSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemBlue).opacity(0.1))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(UIColor.systemBlue))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 使用自定义视图替代复杂的Menu表达式
                MenuButton {
                    viewModeMenuContent
                    Divider()
                    categoryMenuContent
                    sortMenuContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            
            // 第二行：联系人类型筛选器
            VStack(alignment: .leading, spacing: 8) {
               ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // 全部选项
                        FilterChip(title: "全部", isSelected: selectedSegment == 0) {
                            selectedSegment = 0
                        }
                        
                        // 家人选项
                        FilterChip(title: "家人", isSelected: selectedSegment == 1) {
                            selectedSegment = 1
                        }
                        
                        // 挚友选项
                        FilterChip(title: "挚友", isSelected: selectedSegment == 2) {
                            selectedSegment = 2
                        }
                        
                        // 职场选项
                        FilterChip(title: "职场", isSelected: selectedSegment == 3) {
                            selectedSegment = 3
                        }
                        
                        // 榜样选项
                        FilterChip(title: "榜样", isSelected: selectedSegment == 4) {
                            selectedSegment = 4
                        }

                        // 其他选项
                        FilterChip(title: "其他", isSelected: selectedSegment == 5) {
                            selectedSegment = 5
                        }

                        // 有用选项（医生/律师/富人/官员/混混）
                        FilterChip(title: "有用", isSelected: selectedSegment == 6) {
                            selectedSegment = 6
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .safeAreaPadding(.top)
        .background(
            BlurView(style: .systemMaterial)
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
    
    // 联系人类型筛选器
    private var segmentedControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // 全部选项
                    FilterChip(title: "全部", isSelected: selectedSegment == 0) {
                        selectedSegment = 0
                    }
                    
                    // 家人选项
                    FilterChip(title: "家人", isSelected: selectedSegment == 1) {
                        selectedSegment = 1
                    }
                    
                    // 挚友选项
                    FilterChip(title: "挚友", isSelected: selectedSegment == 2) {
                        selectedSegment = 2
                    }
                    
                    // 职场选项
                    FilterChip(title: "职场", isSelected: selectedSegment == 3) {
                        selectedSegment = 3
                    }
                    
                    // 榜样选项
                    FilterChip(title: "榜样", isSelected: selectedSegment == 4) {
                        selectedSegment = 4
                    }

                    // 其他选项
                    FilterChip(title: "其他", isSelected: selectedSegment == 5) {
                        selectedSegment = 5
                    }

                    // 有用选项（医生/律师/富人/官员/混混）
                    FilterChip(title: "有用", isSelected: selectedSegment == 6) {
                        selectedSegment = 6
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    // 搜索栏
    // 顶栏下的搜索区域：包含图标与文本输入
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            // 文本输入框：联系人搜索关键词
            TextField("搜索联系人", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // 联系人列表视图
    private var contactListView: some View {
        ScrollView {
            if filteredContacts.isEmpty {
                LazyVStack(spacing: 12) {
                    emptyStateView
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            } else if viewMode == .gallery {
                GeometryReader { geometry in
                    let columns = 2
                    let spacing: CGFloat = 12
                    let cardWidth = (geometry.size.width - CGFloat(columns + 1) * spacing) / CGFloat(columns)
                    HStack(alignment: .top, spacing: spacing) {
                        // 左列
                        LazyVStack(spacing: spacing) {
                            ForEach(leftColumnItems(filteredContacts), id: \.id) { contact in
                                NavigationLink(destination: ContactDetailView(contact: contact)) {
                                    ContactGalleryCard(contact: contact)
                                        .frame(width: cardWidth)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        // 右列
                        LazyVStack(spacing: spacing) {
                            ForEach(rightColumnItems(filteredContacts), id: \.id) { contact in
                                NavigationLink(destination: ContactDetailView(contact: contact)) {
                                    ContactGalleryCard(contact: contact)
                                        .frame(width: cardWidth)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, spacing)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredContacts, id: \.id) { contact in
                        NavigationLink(destination: ContactDetailView(contact: contact)) {
                            ContactListItem(contact: contact)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }

    // 拆分左右列（参考目标模块的瀑布流样式）
    private func leftColumnItems(_ items: [Contact]) -> [Contact] {
        items.enumerated().compactMap { index, item in
            index % 2 == 0 ? item : nil
        }
    }
    private func rightColumnItems(_ items: [Contact]) -> [Contact] {
        items.enumerated().compactMap { index, item in
            index % 2 == 1 ? item : nil
        }
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(searchText.isEmpty ? "暂无联系人" : "未找到匹配的联系人")
                .font(.title2)
                .foregroundColor(.gray)
            
            if searchText.isEmpty {
                Button("添加第一个联系人") {
                    showAddContactSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    // 视图模式菜单内容
    private var viewModeMenuContent: some View {
        Group {
            Button(action: {
                viewMode = .gallery
            }) {
                Label("卡片视图", systemImage: "square.grid.2x2")
                if viewMode == .gallery {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                viewMode = .list
            }) {
                Label("列表视图", systemImage: "list.bullet")
                if viewMode == .list {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    // 分类菜单内容
    private var categoryMenuContent: some View {
        Menu {
            Button(action: {
                categoryOption = .time
            }) {
                Text("时间")
                if categoryOption == .time {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                categoryOption = .type
            }) {
                Text("类型")
                if categoryOption == .type {
                    Image(systemName: "checkmark")
                }
            }
        } label: {
            Label("分类", systemImage: "folder")
        }
    }
    
    // 排序菜单内容
    private var sortMenuContent: some View {
        Menu {
            Button(action: {
                sortOption = .name
            }) {
                Text("姓名")
                if sortOption == .name {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                sortOption = .createTime
            }) {
                Text("创建时间")
                if sortOption == .createTime {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                sortOption = .modifyTime
            }) {
                Text("修改时间")
                if sortOption == .modifyTime {
                    Image(systemName: "checkmark")
                }
            }
            
            Button(action: {
                sortOption = .visitTime
            }) {
                Text("联系时间")
                if sortOption == .visitTime {
                    Image(systemName: "checkmark")
                }
            }
        } label: {
            Label("排序", systemImage: "arrow.up.arrow.down")
        }
    }
}

// MARK: - 联系人卡片视图
struct ContactCard: View {
    let contact: Contact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头像和基本信息
            HStack(spacing: 12) {
                // 头像
                ZStack {
                    Circle()
                        .fill(Color(contact.importance.color).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if let avatar = contact.avatar {
                        Image(avatar)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Text(String(contact.name.prefix(1)))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(contact.importance.color))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let company = contact.company {
                        Text(company)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let position = contact.position {
                        Text(position)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 联系类型图标
                Image(systemName: contact.contactType.iconName)
                    .font(.title2)
                    .foregroundColor(Color(contact.importance.color))
            }
            
            // 标签（最多显示3行，不滚动）
            if !contact.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(contact.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(TagColorManager.shared.getColor(for: tag))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                // 估算：每行约24pt高度（含间距），3行≈84pt
                .frame(maxHeight: 84)
                .clipped()
            }
            
            // 最后联系时间和提醒状态
            HStack {
                if let lastContact = contact.lastContactDate {
                    Text("最后联系: \(lastContact, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("尚未联系")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if contact.needsContactReminder {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.1), radius: 2, x: 0, y: 2)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

// MARK: - 联系人列表项视图
struct ContactListItem: View {
    let contact: Contact
    
    // 从文档目录加载头像图片（当不在资产库时）
    private func loadAvatarUIImage(_ name: String) -> UIImage? {
        let fm = FileManager.default
        if let doc = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = doc.appendingPathComponent(name)
            if fm.fileExists(atPath: url.path) {
                return UIImage(contentsOfFile: url.path)
            }
        }
        return nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 头像
            ZStack {
                Circle()
                    .fill(Color(contact.importance.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if let avatar = contact.avatar {
                    if let uiImage = UIImage(named: avatar) ?? loadAvatarUIImage(avatar) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Text(String(contact.name.prefix(1)))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(contact.importance.color))
                    }
                } else {
                    Text(String(contact.name.prefix(1)))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(contact.importance.color))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let notes = contact.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: contact.contactType.iconName)
                    .font(.title3)
                    .foregroundColor(Color(contact.importance.color))
                
                if contact.needsContactReminder {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - 画廊卡片（样式对齐主页人脉卡片）
struct ContactGalleryCard: View {
    let contact: Contact
    
    // 从文档目录加载头像图片（当不在资产库时）
    private func loadAvatarUIImage(_ name: String) -> UIImage? {
        let fm = FileManager.default
        if let doc = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = doc.appendingPathComponent(name)
            if fm.fileExists(atPath: url.path) {
                return UIImage(contentsOfFile: url.path)
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            // 头像（圆形，重要程度色为底色）
            ZStack {
                Circle()
                    .fill(Color(contact.importance.color).opacity(0.2))
                    .frame(width: 56, height: 56)
                
                if let avatar = contact.avatar {
                if let uiImage = UIImage(named: avatar) ?? loadAvatarUIImage(avatar) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    Text(String(contact.name.prefix(1)))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(contact.importance.color))
                }
            } else {
                Text(String(contact.name.prefix(1)))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(contact.importance.color))
            }
            }
            
            // 姓名（居中）
            Text(contact.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // 联系人类型（居中，辅助色，无背景）
            Text(contact.contactType.displayName)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // 标签（居中、水平滚动，样式与个人信息一致）
            if !contact.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(contact.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(TagColorManager.shared.getColor(for: tag))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                }
                .frame(height: 34)
            }
            
            // 已移除备注显示：列表与画廊卡片不再展示备注
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.1), radius: 2, x: 0, y: 2)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Contact.self, configurations: config)
    
    ContactView(selectedTab: .constant(3))
        .modelContainer(container)
}
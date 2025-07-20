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
    
    // 绑定到TabView的选中标签
    @Binding var selectedTab: Int
    
    // 分段控制器选择
    @State private var selectedSegment = 0
    
    // 视图模式：画廊视图或列表视图
    @State private var viewMode: ViewMode = .list
    
    // 分类和排序选项
    @State private var categoryOption: CategoryOption = .type
    @State private var sortOption: SortOption = .name
    
    // 添加联系人的状态变量
    @State private var showAddContactSheet = false
    
    // 搜索相关
    @State private var searchText = ""
    @State private var showSearchBar = false
    
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
        let friendContacts = allContacts.filter { $0.contactType == .friend }
        return sortContacts(categorizeContacts(friendContacts))
    }
    
    private var processedWorkContacts: [Contact] {
        let workContacts = allContacts.filter { contact in
            contact.contactType == .colleague || contact.contactType == .business
        }
        return sortContacts(categorizeContacts(workContacts))
    }
    
    private var processedReminderContacts: [Contact] {
        let reminderContacts = allContacts.filter { $0.needsContactReminder }
        return sortContacts(categorizeContacts(reminderContacts))
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
        switch selectedSegment {
        case 0: return processedAllContacts
        case 1: return processedFamilyContacts
        case 2: return processedFriendContacts
        case 3: return processedWorkContacts
        case 4: return processedReminderContacts
        default: return processedAllContacts
        }
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
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部标题栏
                headerView
                
                // 分段控制器
                segmentedControl
                
                // 搜索栏
                if showSearchBar {
                    searchBarView
                }
                
                // 联系人列表
                contactListView
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddContactSheet) {
            AddContactView(isPresented: $showAddContactSheet, selectedSegment: $selectedSegment)
        }
    }
    
    // 顶部标题栏
    private var headerView: some View {
        HStack {
            Text("人脉")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
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
                Image(systemName: showSearchBar ? "xmark.circle.fill" : "magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // 添加联系人按钮
            Button(action: {
                showAddContactSheet = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .buttonStyle(ScaleButtonStyle())
            
            // 菜单按钮
            MenuButton {
                viewModeMenuContent
                Divider()
                categoryMenuContent
                sortMenuContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    // 分段控制器
    private var segmentedControl: some View {
        Picker("联系人类型", selection: $selectedSegment) {
            Text("全部").tag(0)
            Text("家人").tag(1)
            Text("朋友").tag(2)
            Text("工作").tag(3)
            Text("提醒").tag(4)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    // 搜索栏
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
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
            LazyVStack(spacing: 12) {
                if filteredContacts.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredContacts, id: \.id) { contact in
                        NavigationLink(destination: ContactDetailView(contact: contact)) {
                            if viewMode == .gallery {
                                ContactCard(contact: contact)
                            } else {
                                ContactListItem(contact: contact)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
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
            
            // 标签
            if !contact.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(contact.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 1)
                }
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
    
    var body: some View {
        HStack(spacing: 12) {
            // 头像
            ZStack {
                Circle()
                    .fill(Color(contact.importance.color).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if let avatar = contact.avatar {
                    Image(avatar)
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
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let company = contact.company, let position = contact.position {
                    Text("\(position) @ \(company)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let company = contact.company {
                    Text(company)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let position = contact.position {
                    Text(position)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Contact.self, configurations: config)
    
    ContactView(selectedTab: .constant(3))
        .modelContainer(container)
}
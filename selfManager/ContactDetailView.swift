//
//  ContactDetailView.swift
//  selfManager
//
//  Created by AI Assistant on 24.12.25.
//

import SwiftUI
import Foundation
import SwiftData

struct ContactDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode
    
    // 观察TagColorManager的变化以实现即时更新
    @ObservedObject private var tagColorManager = TagColorManager.shared
    // Ping 管理器：用于将联系人固定到主页
    @ObservedObject private var pingManager = PingManager.shared
    
    @Bindable var contact: Contact
    
    // 查询所有未删除的目标
    @Query(filter: #Predicate<Goal> { $0.isDeleted == false },
           sort: \Goal.createTime, order: .reverse) private var allGoals: [Goal]
    
    // 编辑状态
    @State private var showEditSheet = false
    @State private var editingField: EditingField = .name
    @State private var editingValue = ""
    
    // 联系记录
    @State private var showContactLogSheet = false
    // 头像选择弹窗
    @State private var showAvatarPicker = false
    
    // 删除确认
    @State private var showDeleteAlert = false
    
    // 目标选择器
    @State private var showGoalSelector = false
    // 标签添加弹窗
    @State private var showAddTagSheet = false
    
    enum EditingField {
        case name, company, position, phone, email, address, notes, tag
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 头部信息
                headerView
                
                // 标签
                tagsView

                // 联系方式
                contactInfoView
                
                // 备注
                
                // 关联目标
                relatedGoalsView
                
                // 操作按钮
                actionButtonsView
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: { presentationMode.wrappedValue.dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("返回")
                }
            }
        )
        .sheet(isPresented: $showAvatarPicker) {
            ImagePickerView(
                selectedImage: .init(
                    get: { contact.avatar },
                    set: { contact.avatar = $0 }
                ),
                onSelect: { imageName in
                    contact.avatar = imageName
                    contact.modifyTime = Date()
                    try? modelContext.save()
                }
            )
        }
        .sheet(isPresented: $showGoalSelector) {
            GoalMultiSelectorView(contact: contact, allGoals: allGoals)
        }
        .sheet(isPresented: $showAddTagSheet) {
            AddTagSheet(existingEntityTags: contact.tags) { names in
                let existing = Set(contact.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
                let toAdd = names.filter { !existing.contains($0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) }
                guard !toAdd.isEmpty else { return }
                for name in toAdd {
                    contact.tags.append(name)
                }
                contact.modifyTime = Date()
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save tag additions: \(error)")
                }
            }
        }
        .alert("删除联系人", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteContact()
            }
        } message: {
            Text("确定要删除联系人「\(contact.name)」吗？此操作无法撤销。")
        }
    }
    
    // 关联目标视图 - 现代卡片设计
    private var relatedGoalsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 18))
                    .foregroundColor(Color(UIColor.systemRed))
                Text("关联目标")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 添加关联目标按钮
                Button(action: {
                    showGoalSelector = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("添加")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(UIColor.systemRed))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 关联目标内容
            if contact.relatedGoals.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("暂无关联目标")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
                .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
                .cornerRadius(8)
            } else {
                VStack(spacing: 12) {
                    ForEach(contact.relatedGoals) { goal in
                        NavigationLink(destination: GoalDetailView(goal: goal)) {
                            HStack(spacing: 12) {
                                // 目标状态指示器
                                Circle()
                                    .fill(goal.progress >= 1.0 ? Color("Green") : Color("AppBlue"))
                                    .frame(width: 10, height: 10)
                                
                                // 目标名称
                                Text(goal.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                // 目标截止日期
                                if let dueDate = goal.dueDate {
                                    Text(dueDate, style: .date)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // 头部信息 - 现代化设计
    private var headerView: some View {
        ZStack(alignment: .top) {
            // 白卡背景移除固定高度，整体背景由外层提供
            
            // 顶部右侧：Ping/取消Ping 到主页按钮
            HStack {
                Spacer()
                pingButton
            }
            .padding(.top, 10)
            .padding(.trailing, 16)
            
            VStack(spacing: 0) {
                // 头像和基本信息并排布局
                HStack(alignment: .center, spacing: 20) {
                    // 头像
                    ZStack {
                        Circle()
                            .fill(Color("AppBlue").opacity(0.12))
                            .frame(width: 90, height: 90)
                        
                        if let avatar = contact.avatar,
                           let ui = (UIImage(named: avatar) ?? loadAvatarUIImage(avatar)) {
                            Image(uiImage: ui)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 84, height: 84)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                        } else {
                            Text(String(contact.name.prefix(1)))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(Color("AppBlue"))
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Button(action: { showAvatarPicker = true }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.8), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .offset(x: 6, y: 6)
                    }
                    .padding(.leading, 4)
                    
                    // 基本信息（就地编辑，仅姓名）
                    VStack(alignment: .leading, spacing: 8) {
                        TextField(
                            "姓名",
                            text: Binding(
                                get: { contact.name },
                                set: { newValue in
                                    contact.name = newValue
                                    contact.modifyTime = Date()
                                    try? modelContext.save()
                                }
                            )
                        )
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                        // 联系人类型选择器（移动至头像卡片）
                        HStack(spacing: 8) {
                            // 固定为“朋友”icon，蓝色，不随选择变化
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(UIColor.systemBlue))
                                .frame(width: 24, height: 24)
                            Picker("", selection: Binding(get: { contact.contactType }, set: { newValue in
                                contact.contactType = newValue
                                contact.modifyTime = Date()
                                try? modelContext.save()
                            })) {
                                ForEach(ContactType.allCases, id: \.self) { type in
                                    HStack {
                                        Image(systemName: type.iconName)
                                        Text(type.displayName)
                                    }
                                    .tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        HStack(spacing: 12) {
                            // 备注使用灰色“报纸”icon
                            Image(systemName: "newspaper.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(UIColor.systemGray))
                                .frame(width: 24, height: 24)
                            TextField("备注", text: optionalBinding(\.notes))
                                .autocapitalization(.none)
                        }
                    }
                    .padding(.trailing, 8)
                    
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // 顶部 Ping/取消Ping 按钮
    private var pingButton: some View {
        let isPinned = pingManager.isPinged(contactID: contact.id)
        return Button(action: {
            if isPinned {
                pingManager.unping(contactID: contact.id)
            } else {
                pingManager.ping(contactID: contact.id)
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(isPinned ? "取消Ping" : "Ping到主页")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundColor(Color(UIColor.systemBlue))
            .background(Color(UIColor.systemBlue).opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 联系方式 - 现代卡片设计
    private var contactInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(UIColor.systemRed))
                Text("联系方式")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                // 快速操作按钮（统一样式）
                HStack(spacing: 8) {
                    if let phone = contact.phone, !phone.isEmpty {
                        Button(action: {
                            if let url = URL(string: "tel:\(phone)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 28, height: 28)
                                .foregroundColor(Color(UIColor.systemBlue))
                                .background(Color(UIColor.systemBlue).opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if let email = contact.email, !email.isEmpty {
                        Button(action: {
                            if let url = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 28, height: 28)
                                .foregroundColor(Color(UIColor.systemBlue))
                                .background(Color(UIColor.systemBlue).opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // 联系信息（就地编辑）
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.systemBlue))
                        .frame(width: 24, height: 24)
                    TextField("电话", text: optionalBinding(\.phone))
                        .keyboardType(.phonePad)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.systemBlue))
                        .frame(width: 24, height: 24)
                    TextField("邮箱", text: optionalBinding(\.email))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.systemBlue))
                        .frame(width: 24, height: 24)
                    TextField("地址", text: optionalBinding(\.address))
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 分类信息 - 现代卡片设计
    private var categoryInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分类信息")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // 使用卡片式设计展示分类信息
            HStack(spacing: 16) {
                // 联系类型卡片（就地编辑）
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // 固定为“朋友”icon，蓝色
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(UIColor.systemBlue))
                        Text("联系人类型")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Picker("", selection: Binding(get: { contact.contactType }, set: { newValue in
                        contact.contactType = newValue
                        contact.modifyTime = Date()
                        try? modelContext.save()
                    })) {
                        ForEach(ContactType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                Text(type.displayName)
                            }.tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color("AppBlue").opacity(0.05))
                .cornerRadius(12)

                // 联系频率卡片（就地编辑）
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16))
                            .foregroundColor(Color(UIColor.systemRed))
                        Text("联系频率")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Picker("", selection: Binding(get: { contact.frequency }, set: { newValue in
                        contact.frequency = newValue
                        contact.modifyTime = Date()
                        try? modelContext.save()
                    })) {
                        ForEach(ContactFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color("Purple").opacity(0.05))
                .cornerRadius(12)
                
                // 重要程度卡片（就地编辑）
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(UIColor.systemRed))
                        Text("重要程度")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Picker("", selection: Binding(get: { contact.importance }, set: { newValue in
                        contact.importance = newValue
                        contact.modifyTime = Date()
                        try? modelContext.save()
                    })) {
                        ForEach(ContactImportance.allCases, id: \.self) { importance in
                            Text(importance.displayName).tag(importance)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(contact.importance.color).opacity(0.05))
                .cornerRadius(12)

                // 备注编辑区（整合到头像卡片）
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 18))
                            .foregroundColor(Color(UIColor.systemBlue))
                        Text("备注")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    TextEditor(text: optionalBinding(\.notes))
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .onChange(of: contact.notes ?? "") { _ in
                            contact.modifyTime = Date()
                            try? modelContext.save()
                        }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 标签 - 现代设计
    // 标签视图 - 支持直接编辑
    private var tagsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(UIColor.systemRed))
                Text("标签")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // 标签内容
            if contact.tags.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Button(action: { showAddTagSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("添加标签")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundColor(Color(UIColor.systemRed))
                            .background(Color(UIColor.systemRed).opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Text("暂无标签")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
                .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
                .cornerRadius(8)
            } else {
                // 使用流式布局展示标签 - 参考目标详情页的实现
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(contact.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .foregroundColor(.white)
                                
                                // 删除标签按钮
                                Button(action: {
                                    // 删除标签
                                    if let index = contact.tags.firstIndex(of: tag) {
                                        contact.tags.remove(at: index)
                                        // 更新修改时间
                                        contact.modifyTime = Date()
                                        // 保存更改
                                        do {
                                            try modelContext.save()
                                        } catch {
                                            print("Failed to save tag deletion: \(error)")
                                        }
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(tagColor(for: tag))
                            .cornerRadius(12)
                        }
                        
                        // 添加标签按钮 - 打开可复用的标签添加弹窗
                        Button(action: {
                            showAddTagSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12))
                                .foregroundColor(Color(UIColor.systemRed))
                                .frame(width: 24, height: 24)
                                .background(Color(UIColor.systemRed).opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .frame(height: 40)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // 为标签生成一致的颜色 - 使用TagColorManager
    private func tagColor(for tag: String) -> Color {
        return TagColorManager.shared.getColor(for: tag)
    }
    
    // 联系记录 - 现代卡片设计
    private var contactHistoryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                Text("联系记录")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showContactLogSheet = true
                }) {
                    HStack(spacing: 4) {
                        Text("查看全部")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color("AppBlue"))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 联系时间卡片
            HStack(spacing: 16) {
                // 上次联系卡片
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16))
                            .foregroundColor(Color("Teal"))
                        Text("最后联系")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastContact = contact.lastContactDate {
                        Text(lastContact, formatter: dateFormatter)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    } else {
                        Text("尚未联系")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color("Teal").opacity(0.05))
                .cornerRadius(12)
                
                // 下次联系卡片
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(Color("AppBlue"))
                        Text("下次联系")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if let nextContact = contact.nextContactDate {
                        HStack(spacing: 4) {
                            Text(nextContact, formatter: dateFormatter)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(contact.needsContactReminder ? Color("Red") : .primary)
                            
                            if contact.needsContactReminder {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("Red"))
                            }
                        }
                    } else {
                        Text("未设置")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color("AppBlue").opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 已移除：备注卡片已整合到头像卡片
    
    // 操作按钮 - 现代设计
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            if let address = contact.address, !address.isEmpty {
                Button(action: {
                    let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    guard let url = URL(string: "https://maps.apple.com/?q=\(encodedAddress)") else { return }
                    UIApplication.shared.open(url)
                }) {
                    HStack {
                        Image(systemName: "map.fill")
                            .font(.system(size: 18))
                        Text("导航地址")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("Purple"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            Button(action: {
                showDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                    Text("删除联系人")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color("Red"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private func deleteContact() {
        contact.moveToTrash()
        try? modelContext.save()
        presentationMode.wrappedValue.dismiss()
    }

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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    // 可选字符串字段的绑定助手：将nil映射为空串，保存修改
    private func optionalBinding(_ keyPath: ReferenceWritableKeyPath<Contact, String?>) -> Binding<String> {
        Binding<String>(
            get: { contact[keyPath: keyPath] ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                contact[keyPath: keyPath] = trimmed.isEmpty ? nil : trimmed
                contact.modifyTime = Date()
                try? modelContext.save()
            }
        )
    }
}

// MARK: - 联系信息行
struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.systemRed))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 编辑联系人视图
struct EditContactView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var contact: Contact
    
    @State private var name: String
    @State private var company: String
    @State private var position: String
    @State private var phone: String
    @State private var email: String
    @State private var address: String
    @State private var notes: String
    @State private var selectedContactType: ContactType
    @State private var selectedImportance: ContactImportance
    @State private var selectedFrequency: ContactFrequency
    @State private var tags: String
    @State private var newTag: String = ""
    @State private var isExample: Bool
    
    init(contact: Contact) {
        self.contact = contact
        self._name = State(initialValue: contact.name)
        self._company = State(initialValue: contact.company ?? "")
        self._position = State(initialValue: contact.position ?? "")
        self._phone = State(initialValue: contact.phone ?? "")
        self._email = State(initialValue: contact.email ?? "")
        self._address = State(initialValue: contact.address ?? "")
        self._notes = State(initialValue: contact.notes ?? "")
        self._selectedContactType = State(initialValue: contact.contactType)
        self._selectedImportance = State(initialValue: contact.importance)
        self._selectedFrequency = State(initialValue: contact.frequency)
        self._tags = State(initialValue: contact.tags.joined(separator: ", "))
        self._isExample = State(initialValue: contact.isExample)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("姓名", text: $name)
                    TextField("公司", text: $company)
                    TextField("职位", text: $position)
                }
                
                Section(header: Text("联系方式")) {
                    TextField("电话", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("邮箱", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("地址", text: $address)
                }
                
                Section(header: Text("分类信息")) {
                    Picker("联系人类型", selection: $selectedContactType) {
                        ForEach(ContactType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    
                    Picker("重要程度", selection: $selectedImportance) {
                        ForEach(ContactImportance.allCases, id: \.self) { importance in
                            Text(importance.displayName).tag(importance)
                        }
                    }
                    
                    Picker("联系频率", selection: $selectedFrequency) {
                        ForEach(ContactFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                }
                
                Section(header: Text("其他信息")) {
                    TextField("标签 (用逗号分隔)", text: $tags)
                    TextField("备注", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Toggle("设为榜样联系人", isOn: $isExample)
                }
            }
            .navigationBarTitle("编辑联系人", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveChanges()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func saveChanges() {
        contact.name = name
        contact.company = company.isEmpty ? nil : company
        contact.position = position.isEmpty ? nil : position
        contact.phone = phone.isEmpty ? nil : phone
        contact.email = email.isEmpty ? nil : email
        contact.address = address.isEmpty ? nil : address
        contact.notes = notes.isEmpty ? nil : notes
        contact.contactType = selectedContactType
        contact.importance = selectedImportance
        contact.frequency = selectedFrequency
        contact.tags = tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }.filter { !$0.isEmpty }
        contact.isExample = isExample
        contact.modifyTime = Date()
        
        // 重新计算下次联系时间
        if let lastDate = contact.lastContactDate {
            contact.nextContactDate = contact.calculateNextContactDate()
        }
        
        try? modelContext.save()
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 联系记录视图
struct ContactLogView: View {
    @Environment(\.presentationMode) var presentationMode
    let contact: Contact
    
    var body: some View {
        NavigationView {
            VStack {
                Text("联系记录功能")
                    .font(.title2)
                    .padding()
                
                Text("此功能可以记录与\(contact.name)的联系历史")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitle("联系记录", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - FlowLayout 流式布局组件
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, containerWidth: proposal.width ?? 0)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var rowY: CGFloat = bounds.minY
        var rowX: CGFloat = bounds.minX
        var rowHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            
            // 如果当前行放不下这个元素，换行
            if rowX + size.width > bounds.maxX && rowX > bounds.minX {
                rowY += rowHeight + spacing
                rowX = bounds.minX
                rowHeight = 0
            }
            
            // 放置元素
            subview.place(at: CGPoint(x: rowX, y: rowY), proposal: ProposedViewSize(size))
            
            // 更新位置和行高
            rowX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
    
    private func layout(sizes: [CGSize], containerWidth: CGFloat) -> CGSize {
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for size in sizes {
            // 如果当前行放不下这个元素，换行
            if rowWidth + size.width > containerWidth && rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += size.width + (rowWidth > 0 ? spacing : 0)
                rowHeight = max(rowHeight, size.height)
            }
        }
        
        // 添加最后一行的高度
        if rowHeight > 0 {
            totalHeight += rowHeight
        }
        
        return CGSize(width: containerWidth, height: totalHeight)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Contact.self, configurations: config)
    
    let sampleContact = Contact(
        name: "张三",
        company: "示例公司",
        position: "产品经理",
        phone: "13800138000",
        email: "zhangsan@example.com",
        contactType: .workplace,
        importance: .high,
        frequency: .monthly
    )
    
    ContactDetailView(contact: sampleContact)
        .modelContainer(container)
}
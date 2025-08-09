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
    
    @Bindable var contact: Contact
    
    // 编辑状态
    @State private var showEditSheet = false
    @State private var editingField: EditingField = .name
    @State private var editingValue = ""
    
    // 联系记录
    @State private var showContactLogSheet = false
    
    // 删除确认
    @State private var showDeleteAlert = false
    
    enum EditingField {
        case name, company, position, phone, email, address, notes, tag
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 头部信息
                headerView
                
                // 联系方式
                contactInfoView
                
                // 分类信息
                categoryInfoView
                
                // 标签
                tagsView
                
                // 联系记录
                contactHistoryView
                
                // 备注
                notesView
                
                // 操作按钮
                actionButtonsView
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .navigationBarTitle(contact.name, displayMode: .large)
        .navigationBarItems(
            trailing: Menu {
                Button("编辑联系人") {
                    showEditSheet = true
                }
                
                Button("删除联系人", role: .destructive) {
                    showDeleteAlert = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
            }
        )
        .sheet(isPresented: $showEditSheet) {
            EditContactView(contact: contact)
        }
        .sheet(isPresented: $showContactLogSheet) {
            ContactLogView(contact: contact)
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
    
    // 头部信息 - 现代化设计
    private var headerView: some View {
        ZStack(alignment: .top) {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(contact.importance.color).opacity(0.2),
                    Color(UIColor.systemBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(spacing: 0) {
                // 头像和基本信息并排布局
                HStack(alignment: .center, spacing: 20) {
                    // 头像
                    ZStack {
                        Circle()
                            .fill(Color(contact.importance.color).opacity(0.3))
                            .frame(width: 90, height: 90)
                            .shadow(color: Color(contact.importance.color).opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        if let avatar = contact.avatar {
                            Image(avatar)
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
                                .foregroundColor(Color(contact.importance.color))
                        }
                    }
                    .padding(.leading, 4)
                    
                    // 基本信息
                    VStack(alignment: .leading, spacing: 6) {
                        Text(contact.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let company = contact.company, let position = contact.position {
                            Text("\(position) @ \(company)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else if let company = contact.company {
                            Text(company)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else if let position = contact.position {
                            Text(position)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer().frame(height: 4)
                        
                        // 联系类型和重要程度 - 使用标签样式
                        HStack(spacing: 8) {
                            // 联系类型标签
                            HStack(spacing: 4) {
                                Image(systemName: contact.contactType.iconName)
                                    .font(.system(size: 12))
                                Text(contact.contactType.displayName)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(contact.importance.color).opacity(0.1))
                            .foregroundColor(Color(contact.importance.color))
                            .cornerRadius(8)
                            
                            // 重要程度标签
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                Text(contact.importance.displayName)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(contact.importance.color).opacity(0.1))
                            .foregroundColor(Color(contact.importance.color))
                            .cornerRadius(8)
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
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    // 联系方式 - 现代卡片设计
    private var contactInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                Text("联系方式")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 快速操作按钮
                if let phone = contact.phone, !phone.isEmpty {
                    Button(action: {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "phone.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 4)
                }
                
                if let email = contact.email, !email.isEmpty {
                    Button(action: {
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color("Colors/Blue"))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 4)
                }
            }
            
            // 联系信息列表
            VStack(spacing: 16) {
                if let phone = contact.phone, !phone.isEmpty {
                    ContactInfoRow(icon: "phone.fill", title: "电话", value: phone) {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if let email = contact.email, !email.isEmpty {
                    ContactInfoRow(icon: "envelope.fill", title: "邮箱", value: email) {
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if let address = contact.address, !address.isEmpty {
                    ContactInfoRow(icon: "location.fill", title: "地址", value: address) {
                        // 可以添加地图导航功能
                        if let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: "https://maps.apple.com/?q=\(encodedAddress)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if (contact.phone == nil || contact.phone?.isEmpty == true) &&
                   (contact.email == nil || contact.email?.isEmpty == true) &&
                   (contact.address == nil || contact.address?.isEmpty == true) {
                    HStack {
                        Spacer()
                        Text("暂无联系方式")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // 分类信息 - 现代卡片设计
    private var categoryInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分类信息")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // 使用卡片式设计展示分类信息
            HStack(spacing: 16) {
                // 联系频率卡片
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16))
                            .foregroundColor(Color("Colors/Purple"))
                        Text("联系频率")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(contact.frequency.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color("Colors/Purple").opacity(0.05))
                .cornerRadius(12)
                
                // 重要程度卡片
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(contact.importance.color))
                        Text("重要程度")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(contact.importance.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(contact.importance.color))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(contact.importance.color).opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // 标签 - 现代设计
    private var tagsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                Text("标签")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 编辑标签按钮
                Button(action: {
                    editingField = .tag
                    editingValue = contact.tags.joined(separator: ", ")
                    showEditSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("Colors/Blue"))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 标签内容
            if contact.tags.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tag")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("暂无标签")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                // 使用流式布局展示标签
                FlowLayout(spacing: 8) {
                    ForEach(contact.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(tagColor(for: tag).opacity(0.1))
                            .foregroundColor(tagColor(for: tag))
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // 为标签生成一致的颜色
    private func tagColor(for tag: String) -> Color {
        let colors: [Color] = [Color("Colors/Blue"), Color("Colors/Green"), Color("Colors/Orange"), Color("Colors/Purple"), Color("Colors/Pink"), Color("Colors/Teal")]
        let index = abs(tag.hashValue) % colors.count
        return colors[index]
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
                    .foregroundColor(Color("Colors/Blue"))
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
                            .foregroundColor(Color("Colors/Teal"))
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
                .background(Color("Colors/Teal").opacity(0.05))
                .cornerRadius(12)
                
                // 下次联系卡片
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(Color("Colors/Blue"))
                        Text("下次联系")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if let nextContact = contact.nextContactDate {
                        HStack(spacing: 4) {
                            Text(nextContact, formatter: dateFormatter)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(contact.needsContactReminder ? Color("Colors/Red") : .primary)
                            
                            if contact.needsContactReminder {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("Colors/Red"))
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
                .background(Color("Colors/Blue").opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // 备注 - 现代卡片设计
    private var notesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                Text("备注")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 编辑备注按钮
                Button(action: {
                    editingField = .notes
                    editingValue = contact.notes ?? ""
                    showEditSheet = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18))
                        .foregroundColor(Color("Colors/Blue"))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 备注内容
            if let notes = contact.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 16))
                    .lineSpacing(4)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("暂无备注")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
                .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // 操作按钮 - 现代设计
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            // 标记为已联系按钮
            Button(action: {
                contact.updateLastContactDate()
                try? modelContext.save()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("标记为已联系")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color("Colors/Green"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 联系方式快捷操作
            HStack(spacing: 16) {
                if let phone = contact.phone, !phone.isEmpty {
                    Button(action: {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 18))
                            Text("拨打电话")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("Colors/Blue"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let email = contact.email, !email.isEmpty {
                    Button(action: {
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18))
                            Text("发送邮件")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("Colors/Orange"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
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
                        .background(Color("Colors/Purple"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private func deleteContact() {
        modelContext.delete(contact)
        try? modelContext.save()
        presentationMode.wrappedValue.dismiss()
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
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
                    .font(.title3)
                    .foregroundColor(Color("Colors/Blue"))
                    .frame(width: 24)
                
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
        contactType: .colleague,
        importance: .high,
        frequency: .monthly
    )
    
    ContactDetailView(contact: sampleContact)
        .modelContainer(container)
}
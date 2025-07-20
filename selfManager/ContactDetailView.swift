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
    
    // 头部信息
    private var headerView: some View {
        VStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(Color(contact.importance.color).opacity(0.2))
                    .frame(width: 100, height: 100)
                
                if let avatar = contact.avatar {
                    Image(avatar)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Text(String(contact.name.prefix(1)))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color(contact.importance.color))
                }
            }
            
            // 基本信息
            VStack(spacing: 8) {
                Text(contact.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                if let company = contact.company, let position = contact.position {
                    Text("\(position) @ \(company)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else if let company = contact.company {
                    Text(company)
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else if let position = contact.position {
                    Text(position)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // 联系类型和重要程度
                HStack(spacing: 16) {
                    Label(contact.contactType.displayName, systemImage: contact.contactType.iconName)
                        .font(.subheadline)
                        .foregroundColor(Color(contact.importance.color))
                    
                    Label(contact.importance.displayName, systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundColor(Color(contact.importance.color))
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // 联系方式
    private var contactInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("联系方式")
                .font(.headline)
                .padding(.bottom, 4)
            
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
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.1), radius: 2, x: 0, y: 2)
    }
    
    // 分类信息
    private var categoryInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类信息")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("联系频率")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(contact.frequency.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("重要程度")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(contact.importance.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color(contact.importance.color))
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.1), radius: 2, x: 0, y: 2)
    }
    
    // 标签
    private var tagsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("标签")
                .font(.headline)
            
            if contact.tags.isEmpty {
                Text("暂无标签")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(contact.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.1), radius: 2, x: 0, y: 2)
    }
    
    // 联系记录
    private var contactHistoryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("联系记录")
                    .font(.headline)
                
                Spacer()
                
                Button("查看全部") {
                    showContactLogSheet = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if let lastContact = contact.lastContactDate {
                    HStack {
                        Text("最后联系:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(lastContact, formatter: dateFormatter)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                } else {
                    Text("尚未联系")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let nextContact = contact.nextContactDate {
                    HStack {
                        Text("下次联系:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(nextContact, formatter: dateFormatter)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(contact.needsContactReminder ? .red : .primary)
                        Spacer()
                        
                        if contact.needsContactReminder {
                            Image(systemName: "bell.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.1), radius: 2, x: 0, y: 2)
    }
    
    // 备注
    private var notesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("备注")
                .font(.headline)
            
            if let notes = contact.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundColor(.primary)
            } else {
                Text("暂无备注")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.1), radius: 2, x: 0, y: 2)
    }
    
    // 操作按钮
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                contact.updateLastContactDate()
                try? modelContext.save()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("标记为已联系")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            HStack(spacing: 12) {
                if let phone = contact.phone, !phone.isEmpty {
                    Button(action: {
                        if let url = URL(string: "tel:\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("拨打电话")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                if let email = contact.email, !email.isEmpty {
                    Button(action: {
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("发送邮件")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
        }
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
                    .foregroundColor(.blue)
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
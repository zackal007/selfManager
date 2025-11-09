//
//  AddContactView.swift
//  selfManager
//
//  Created by AI Assistant on 24.12.25.
//

import SwiftUI
import Foundation
import SwiftData

// 添加联系人的表单视图
struct AddContactView: View {
    @Binding var isPresented: Bool
    @Binding var selectedSegment: Int
    @Environment(\.modelContext) private var modelContext
    
    // 表单字段
    @State private var name = ""
    @State private var company = ""
    @State private var position = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""
    @State private var notes = ""
    @State private var selectedContactType: ContactType = .other
    @State private var selectedImportance: ContactImportance = .medium
    @State private var selectedFrequency: ContactFrequency = .monthly
    @State private var tags = ""
    @State private var hasLastContactDate = false
    @State private var lastContactDate = Date()
    
    // 错误处理
    @State private var showAlert = false
    @State private var errorMessage = ""
    
    // 成功提示
    @State private var showSuccessToast = false
    @State private var successMessage = ""
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        formFieldsSection
                        Spacer(minLength: 100)
                    }
                }
                // 点击非输入区域时收起键盘，不影响布局
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }
                .background(Color(UIColor.systemBackground))
                .navigationBarTitle("添加联系人", displayMode: .inline)
                .navigationBarItems(
                    leading: cancelButton,
                    trailing: saveButton
                )
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("提示"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("确定"))
                    )
                }
            }
            
            successToast
        }
    }

    // MARK: - 键盘控制
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 24) {
            // 图标
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "person.fill.badge.plus")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 32)
        }
    }
    
    // MARK: - Form Fields Section
    private var formFieldsSection: some View {
        VStack(spacing: 16) {
            // 仅保留：姓名、分类（横向列表）、备注
            nameField
            contactTypeHorizontalField
            notesField
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Basic Info Fields
    private var basicInfoFields: some View {
        VStack(spacing: 16) {
            nameField
            companyField
            positionField
        }
    }
    
    // MARK: - Category Field (Horizontal)
    private var contactTypeHorizontalField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分类")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ContactType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedContactType = type
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: type.iconName)
                                    .font(.system(size: 12))
                                Text(type.displayName)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(selectedContactType == type ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedContactType == type ? Color.blue : Color(UIColor.systemGray5))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Contact Info Fields
    private var contactInfoFields: some View {
        VStack(spacing: 16) {
            phoneField
            emailField
            addressField
        }
    }
    
    // MARK: - Additional Fields
    private var additionalFields: some View {
        VStack(spacing: 16) {
            notesField
        }
    }
    
    // MARK: - Individual Field Views
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("姓名")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("请输入姓名", text: $name)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(name.isEmpty ? Color.clear : Color.blue, lineWidth: 2)
                        )
                )
        }
    }
    
    private var companyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("公司")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("请输入公司名称", text: $company)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(company.isEmpty ? Color.clear : Color.blue.opacity(0.6), lineWidth: company.isEmpty ? 0 : 2)
                        )
                )
        }
    }
    
    private var positionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("职位")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("请输入职位", text: $position)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(position.isEmpty ? Color.clear : Color.blue.opacity(0.6), lineWidth: position.isEmpty ? 0 : 2)
                        )
                )
        }
    }
    
    private var contactTypeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("分类")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Menu {
                ForEach(ContactType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedContactType = type
                    }) {
                        HStack {
                            Image(systemName: type.iconName)
                            Text(type.displayName)
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedContactType.iconName)
                        .foregroundColor(.blue)
                    Text(selectedContactType.displayName)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                )
            }
        }
    }
    
    private var importanceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("重要性")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Menu {
                ForEach(ContactImportance.allCases, id: \.self) { importance in
                    Button(action: {
                        selectedImportance = importance
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text(importance.displayName)
                            if selectedImportance == importance {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.blue)
                    Text(selectedImportance.displayName)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
    
    private var frequencyField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("联系频率")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Menu {
                ForEach(ContactFrequency.allCases, id: \.self) { frequency in
                    Button(action: {
                        selectedFrequency = frequency
                    }) {
                        HStack {
                            Image(systemName: "clock")
                            Text(frequency.displayName)
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text(selectedFrequency.displayName)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                )
            }
        }
    }
    
    private var tagsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标签")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("请输入标签，用逗号分隔", text: $tags)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tags.isEmpty ? Color.clear : Color.blue.opacity(0.6), lineWidth: tags.isEmpty ? 0 : 2)
                        )
                )
        }
    }
    
    private var lastContactDateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("最后联系日期")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: $hasLastContactDate)
                    .labelsHidden()
            }
            
            if hasLastContactDate {
                DatePicker("选择日期", selection: $lastContactDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemGray6))
                    )
            }
        }
    }
    
    private var phoneField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("电话")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("请输入电话号码", text: $phone)
                .font(.system(size: 16))
                .keyboardType(.phonePad)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(phone.isEmpty ? Color.clear : Color.blue.opacity(0.6), lineWidth: phone.isEmpty ? 0 : 2)
                        )
                )
        }
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("邮箱")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("请输入邮箱地址", text: $email)
                .font(.system(size: 16))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(email.isEmpty ? Color.clear : Color.blue.opacity(0.6), lineWidth: email.isEmpty ? 0 : 2)
                        )
                )
        }
    }
    
    private var addressField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("地址")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("请输入地址", text: $address)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(address.isEmpty ? Color.clear : Color.blue.opacity(0.6), lineWidth: address.isEmpty ? 0 : 2)
                        )
                )
        }
    }
    
    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("备注（可选）")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("请输入备注信息", text: $notes, axis: .vertical)
                .font(.system(size: 16))
                .lineLimit(3...6)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(notes.isEmpty ? Color.clear : Color.blue.opacity(0.6), lineWidth: notes.isEmpty ? 0 : 2)
                        )
                )
        }
    }
    
    // MARK: - Toolbar Buttons
    private var cancelButton: some View {
        Button(action: {
            isPresented = false
        }) {
            HStack(spacing: 4) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                Text("取消")
                    .font(.system(size: 17, weight: .medium))
            }
            .foregroundColor(Color(UIColor.systemBlue))
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            validateAndSaveContact()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                Text("保存")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(
                        name.isEmpty ? 
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor.systemBlue),
                                Color(UIColor.systemBlue).opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .disabled(name.isEmpty)
    }
    
    // MARK: - Success Toast
    private var successToast: some View {
        Group {
            if showSuccessToast {
                VStack {
                    Spacer()
                    ToastView(message: successMessage, isSuccess: true)
                        .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: showSuccessToast)
                .zIndex(1)
            }
        }
    }
    
    private func validateAndSaveContact() {
        // 验证输入
        if name.isEmpty {
            errorMessage = "姓名不能为空"
            showAlert = true
            return
        }
        
        if name.count < 2 {
            errorMessage = "姓名至少需要2个字符"
            showAlert = true
            return
        }
        
        // 验证邮箱格式（如果填写了邮箱）
        if !email.isEmpty && !isValidEmail(email) {
            errorMessage = "请输入有效的邮箱地址"
            showAlert = true
            return
        }
        
        // 验证通过，保存联系人
        saveContact()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func saveContact() {
        // 创建新联系人
        let newContact = Contact(
            name: name,
            company: company.isEmpty ? nil : company,
            position: position.isEmpty ? nil : position,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            address: address.isEmpty ? nil : address,
            notes: notes.isEmpty ? nil : notes,
            contactType: selectedContactType,
            importance: selectedImportance,
            frequency: selectedFrequency,
            tags: [],
            lastContactDate: nil
        )
        
        // 保存到数据库
        modelContext.insert(newContact)
        
        do {
            try modelContext.save()
            
            // 根据新联系人的类型切换分段
            switch newContact.contactType {
            case .family:
                selectedSegment = 1
            case .intimateFriend:
                selectedSegment = 2
            case .workplace:
                selectedSegment = 3
            case .roleModel:
                selectedSegment = 4
            case .other:
                selectedSegment = 5
            case .doctor, .lawyer, .rich, .official, .gangster:
                selectedSegment = 6
            }
            
            // 显示成功提示
            successMessage = "联系人「\(name)」添加成功！"
            showSuccessToast = true
            
            // 延迟1.5秒后关闭表单，让用户有时间看到成功提示
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                isPresented = false
            }
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            showAlert = true
        }
    }
}



#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Contact.self, configurations: config)
    
    AddContactView(isPresented: .constant(true), selectedSegment: .constant(0))
        .modelContainer(container)
}
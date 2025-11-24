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
                .navigationBarTitle("add_contact".localized, displayMode: .inline)
                .navigationBarItems(
                    leading: cancelButton,
                    trailing: saveButton
                )
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("alert_info_title".localized),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("ok".localized))
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
            Text("category".localized)
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
                                Text(localizedContactTypeName(type))
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
            Text("name_label".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("name_placeholder".localized, text: $name)
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
            Text("company".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("company_placeholder".localized, text: $company)
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
            Text("position".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("position_placeholder".localized, text: $position)
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
            Text("category".localized)
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
            Text("importance".localized)
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
            Text("contact_frequency".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Menu {
                ForEach(ContactFrequency.allCases, id: \.self) { frequency in
                    Button(action: {
                        selectedFrequency = frequency
                    }) {
                        HStack {
                            Image(systemName: "clock")
                            Text(localizedFrequencyName(frequency))
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
            Text("tags".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("search_or_create_tag_placeholder".localized, text: $tags)
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
                Text("last_contact".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: $hasLastContactDate)
                    .labelsHidden()
            }
            
            if hasLastContactDate {
                DatePicker("", selection: $lastContactDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .environment(\.locale, LocalizationManager.shared.currentLanguage.locale)
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
            Text("phone".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("phone".localized, text: $phone)
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
            Text("email".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("email".localized, text: $email)
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
            Text("address".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("address".localized, text: $address)
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
            Text("description_optional".localized)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            TextField("note_placeholder".localized, text: $notes, axis: .vertical)
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

    private func localizedContactTypeName(_ type: ContactType) -> String {
        switch type {
        case .family: return "contacts_family".localized
        case .intimateFriend: return "contacts_friend".localized
        case .workplace: return "contacts_work".localized
        case .roleModel: return "contacts_role_model".localized
        case .doctor: return "contacts_doctor".localized
        case .lawyer: return "contacts_lawyer".localized
        case .rich: return "contacts_rich".localized
        case .official: return "contacts_official".localized
        case .gangster: return "contacts_gangster".localized
        case .other: return "contacts_other".localized
        }
    }

    private func localizedFrequencyName(_ frequency: ContactFrequency) -> String {
        switch frequency {
        case .daily: return "frequency_daily".localized
        case .weekly: return "frequency_weekly".localized
        case .monthly: return "frequency_monthly".localized
        case .quarterly: return "frequency_quarterly".localized
        case .yearly: return "frequency_yearly".localized
        case .occasional: return "frequency_occasional".localized
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
                Text("cancel".localized)
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
                Text("save".localized)
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
            errorMessage = "name_empty".localized
            showAlert = true
            return
        }
        
        if name.count < 2 {
            errorMessage = "name_min_length".localized
            showAlert = true
            return
        }
        
        // 验证邮箱格式（如果填写了邮箱）
        if !email.isEmpty && !isValidEmail(email) {
            errorMessage = "invalid_email".localized
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
            
            // 直接关闭表单，不显示成功提示
            isPresented = false
        } catch {
            errorMessage = "save_failed".localized + ": \(error.localizedDescription)"
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
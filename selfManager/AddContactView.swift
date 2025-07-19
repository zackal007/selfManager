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
                Form {
                    Section(header: Text("基本信息")) {
                        TextField("姓名", text: $name)
                            .overlay(
                                name.isEmpty ? 
                                Text("姓名不能为空").foregroundColor(.red).font(.caption) : nil,
                                alignment: .trailing
                            )
                        
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
                        
                        Toggle("设置最后联系时间", isOn: $hasLastContactDate)
                        
                        if hasLastContactDate {
                            DatePicker("最后联系时间", selection: $lastContactDate, displayedComponents: [.date])
                        }
                        
                        TextField("备注", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                .navigationBarTitle("添加联系人", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("取消") {
                        isPresented = false
                    },
                    trailing: Button("保存") {
                        validateAndSaveContact()
                    }
                    .disabled(name.isEmpty)
                )
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("提示"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("确定"))
                    )
                }
            }
            
            // 成功提示Toast
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
            tags: tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }.filter { !$0.isEmpty },
            lastContactDate: hasLastContactDate ? lastContactDate : nil
        )
        
        // 如果设置了最后联系时间，计算下次联系时间
        if hasLastContactDate {
            newContact.updateLastContactDate(lastContactDate)
        }
        
        // 保存到数据库
        modelContext.insert(newContact)
        
        do {
            try modelContext.save()
            
            // 根据新联系人的类型切换分段
            switch newContact.contactType {
            case .family:
                selectedSegment = 1
            case .friend:
                selectedSegment = 2
            case .colleague, .business:
                selectedSegment = 3
            default:
                selectedSegment = 0
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
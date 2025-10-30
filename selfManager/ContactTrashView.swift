//
//  ContactTrashView.swift
//  selfManager
//
//  Created by AI Assistant on 2024.12.27.
//

import SwiftUI
import SwiftData

struct ContactTrashView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 查询已删除的联系人
    @Query(filter: #Predicate<Contact> { $0.isDeleted == true }, 
           sort: \Contact.deletedDate, order: .reverse) 
    private var deletedContacts: [Contact]
    
    @State private var showingRestoreAlert = false
    @State private var showingPermanentDeleteAlert = false
    @State private var selectedContact: Contact?
    @State private var showingEmptyTrashAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
            if deletedContacts.isEmpty {
                // 空状态
                VStack(spacing: 20) {
                    Image(systemName: "trash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("回收站为空")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("删除的联系人会在这里保留\(getTrashExpirationDays())天")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 联系人列表
                List {
                    ForEach(deletedContacts) { contact in
                        TrashContactRow(contact: contact) {
                            selectedContact = contact
                            showingRestoreAlert = true
                        } onPermanentDelete: {
                            selectedContact = contact
                            showingPermanentDeleteAlert = true
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("回收站")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("关闭") {
                    dismiss()
                }
            }
            
            if !deletedContacts.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清空回收站") {
                        showingEmptyTrashAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .alert("恢复联系人", isPresented: $showingRestoreAlert) {
            Button("取消", role: .cancel) { }
            Button("恢复") {
                if let contact = selectedContact {
                    restoreContact(contact)
                }
            }
        } message: {
            Text("确定要恢复联系人「\(selectedContact?.name ?? "")」吗？")
        }
        .alert("永久删除", isPresented: $showingPermanentDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let contact = selectedContact {
                    permanentlyDeleteContact(contact)
                }
            }
        } message: {
            Text("确定要永久删除联系人「\(selectedContact?.name ?? "")」吗？此操作无法撤销。")
        }
        .alert("清空回收站", isPresented: $showingEmptyTrashAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                emptyTrash()
            }
        } message: {
            Text("确定要清空回收站吗？这将永久删除所有已删除的联系人，此操作无法撤销。")
        }
        }
    }
    
    private func restoreContact(_ contact: Contact) {
        contact.restoreFromTrash()
        
        do {
            try modelContext.save()
        } catch {
            print("恢复联系人失败: \(error)")
        }
    }
    
    private func permanentlyDeleteContact(_ contact: Contact) {
        modelContext.delete(contact)
        
        do {
            try modelContext.save()
        } catch {
            print("永久删除联系人失败: \(error)")
        }
    }
    
    private func emptyTrash() {
        for contact in deletedContacts {
            modelContext.delete(contact)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("清空回收站失败: \(error)")
        }
    }
    
    // 获取用户设置的回收站过期天数
    private func getTrashExpirationDays() -> Int {
        return TrashCleanupService.shared.getUserTrashExpirationDays(modelContext: modelContext)
    }
}

struct TrashContactRow: View {
    @Environment(\.modelContext) private var modelContext
    let contact: Contact
    let onRestore: () -> Void
    let onPermanentDelete: () -> Void
    
    private var deletedTimeText: String {
        guard let deletedDate = contact.deletedDate else { return "" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "删除于 " + formatter.localizedString(for: deletedDate, relativeTo: Date())
    }
    
    private var daysUntilPermanentDeletion: Int {
        guard let deletedDate = contact.deletedDate else { return 0 }
        
        // 获取用户设置的过期天数
        let expirationDays = TrashCleanupService.shared.getUserTrashExpirationDays(modelContext: modelContext)
        
        let calendar = Calendar.current
        let daysSinceDeletion = calendar.dateComponents([.day], from: deletedDate, to: Date()).day ?? 0
        let daysRemaining = expirationDays - daysSinceDeletion
        return max(0, daysRemaining)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 联系人信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // 联系人类型标签
                    Text(contact.contactType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                
                // 公司和职位
                if let company = contact.company, !company.isEmpty {
                    Text(company)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let position = contact.position, !position.isEmpty {
                    Text(position)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // 删除时间和剩余天数
                VStack(alignment: .leading, spacing: 2) {
                    Text(deletedTimeText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if daysUntilPermanentDeletion > 0 {
                        Text("\(daysUntilPermanentDeletion)天后永久删除")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("即将永久删除")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: onRestore) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("恢复")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Button(action: onPermanentDelete) {
                    HStack {
                        Image(systemName: "trash")
                        Text("永久删除")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
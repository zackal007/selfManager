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
    
    enum ActiveAlert: Identifiable {
        case restore
        case permanentDelete
        case emptyTrash
        var id: Int {
            switch self {
            case .restore: return 1
            case .permanentDelete: return 2
            case .emptyTrash: return 3
            }
        }
    }
    @State private var activeAlert: ActiveAlert?
    @State private var selectedContact: Contact?
    
    var body: some View {
        NavigationView {
            VStack {
            if deletedContacts.isEmpty {
                // 空状态
                VStack(spacing: 20) {
                    Image(systemName: "trash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("trash_empty_title".localized)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("deleted_contacts_keep_days_prefix".localized + String(getTrashExpirationDays()) + "days_unit".localized)
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
                            activeAlert = .restore
                        } onPermanentDelete: {
                            selectedContact = contact
                            activeAlert = .permanentDelete
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("recycle_bin".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("close".localized) {
                    dismiss()
                }
            }
            
            if !deletedContacts.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("empty_trash".localized) {
                        activeAlert = .emptyTrash
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .restore:
                return Alert(
                    title: Text("restore_contact".localized),
                    message: Text("restore_contact_confirm_before".localized + (selectedContact?.name ?? "") + "restore_contact_confirm_after".localized),
                    primaryButton: .cancel(Text("cancel".localized)),
                    secondaryButton: .default(Text("restore".localized), action: {
                        if let contact = selectedContact {
                            restoreContact(contact)
                        }
                        selectedContact = nil
                        activeAlert = nil
                    })
                )
            case .permanentDelete:
                return Alert(
                    title: Text("permanent_delete".localized),
                    message: Text("permanent_delete_contact_confirm_before".localized + (selectedContact?.name ?? "") + "permanent_delete_contact_confirm_after".localized),
                    primaryButton: .cancel(Text("cancel".localized)),
                    secondaryButton: .destructive(Text("delete".localized), action: {
                        if let contact = selectedContact {
                            permanentlyDeleteContact(contact)
                        }
                        selectedContact = nil
                        activeAlert = nil
                    })
                )
            case .emptyTrash:
                return Alert(
                    title: Text("empty_trash".localized),
                    message: Text("empty_trash_confirm_contact".localized),
                    primaryButton: .cancel(Text("cancel".localized)),
                    secondaryButton: .destructive(Text("clear".localized), action: {
                        emptyTrash()
                        selectedContact = nil
                        activeAlert = nil
                    })
                )
            }
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
        return "deleted_on_prefix".localized + formatter.localizedString(for: deletedDate, relativeTo: Date())
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
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.label))
                    
                    // 联系人类型标签
                    Text(contact.contactType.displayName)
                        .font(.system(size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.systemBlue).opacity(0.1))
                        .cornerRadius(DesignToken.cornerRadiusSmall)
                }
                
                // 公司和职位
                if let company = contact.company, !company.isEmpty {
                    Text(company)
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(1)
                }
                
                if let position = contact.position, !position.isEmpty {
                    Text(position)
                        .font(.system(size: 14))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(1)
                }
                
                // 删除时间和剩余天数
                VStack(alignment: .leading, spacing: 2) {
                    if daysUntilPermanentDeletion > 0 {
                        Text("days_until_permanent_delete_prefix".localized + String(daysUntilPermanentDeletion) + "days_unit".localized)
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.systemOrange))
                    } else {
                        Text("immediate_permanent_delete".localized)
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor.systemRed))
                    }
                }
            }
            
            // 操作按钮
            HStack(spacing: 12) {
                Button(action: onRestore) {
                    Text("恢复")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.systemBlue))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.systemBlue).opacity(0.1))
                    .cornerRadius(DesignToken.cornerRadiusSmall)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onPermanentDelete) {
                    Text("永久删除")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor.systemRed))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(UIColor.systemRed).opacity(0.1))
                    .cornerRadius(DesignToken.cornerRadiusSmall)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(DesignToken.cornerRadiusMedium)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
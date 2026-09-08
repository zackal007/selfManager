import SwiftUI
import Foundation

struct ContactSelectorView: View {
    let allContacts: [Contact]
    @State var selectedIds: [UUID]
    var onSelect: ([UUID]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return allContacts
        } else {
            return allContacts.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText) ||
                (contact.company?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (contact.position?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("search_contacts_placeholder".localized, text: $searchText)
                        .padding(8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(DesignToken.cornerRadiusSmall)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // 已选联系人
                if !selectedIds.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("selected_contacts".localized)
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedIds, id: \.self) { id in
                                    if let contact = allContacts.first(where: { $0.id == id }) {
                                        HStack(spacing: 4) {
                                            Text(contact.name)
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(UIColor.systemBlue))
                                            Button(action: {
                                                if let idx = selectedIds.firstIndex(of: id) {
                                                    selectedIds.remove(at: idx)
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color(UIColor.systemGray3))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color(UIColor.systemBlue).opacity(0.1))
                                        .cornerRadius(DesignToken.cornerRadiusMedium)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 8)
                    }
                    .background(Color(UIColor.systemGray6).opacity(0.5))
                }
                
                // 联系人列表
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredContacts, id: \.id) { contact in
                            MultipleSelectionRow(
                                contact: contact,
                                isSelected: selectedIds.contains(contact.id)
                            ) {
                                if let idx = selectedIds.firstIndex(of: contact.id) {
                                    selectedIds.remove(at: idx)
                                } else {
                                    selectedIds.append(contact.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            
                            if contact.id != filteredContacts.last?.id {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("choose_contact".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("cancel".localized) {
                    dismiss()
                },
                trailing: Button(action: {
                    onSelect(selectedIds)
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("add".localized)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.blue.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                }
                .disabled(selectedIds.isEmpty)
                .opacity(selectedIds.isEmpty ? 0.6 : 1.0)
            )
        }
    }
}

struct MultipleSelectionRow: View {
    let contact: Contact
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 联系人信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    if let company = contact.company, !company.isEmpty {
                        Text(company)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 选择指示器
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(UIColor.systemBlue))
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color(UIColor.systemGray3))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
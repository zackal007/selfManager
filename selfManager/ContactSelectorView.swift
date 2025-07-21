import SwiftUI
import Foundation

struct ContactSelectorView: View {
    let allContacts: [Contact]
    @State var selectedIds: [UUID]
    var onSelect: ([UUID]) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(allContacts, id: \.id) { contact in
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
                }
            }
            .navigationTitle("选择联系人")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("完成") {
                    onSelect(selectedIds)
                    presentationMode.wrappedValue.dismiss()
                }
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
            HStack {
                Text(contact.name)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
import SwiftUI
import SwiftData

struct UserEditView: View {
    @Bindable var user: User
    @Environment(\.dismiss) private var dismiss
    @State private var showAddTagField = false
    @State private var newTag = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("用户名", text: $user.name)
                    TextField("头像 (Emoji 或图像名)", text: $user.avatar)
                    TextField("描述", text: $user.userDescription)
                }
                
                Section(header: Text("标签")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(user.tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .foregroundColor(Color(UIColor.systemBlue))
                                    Button(action: {
                                        if let index = user.tags.firstIndex(of: tag) {
                                            user.tags.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(UIColor.systemGray3))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(UIColor.systemBlue).opacity(0.1))
                                .cornerRadius(12)
                            }
                            Button(action: {
                                showAddTagField = true
                                newTag = ""
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(UIColor.systemBlue))
                                    .frame(width: 24, height: 24)
                                    .background(Color(UIColor.systemBlue).opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    if showAddTagField {
                        HStack {
                            TextField("新标签", text: $newTag)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("添加") {
                                let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty && !user.tags.contains(trimmed) {
                                    user.tags.append(trimmed)
                                }
                                showAddTagField = false
                                newTag = ""
                            }
                        }
                    }
                }
            }
            .navigationTitle("编辑用户信息")
            .navigationBarItems(leading: Button("取消") { dismiss() }, trailing: Button("保存") { dismiss() })
        }
    }
}
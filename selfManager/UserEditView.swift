import SwiftUI
import SwiftData

struct UserEditView: View {
    @Bindable var user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("用户名", text: $user.name)
                    TextField("头像 (Emoji 或图像名)", text: $user.avatar)
                    TextField("描述", text: $user.userDescription)
                }
                
                Section(header: Text("标签")) {
                    List {
                        ForEach($user.tags.indices, id: \.self) { index in
                            TextField("标签", text: $user.tags[index])
                        }
                        .onDelete { indices in
                            user.tags.remove(atOffsets: indices)
                        }
                    }
                    
                    Button("添加标签") {
                        user.tags.append("")
                    }
                }
            }
            .navigationTitle("编辑用户信息")
            .navigationBarItems(leading: Button("取消") { dismiss() }, trailing: Button("保存") { dismiss() })
        }
    }
}
import SwiftData
import SwiftUI
import PhotosUI

struct UserEditView: View {
    @Bindable var user: User
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showAddTagField = false
    @State private var newTag = ""
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("我的信息")) {
                    HStack {
                        Text("用户名:")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("请输入用户名", text: $user.name)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("头像:")
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        PhotosPicker(selection: $avatarItem, matching: .images) {
                            (avatarImage ?? Image(systemName: "person.circle.fill"))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .foregroundColor(avatarImage == nil ? .gray : .primary)
                        }
                    }
                    
                    HStack {
                        Text("个人描述:")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("请输入个人描述", text: $user.userDescription)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("标签")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(user.tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .foregroundColor(.white)
                                    Button(action: {
                                        if let index = user.tags.firstIndex(of: tag) {
                                            user.tags.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(TagColorManager.shared.getColor(for: tag))
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
                                    
                                    // 创建或更新Tag对象
                                    // 注意：这里需要获取modelContext，但UserEditView没有直接访问
                                    // 我们需要添加Environment变量
                                }
                                showAddTagField = false
                                newTag = ""
                            }
                        }
                    }
                }
                

            }
            .navigationTitle("我的信息")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("取消") { dismiss() }, trailing: Button("保存") { dismiss() })
            .onChange(of: avatarItem) { oldItem, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            avatarImage = Image(uiImage: uiImage)
                            // 将图片保存到本地，并更新user.avatar
                            if let imageUrl = ImageUtility.saveImageToAppDirectory(image: uiImage, fileName: "user_avatar.png") {
                                user.avatar = imageUrl.lastPathComponent
                            }
                        }
                    }
                }
            }
            .onAppear {
                // 加载已保存的头像
                if !user.avatar.isEmpty {
                    if let uiImage = ImageUtility.loadImageFromAppDirectory(fileName: user.avatar) {
                        avatarImage = Image(uiImage: uiImage)
                    } else {
                        // 如果文件不存在或加载失败，显示默认头像
                        avatarImage = nil // Set to nil to show default PhotosPicker content
                    }
                } else {
                    // 如果没有头像，显示默认头像
                    avatarImage = nil // Set to nil to show default PhotosPicker content
                }
            }
        }
    }
}
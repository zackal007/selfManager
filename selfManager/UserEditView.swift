import SwiftData
import SwiftUI
import PhotosUI

struct UserEditView: View {
    @Bindable var user: User
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Record.createTime, order: .reverse) private var records: [Record]
    @State private var showAddTagSheet = false
    @State private var showAddTagField = false
    @State private var newTag = ""
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    
    private var latestDailyMoods: [String] {
        let moods = records
            .filter { $0.recordType == .daily && ($0.mood?.isEmpty == false) }
            .prefix(3)
            .compactMap { $0.mood }
        return Array(moods)
    }
    
    var body: some View {
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
                                showAddTagSheet = true
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
                }

                if !latestDailyMoods.isEmpty {
                    Section(header: Text("最近心情")) {
                        HStack(spacing: 8) {
                            ForEach(latestDailyMoods.indices, id: \.self) { i in
                                Text(latestDailyMoods[i])
                                    .font(.system(size: 24))
                                    .frame(width: 44, height: 44)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color(UIColor.label).opacity(0.06), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                
                Section(header: Text("自定义信息"), footer: Text("可添加任意名称-信息键值对。主页将于 2×2 信息卡片中部分显示，超出内容自动隐藏。")) {
                    VStack(spacing: 8) {
                        ForEach(user.customInfos, id: \.id) { info in
                            HStack(spacing: 8) {
                                TextField("名称", text: Binding(
                                    get: { info.key },
                                    set: { newKey in
                                        var arr = user.customInfos
                                        if let idx = arr.firstIndex(where: { $0.id == info.id }) {
                                            arr[idx].key = newKey
                                            user.customInfos = arr
                                        }
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)

                                TextField("信息", text: Binding(
                                    get: { info.value },
                                    set: { newVal in
                                        var arr = user.customInfos
                                        if let idx = arr.firstIndex(where: { $0.id == info.id }) {
                                            arr[idx].value = newVal
                                            user.customInfos = arr
                                        }
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)

                                Button(action: {
                                    var arr = user.customInfos
                                    if let idx = arr.firstIndex(where: { $0.id == info.id }) {
                                        arr.remove(at: idx)
                                        user.customInfos = arr
                                        try? modelContext.save()
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(Color(UIColor.systemRed))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        Button(action: {
                            var arr = user.customInfos
                            arr.append(UserCustomInfo(key: "", value: ""))
                            user.customInfos = arr
                        }) {
                            Label("添加字段", systemImage: "plus")
                                .foregroundColor(Color(UIColor.systemBlue))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                }
        }
        .navigationTitle("我的信息")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("返回")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    // 保存更改
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showAddTagSheet) {
                AddTagSheet(existingEntityTags: user.tags) { names in
                    let existing = Set(user.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
                    let toAdd = names.filter { !existing.contains($0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) }
                    guard !toAdd.isEmpty else { return }
                    for name in toAdd {
                        user.tags.append(name)
                    }
                    do {
                        try modelContext.save()
                    } catch {
                        print("Failed to save user tag additions: \(error)")
                    }
                }
        }
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
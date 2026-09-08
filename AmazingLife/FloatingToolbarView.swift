//
//  FloatingToolbarView.swift
//  selfManager
//
//  工具栏视图，整合添加图片、字数统计和心情选择功能
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct FloatingToolbarView: View {
    // 文本内容绑定
    @Binding var text: String
    
    // 图片相关
    @Binding var images: [Data]
    @State private var showImagePicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    // 心情选择（仅在日记模式下显示）
    @Binding var selectedMood: String?
    let showMoodSelector: Bool
    
    // 目标和联系人数据
    let goals: [Goal]
    let contacts: [Contact]
    
    // 下拉菜单状态
    @State private var showGoalSelector = false
    @State private var showContactSelector = false
    
    // 回调
    var onImagesChanged: (([Data]) -> Void)?
    var onMoodChanged: ((String?) -> Void)?
    
    // 键盘状态
    @FocusState var isTextFieldFocused: Bool
    @FocusState var isTextEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 主要工具栏
            HStack(spacing: 12) {
                // 添加图片按钮（仅图标）
                Button(action: {
                    dismissKeyboard()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showImagePicker = true
                    }
                }) {
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("添加图片")
                .accessibilityHint("双击添加照片到记录")

                // 心情选择按钮（仅图标，仅在日记模式下显示）
                if showMoodSelector {
                    Menu {
                        // 清除心情选项
                        Button("no_mood".localized) {
                            selectedMood = nil
                            onMoodChanged?(nil)
                        }

                        // 心情选项
                        ForEach(["😊", "😢", "😡", "😴", "🤔", "😎"], id: \.self) { mood in
                            Button {
                                selectedMood = mood
                                onMoodChanged?(mood)
                            } label: {
                                Label(mood, systemImage: selectedMood == mood ? "checkmark" : "")
                            }
                        }
                    } label: {
                        if let mood = selectedMood {
                            Text(mood)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(16)
                        } else {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.accentColor)
                                .frame(width: 32, height: 32)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(16)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("选择心情")
                    .accessibilityHint("双击选择今天的心情")
                }

                // 目标引用按钮（#）
                Menu {
                    // 清除目标引用选项
                    Button("clear_goal_reference".localized) {
                        insertGoalReference(nil)
                    }
                    
                    // 目标选项
                    ForEach(goals.filter { !$0.isDeleted }, id: \.id) { goal in
                        Button {
                            insertGoalReference(goal)
                        } label: {
                            Label(goal.name, systemImage: "target")
                        }
                    }
                } label: {
                    Text("#")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("关联目标")
                .accessibilityHint("双击选择要关联的目标")

                // 人脉引用按钮（@）
                Menu {
                    // 清除人脉引用选项
                    Button("clear_contact_reference".localized) {
                        insertContactReference(nil)
                    }

                    // 联系人选项
                    ForEach(contacts, id: \.id) { contact in
                        Button {
                            insertContactReference(contact)
                        } label: {
                            Label(contact.name, systemImage: "person")
                        }
                    }
                } label: {
                    Text("@")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("关联人脉")
                .accessibilityHint("双击选择要关联的联系人")
                
                Spacer()
                
                // 字数统计（本地化）
                HStack(spacing: 4) {
                    Image(systemName: "text.alignleft")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "character_count_format".localized, text.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotos, maxSelectionCount: 9, matching: .images)
        .onChange(of: selectedPhotos) { newValue in
            loadSelectedPhotos(newValue)
        }
    }
    
    // 图片缩略图视图
    private func imageThumbnailView(imageData: Data, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            }
            
            // 删除按钮
            Button(action: {
                withAnimation(.appSnappy) {
                    images.remove(at: index)
                    onImagesChanged?(images)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .offset(x: 4, y: -4)
        }
    }
    
    // 收起键盘
    private func dismissKeyboard() {
        isTextFieldFocused = false
        isTextEditorFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // 插入目标引用
    private func insertGoalReference(_ goal: Goal?) {
        if let goal = goal {
            let goalReference = "#\(goal.name) "
            text += goalReference
        }
    }
    
    // 插入联系人引用
    private func insertContactReference(_ contact: Contact?) {
        if let contact = contact {
            let contactReference = "@\(contact.name) "
            text += contactReference
        }
    }
    
    // 加载选择的图片
    private func loadSelectedPhotos(_ oldPhotos: [PhotosPickerItem]) {
        Task {
            var newImages: [Data] = []
            
            for photo in selectedPhotos {
                if let data = try? await photo.loadTransferable(type: Data.self) {
                    newImages.append(data)
                }
            }
            
            await MainActor.run {
                withAnimation(.appSnappy) {
                    images.append(contentsOf: newImages)
                    onImagesChanged?(images)
                }
                selectedPhotos.removeAll()
            }
        }
    }
}

// 自定义圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// 预览
struct FloatingToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            
            FloatingToolbarView(
                text: .constant("这是一个示例文本，用于测试悬浮工具栏的功能。"),
                images: .constant([]),
                selectedMood: .constant("😊"),
                showMoodSelector: true,
                goals: [],
                contacts: [],
                onImagesChanged: { _ in },
                onMoodChanged: { _ in }
            )
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
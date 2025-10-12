//
//  FloatingToolbarView.swift
//  selfManager
//
//  悬浮工具栏视图，整合添加图片、字数统计和心情选择功能
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
    
    // 回调
    var onImagesChanged: (([Data]) -> Void)?
    var onMoodChanged: ((String?) -> Void)?
    
    // 键盘状态
    @FocusState var isTextFieldFocused: Bool
    @FocusState var isTextEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 主要工具栏
            HStack(spacing: 16) {
                // 添加图片按钮
                Button(action: {
                    dismissKeyboard()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showImagePicker = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.system(size: 16, weight: .medium))
                        Text("图片")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // 心情选择按钮（仅在日记模式下显示）
                if showMoodSelector {
                    Menu {
                        // 清除心情选项
                        Button("无心情") {
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
                        HStack(spacing: 6) {
                            if let mood = selectedMood {
                                Text(mood)
                                    .font(.system(size: 16))
                            } else {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            Text("心情")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                
                Spacer()
                
                // 字数统计
                HStack(spacing: 4) {
                    Image(systemName: "text.alignleft")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(text.count) 字")
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
            
            // 图片预览（如果有图片的话）
            if !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, imageData in
                            imageThumbnailView(imageData: imageData, index: index)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
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
                withAnimation(.easeInOut(duration: 0.3)) {
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
                withAnimation(.easeInOut(duration: 0.3)) {
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
                onImagesChanged: { _ in },
                onMoodChanged: { _ in }
            )
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
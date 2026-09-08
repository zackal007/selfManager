//
//  NotesStyleRecordEditor.swift
//  selfManager
//
//  Created by AI Assistant on 24.12.25.
//

import SwiftUI
import PhotosUI
import UIKit

// 苹果备忘录风格的记录编辑器
struct NotesStyleRecordEditor: View {
    @Binding var text: String
    @Binding var images: [Data]
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showImagePicker = false
    @State private var isTextEditorFocused = false
    @FocusState private var isTextFieldFocused: Bool
    
    let minHeight: CGFloat
    let onImagesChanged: (([Data]) -> Void)?
    let onTextChanged: (() -> Void)?
    
    init(
        text: Binding<String>,
        images: Binding<[Data]> = .constant([]),
        minHeight: CGFloat = 120,
        onImagesChanged: (([Data]) -> Void)? = nil,
        onTextChanged: (() -> Void)? = nil
    ) {
        self._text = text
        self._images = images
        self.minHeight = minHeight
        self.onImagesChanged = onImagesChanged
        self.onTextChanged = onTextChanged
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 文本编辑区域 - 使用Flexible填充可用空间
            textEditorView
                .layoutPriority(1)
            
            // 图片展示区域
            if !images.isEmpty {
                imageGalleryView
            }
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle()) // 确保整个区域可以响应点击
        .onTapGesture {
            // 点击编辑器外部区域时收起键盘
            dismissKeyboard()
        }
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedPhotos,
            maxSelectionCount: 10,
            matching: .images
        )
        .onChange(of: selectedPhotos) { _, newPhotos in
            loadSelectedPhotos(newPhotos)
        }
        .onChange(of: text) { _, _ in
            onTextChanged?()
        }
        .onChange(of: isTextFieldFocused) { _, newValue in
            isTextEditorFocused = newValue
            // 当焦点状态改变时，如果失去焦点则收起键盘
            if !newValue {
                dismissKeyboard()
            }
        }
    }
    
    // MARK: - 键盘收起方法
    private func dismissKeyboard() {
        if isTextFieldFocused {
            isTextFieldFocused = false
        }
        isTextEditorFocused = false
        
        // 强制收起键盘
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - 文本编辑器视图
    private var textEditorView: some View {
        let lineHeight = UIFont.preferredFont(forTextStyle: .body).lineHeight + 4 // 与 .lineSpacing(4) 对齐
        let desiredMinHeight = max(minHeight, lineHeight * 12) // 显示约 12 行文本高度

        return ZStack(alignment: .topLeading) {
            HiddenIndicatorTextView(text: $text)
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    isTextEditorFocused = true
                }
                .simultaneousGesture(
                    TapGesture().onEnded { _ in }
                )

            
            
            
            if text.isEmpty {
                Text("record_editor_placeholder".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: desiredMinHeight, maxHeight: .infinity)
    }
    
    // MARK: - 图片展示区域
    private var imageGalleryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("图片 (\(images.count))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("全部删除") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        images.removeAll()
                        onImagesChanged?(images)
                    }
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            // 图片网格
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, imageData in
                    imageItemView(imageData: imageData, index: index)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(DesignToken.cornerRadiusTertiary)
        .simultaneousGesture(
            // 防止点击图片区域时触发外部的onTapGesture
            TapGesture().onEnded { _ in
                // 点击图片区域时收起键盘
                dismissKeyboard()
            }
        )
    }
    
    // MARK: - 单个图片项视图
    private func imageItemView(imageData: Data, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            // 图片
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(DesignToken.cornerRadiusTertiary)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
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
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .offset(x: 8, y: -8)
        }
    }
    

    
    // MARK: - 辅助方法
    private func loadSelectedPhotos(_ photos: [PhotosPickerItem]) {
        Task {
            var newImages: [Data] = []
            
            for photo in photos {
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

private struct HiddenIndicatorTextView: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextView {
        let v = UITextView()
        v.text = text
        v.font = UIFont.preferredFont(forTextStyle: .body)
        v.isScrollEnabled = true
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.backgroundColor = UIColor.systemGroupedBackground
        v.layer.cornerRadius = 12
        v.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        v.delegate = context.coordinator
        v.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return v
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        init(text: Binding<String>) { self.text = text }
        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }
}

// MARK: - 预览
#Preview {
    VStack {
        NotesStyleRecordEditor(
            text: .constant("这是一个示例文本，展示苹果备忘录风格的编辑器界面。\n\n支持多行文本编辑和图片上传功能。"),
            images: .constant([]),
            minHeight: 200
        ) { images in
            print("图片已更新: \(images.count) 张")
        }
        
        Spacer()
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
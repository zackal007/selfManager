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
        minHeight: CGFloat = 200,
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
            // 文本编辑区域
            textEditorView
            
            // 图片展示区域
            if !images.isEmpty {
                imageGalleryView
            }
            
            // 底部工具栏
            toolbarView
        }
        .contentShape(Rectangle()) // 确保整个区域可以响应点击
        .onTapGesture {
            // 点击编辑器外部区域时收起键盘
            if isTextFieldFocused {
                isTextFieldFocused = false
                isTextEditorFocused = false
                // 隐藏键盘
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
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
        }
    }
    
    // MARK: - 文本编辑器视图
    private var textEditorView: some View {
        ZStack(alignment: .topLeading) {
            // 文本编辑器
            TextEditor(text: $text)
                .focused($isTextFieldFocused)
                .padding(12)
                .font(.body)
                .lineSpacing(4)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isTextEditorFocused ? Color.accentColor : Color.clear,
                            lineWidth: 2
                        )
                )
                .onTapGesture {
                    // 点击文本编辑器时获取焦点
                    isTextFieldFocused = true
                    isTextEditorFocused = true
                }
                .simultaneousGesture(
                    // 防止点击TextEditor时触发外部的onTapGesture
                    TapGesture().onEnded { _ in
                        // 空实现，用于阻止事件冒泡
                    }
                )
            
            // 占位符文本
            if text.isEmpty {
                Text("记录你的想法...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: minHeight)
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
        .cornerRadius(8)
        .simultaneousGesture(
            // 防止点击图片区域时触发外部的onTapGesture
            TapGesture().onEnded { _ in
                // 点击图片区域时收起键盘
                if isTextFieldFocused {
                    isTextFieldFocused = false
                    isTextEditorFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
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
                    .cornerRadius(8)
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
    
    // MARK: - 底部工具栏
    private var toolbarView: some View {
        HStack(spacing: 20) {
            // 添加图片按钮
            Button(action: {
                // 点击添加图片按钮时先收起键盘
                if isTextFieldFocused {
                    isTextFieldFocused = false
                    isTextEditorFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                showImagePicker = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .medium))
                    Text("添加图片")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            // 字数统计
            Text("\(text.count) 字")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
        .simultaneousGesture(
            // 防止点击工具栏时触发外部的onTapGesture
            TapGesture().onEnded { _ in
                // 点击工具栏区域时收起键盘
                if isTextFieldFocused {
                    isTextFieldFocused = false
                    isTextEditorFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        )
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
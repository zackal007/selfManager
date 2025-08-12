//
//  ImagePickerView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import PhotosUI

let USER_UPLOADED_IMAGES_KEY = "UserUploadedImages"

struct ImagePickerView: View {
    @Binding var selectedImage: String?
    var onSelect: (String?) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    // 预设的背景图片
    private let presetImages = ["GoalBackground", "GoalBackground2"]
    
    // 用于从相册选择图片
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var isLoading = false
    @State private var userUploadedImages: [String] = []
    @State private var showDeleteConfirmation = false
    @State private var imageToDelete: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 预设图片选择区域
                VStack(alignment: .leading, spacing: 10) {
                    Text("预设背景")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            // 默认选项（无背景图片）
                            Button(action: {
                                selectedImage = nil
                                onSelect(nil)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                ZStack {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .frame(width: 120, height: 90)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedImage == nil ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                    
                                    Text("默认渐变")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // 预设图片选项
                            ForEach(presetImages, id: \.self) { imageName in
                                Button(action: {
                                    selectedImage = imageName
                                    onSelect(imageName)
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    if let uiImage = UIImage(named: imageName) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 90)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedImage == imageName ? Color.blue : Color.clear, lineWidth: 3)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                Divider()
                
                // 自定义图片选择区域
                VStack(alignment: .leading, spacing: 10) {
                    Text("自定义背景")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // 从相册选择图片
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 18))
                                Text("从相册选择")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        .onChange(of: selectedPhotoItem) { newItem in
                            if let newItem = newItem {
                                isLoading = true
                                loadTransferable(from: newItem)
                            }
                        }
                    
                    // 显示选择的图片预览
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if let selectedUIImage = selectedUIImage {
                        VStack {
                            Image(uiImage: selectedUIImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .cornerRadius(10)
                                .padding(.horizontal)
                            
                            // 使用选择的图片按钮
                            Button(action: {
                                // 保存图片到应用目录并更新模型
                                if let imageName = saveImageToDocuments(selectedUIImage) {
                                    selectedImage = imageName
                                    onSelect(imageName)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                Text("使用此图片")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.green)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
                
                // 最近上传的图片区域
                if !userUploadedImages.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("最近上传")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(userUploadedImages, id: \.self) { imageName in
                                    Button(action: {
                                        selectedImage = imageName
                                        onSelect(imageName)
                                        presentationMode.wrappedValue.dismiss()
                                    }) {
                                        ZStack(alignment: .topTrailing) {
                                            if let uiImage = loadImageFromDocuments(imageName) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 120, height: 90)
                                                    .cornerRadius(10)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(selectedImage == imageName ? Color.blue : Color.clear, lineWidth: 3)
                                                    )
                                                
                                                // 删除按钮
                                                Button(action: {
                                                    imageToDelete = imageName
                                                    showDeleteConfirmation = true
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                        .padding(5)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                Spacer()
            }
            .navigationBarTitle("选择背景图片", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                loadUserUploadedImages()
            }
            .alert("确认删除", isPresented: $showDeleteConfirmation) {
                Button("删除", role: .destructive) {
                    if let imageName = imageToDelete {
                        deleteUploadedImage(imageName)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要删除这张图片吗？此操作无法撤销。")
            }
        }
    }
    
    // 从 PhotosPickerItem 加载图片
    private func loadTransferable(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let data):
                    if let data = data, let uiImage = UIImage(data: data) {
                        self.selectedUIImage = uiImage
                    }
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
            }
        }
    }
    
    // 保存图片到应用文档目录
    private func saveImageToDocuments(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        
        let fileName = "goal_bg_\(UUID().uuidString).jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            
            // 保存到上传历史
            var uploadedImages = UserDefaults.standard.stringArray(forKey: USER_UPLOADED_IMAGES_KEY) ?? []
            uploadedImages.insert(fileName, at: 0) // 新图片放在最前面
            
            // 限制保存的历史记录数量，最多保存10张
            if uploadedImages.count > 10 {
                let imageToRemove = uploadedImages.removeLast()
                // 删除多余的图片文件
                try? FileManager.default.removeItem(at: getDocumentsDirectory().appendingPathComponent(imageToRemove))
            }
            
            UserDefaults.standard.set(uploadedImages, forKey: USER_UPLOADED_IMAGES_KEY)
            userUploadedImages = uploadedImages // 更新当前视图的状态
            
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    // 加载用户上传的图片列表
    private func loadUserUploadedImages() {
        userUploadedImages = UserDefaults.standard.stringArray(forKey: USER_UPLOADED_IMAGES_KEY) ?? []
    }
    
    // 从文档目录加载图片
    private func loadImageFromDocuments(_ fileName: String) -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // 删除上传的图片
    private func deleteUploadedImage(_ fileName: String) {
        // 从文件系统删除
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
        
        // 从历史记录中删除
        var uploadedImages = UserDefaults.standard.stringArray(forKey: USER_UPLOADED_IMAGES_KEY) ?? []
        uploadedImages.removeAll { $0 == fileName }
        UserDefaults.standard.set(uploadedImages, forKey: USER_UPLOADED_IMAGES_KEY)
        
        // 更新当前视图的状态
        userUploadedImages = uploadedImages
    }
    
    // 获取应用文档目录
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

#Preview {
    ImagePickerView(selectedImage: .constant(nil), onSelect: { _ in })
}
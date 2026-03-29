//
//  ImagePickerView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import PhotosUI

let USER_UPLOADED_IMAGES_KEY = "UserUploadedImages"
let USER_HIDDEN_IMAGES_KEY = "UserHiddenImages"

struct ImagePickerView: View {
    @Binding var selectedImage: String?
    var onSelect: (String?) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    // 预设的背景图片
    private let presetImages = ["GoalBackground", "GoalBackground2", "GoalBackground3", "GoalBackground4", "GoalBackground5", "GoalBackground6"]
    
    // 用于从相册选择图片
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var isLoading = false
    @State private var userUploadedImages: [String] = []
    @State private var hiddenImages: [String] = []
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
                
                // 最近上传的图片区域
                VStack(alignment: .leading, spacing: 10) {
                    Text("最近上传")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if userUploadedImages.isEmpty {
                        // 无上传图片时显示提示信息
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                                .padding(.top, 10)
                            
                            Text("暂无上传图片")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                
                            Text("您可以在下方上传自定义背景图")
                                .font(.system(size: 12))
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.bottom, 10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    } else {
                        // 有上传图片时显示图片列表
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
                }
                .padding(.vertical)
                
                Divider()
                
                // 自定义图片选择区域
                VStack(alignment: .leading, spacing: 10) {
                    Text("自定义背景")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // 从相册选择图片
                    if selectedUIImage == nil {
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
                    }
                    
                    // 显示选择的图片预览
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if let selectedUIImage = selectedUIImage {
                        VStack {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedUIImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                
                                // 取消上传按钮
                                Button(action: {
                                    self.selectedUIImage = nil
                                    self.selectedPhotoItem = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .padding([.top, .trailing], 20)
                                }
                            }
                            
                            // 使用选择的图片按钮
                            Button(action: {
                                // 保存图片到应用目录并更新模型
                                if let imageName = saveImageToDocuments(selectedUIImage) {
                                    selectedImage = imageName
                                    onSelect(imageName)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16))
                                    Text("使用此图片")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
                
                Spacer()
            }
            .navigationBarTitle("选择背景图片", displayMode: .inline)
            .onAppear {
                loadUserUploadedImages()
            }
            .alert("确认操作", isPresented: $showDeleteConfirmation) {
                Button("从列表中移除", role: .destructive) {
                    if let imageName = imageToDelete {
                        deleteUploadedImage(imageName)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要从最近上传列表中移除这张图片吗？图片文件将被保留，但不会在此列表中显示。")
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
            
            UserDefaults.standard.set(uploadedImages, forKey: USER_UPLOADED_IMAGES_KEY)
            
            // 更新当前视图的状态并确保最多显示15张图片
            loadUserUploadedImages()
            
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    // 加载用户上传的图片列表
    private func loadUserUploadedImages() {
        // 获取所有上传的图片
        let allImages = UserDefaults.standard.stringArray(forKey: USER_UPLOADED_IMAGES_KEY) ?? []
        // 获取隐藏的图片
        hiddenImages = UserDefaults.standard.stringArray(forKey: USER_HIDDEN_IMAGES_KEY) ?? []
        
        // 过滤掉隐藏的图片，只显示非隐藏的图片
        userUploadedImages = allImages.filter { !hiddenImages.contains($0) }
        
        // 如果显示的图片超过15张，则只显示最新的15张
        if userUploadedImages.count > 15 {
            let visibleImages = Array(userUploadedImages.prefix(15))
            let hiddenOldImages = Array(userUploadedImages.dropFirst(15))
            
            // 更新显示的图片列表
            userUploadedImages = visibleImages
            
            // 将超出的图片添加到隐藏列表中
            hiddenImages.append(contentsOf: hiddenOldImages)
            UserDefaults.standard.set(hiddenImages, forKey: USER_HIDDEN_IMAGES_KEY)
        }
    }
    
    // 从文档目录加载图片
    private func loadImageFromDocuments(_ fileName: String) -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // 隐藏上传的图片（不从文件系统删除）
    private func deleteUploadedImage(_ fileName: String) {
        // 将图片添加到隐藏列表
        var hiddenImagesList = UserDefaults.standard.stringArray(forKey: USER_HIDDEN_IMAGES_KEY) ?? []
        if !hiddenImagesList.contains(fileName) {
            hiddenImagesList.append(fileName)
            UserDefaults.standard.set(hiddenImagesList, forKey: USER_HIDDEN_IMAGES_KEY)
        }
        
        // 从当前视图的显示列表中移除
        userUploadedImages.removeAll { $0 == fileName }
        hiddenImages = hiddenImagesList
    }
    
    // 获取应用文档目录
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

#Preview {
    ImagePickerView(selectedImage: .constant(nil), onSelect: { _ in })
}
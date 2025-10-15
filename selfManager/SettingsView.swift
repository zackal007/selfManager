//
//  SettingsView.swift
//  selfManager
//
//  Created by AI Assistant on 2023-11-01.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("dataBackupEnabled") private var dataBackupEnabled = false
    @AppStorage("privacyLockEnabled") private var privacyLockEnabled = false
    @AppStorage("syncFrequency") private var syncFrequency = 1 // 0: 手动, 1: 每天, 2: 每周
    
    @Environment(\.modelContext) private var modelContext
    @State private var trashExpirationDays: Int = 30
    
    @State private var showingAbout = false
    @State private var showingBackupOptions = false
    @State private var showingResetConfirmation = false
    
    private let syncOptions = ["手动同步", "每天", "每周"]
    
    var body: some View {
        NavigationView {
            Form {
                // 外观设置
                Section(header: Text("外观")) {
                    HStack {
                        Image(systemName: "moon.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                        Text("深色模式")
                        Spacer()
                        Toggle("", isOn: $isDarkMode)
                            .labelsHidden()
                    }
                }
                
                // 数据与隐私
                Section(header: Text("数据与隐私")) {
                    // 应用锁定
                    HStack {
                        Image(systemName: "lock.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                        Text("应用锁定")
                        Spacer()
                        Toggle("", isOn: $privacyLockEnabled)
                            .labelsHidden()
                    }
                    
                    // 备份与恢复
                    NavigationLink(destination: BackupOptionsView()) {
                        SettingRow(title: "备份与恢复", systemImage: "externaldrive.badge.person.crop", color: .blue)
                    }
                }
                
                // 关于
                Section(header: Text("关于")) {
                    // 关于应用
                    NavigationLink(destination: AboutView()) {
                        SettingRow(title: "关于应用", systemImage: "info.circle", color: .blue)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("设置")
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingBackupOptions) {
                BackupOptionsView()
            }
        }
    }
    
    private func sectionHeader(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.top, 8)
    }
    
    // 加载当前的回收站过期时间设置
    private func loadTrashExpirationDays() {
        // 保留此方法以备将来使用
    }
    
    // 更新回收站过期时间设置
    private func updateTrashExpirationDays() {
        // 保留此方法以备将来使用
    }
}

// 设置行组件
struct SettingRow: View {
    let title: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 26, height: 26)
            
            Text(title)
                .font(.system(size: 16))
        }
    }
}

// 关于视图
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .padding(.top, 40)
                
                Text("自我管理")
                    .font(.system(size: 28, weight: .bold))
                
                Text("版本 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("自我管理应用帮助您追踪个人目标、情绪和成就，提高自我认知和管理能力。")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("© 2023 自我管理团队")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                }
                .padding(.bottom, 40)
            }
            .padding()
            .navigationTitle("关于")
            .navigationBarItems(trailing: Button("关闭") {
                dismiss()
            })
        }
    }
}

// 备份选项视图
struct BackupOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingExportSuccess = false
    @State private var showingImportSuccess = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        // 模拟导出操作
                        isExporting = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isExporting = false
                            showingExportSuccess = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            Text("导出数据")
                            Spacer()
                            if isExporting {
                                ProgressView()
                            }
                        }
                    }
                    
                    Button(action: {
                        // 模拟导入操作
                        isImporting = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isImporting = false
                            showingImportSuccess = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            Text("导入数据")
                            Spacer()
                            if isImporting {
                                ProgressView()
                            }
                        }
                    }
                }
                
                Section(header: Text("备份信息"), footer: Text("上次备份时间: 2023年11月1日 08:30")) {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                        Text("iCloud 同步")
                        Spacer()
                        Text("已启用")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("备份与恢复")
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
            .alert(isPresented: $showingExportSuccess) {
                Alert(
                    title: Text("导出成功"),
                    message: Text("数据已成功导出到您的设备"),
                    dismissButton: .default(Text("确定"))
                )
            }
            .alert(isPresented: $showingImportSuccess) {
                Alert(
                    title: Text("导入成功"),
                    message: Text("数据已成功导入到应用"),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
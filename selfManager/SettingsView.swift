//
//  SettingsView.swift
//  selfManager
//
//  Created by AI Assistant on 2023-11-01.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("dataBackupEnabled") private var dataBackupEnabled = false
    @AppStorage("privacyLockEnabled") private var privacyLockEnabled = false
    @AppStorage("syncFrequency") private var syncFrequency = 1 // 0: 手动, 1: 每天, 2: 每周
    
    @State private var showingAbout = false
    @State private var showingBackupOptions = false
    @State private var showingResetConfirmation = false
    
    private let syncOptions = ["手动同步", "每天", "每周"]
    
    var body: some View {
        NavigationView {
            List {
                // 外观设置
                Section(header: sectionHeader(title: "外观", systemImage: "paintbrush.fill")) {
                    Toggle(isOn: $isDarkMode) {
                        SettingRow(title: "深色模式", systemImage: "moon.fill", color: .purple)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                }
                
                // 通知设置
                Section(header: sectionHeader(title: "通知", systemImage: "bell.fill")) {
                    Toggle(isOn: $enableNotifications) {
                        SettingRow(title: "推送通知", systemImage: "bell.badge.fill", color: .blue)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                    
                    if enableNotifications {
                        NavigationLink(destination: Text("通知设置详情").navigationTitle("通知设置")) {
                            SettingRow(title: "通知类型", systemImage: "bell.and.waves.left.and.right.fill", color: .blue)
                        }
                    }
                }
                
                // 数据与隐私
                Section(header: sectionHeader(title: "数据与隐私", systemImage: "lock.fill")) {
                    Toggle(isOn: $privacyLockEnabled) {
                        SettingRow(title: "应用锁定", systemImage: "lock.shield.fill", color: .green)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                    
                    Toggle(isOn: $dataBackupEnabled) {
                        SettingRow(title: "自动备份", systemImage: "arrow.clockwise.icloud.fill", color: .blue)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                    
                    if dataBackupEnabled {
                        Picker(selection: $syncFrequency, label: SettingRow(title: "同步频率", systemImage: "calendar.badge.clock", color: .blue)) {
                            ForEach(0..<syncOptions.count, id: \.self) { index in
                                Text(syncOptions[index])
                            }
                        }
                    }
                    
                    Button(action: {
                        showingBackupOptions = true
                    }) {
                        SettingRow(title: "备份与恢复", systemImage: "arrow.triangle.2.circlepath.icloud.fill", color: .blue)
                    }
                }
                
                // 关于与支持
                Section(header: sectionHeader(title: "关于与支持", systemImage: "info.circle.fill")) {
                    Button(action: {
                        showingAbout = true
                    }) {
                        SettingRow(title: "关于应用", systemImage: "info.circle.fill", color: .orange)
                    }
                    
                    Link(destination: URL(string: "mailto:support@example.com")!) {
                        SettingRow(title: "联系支持", systemImage: "envelope.fill", color: .orange)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        SettingRow(title: "隐私政策", systemImage: "hand.raised.fill", color: .orange)
                    }
                }
                
                // 危险区域
                Section(header: sectionHeader(title: "危险区域", systemImage: "exclamationmark.triangle.fill")) {
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        SettingRow(title: "重置所有数据", systemImage: "trash.fill", color: .red)
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("设置")
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
            .alert(isPresented: $showingResetConfirmation) {
                Alert(
                    title: Text("确认重置"),
                    message: Text("此操作将删除所有数据且无法恢复，确定要继续吗？"),
                    primaryButton: .destructive(Text("重置")) {
                        // 执行重置操作
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
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
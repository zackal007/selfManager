//
//  SettingsView.swift
//  selfManager
//
//  Created by AI Assistant on 2023-11-01.
//

import SwiftUI
import SwiftData
import Combine

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    // 外观模式：浅色、深色、跟随系统（三选项）
    enum AppearanceMode: String, CaseIterable {
        case light
        case dark
        case system
        var title: String {
            switch self {
            case .light: return "浅色"
            case .dark: return "深色"
            case .system: return "跟随系统"
            }
        }
    }
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @Environment(\.colorScheme) private var colorScheme
    private var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }
    // 首页卡片显示控制
    @AppStorage("showAssetCard") private var showAssetCard = true
    @AppStorage("showHabitCard") private var showHabitCard = true
    @AppStorage("showAchievementCard") private var showAchievementCard = true
    @AppStorage("showAnxietyCard") private var showAnxietyCard = true
    
    // 语言设置
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showLanguageSelector = false
    // 删除所有记录提示与状态
    @State private var showDeleteAllAlert = false
    @State private var isDeletingAll = false
    @State private var deleteAllErrorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                // 外观设置
                Section(header: Text("外观")) {
                    HStack(spacing: 12) {
                        Image(systemName: "moon.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                        Text("深色模式")
                        Spacer()
                    }
                    Picker("深色模式", selection: $appearanceModeRaw) {
                        Text(AppearanceMode.light.title).tag(AppearanceMode.light.rawValue)
                        Text(AppearanceMode.dark.title).tag(AppearanceMode.dark.rawValue)
                        Text(AppearanceMode.system.title).tag(AppearanceMode.system.rawValue)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: appearanceModeRaw) { _ in
                        switch appearanceMode {
                        case .light:
                            isDarkMode = false
                        case .dark:
                            isDarkMode = true
                        case .system:
                            // 跟随系统：将 isDarkMode 与当前系统外观保持一致
                            isDarkMode = (colorScheme == .dark)
                        }
                    }
                    .onAppear {
                        // 初次进入设置页时，根据当前选择同步 isDarkMode
                        switch appearanceMode {
                        case .light:
                            isDarkMode = false
                        case .dark:
                            isDarkMode = true
                        case .system:
                            isDarkMode = (colorScheme == .dark)
                        }
                    }
                    .onChange(of: colorScheme) { newScheme in
                        // 仅在选择“跟随系统”时，系统外观变化同步 isDarkMode
                        if appearanceMode == .system {
                            isDarkMode = (newScheme == .dark)
                        }
                    }
                }
                
                // 语言设置
                Section(header: Text("语言设置")) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                        Text("语言")
                        Spacer()
                        Button(LocalizationManager.shared.currentLanguage.displayName) {
                            showLanguageSelector = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                .sheet(isPresented: $showLanguageSelector) {
                    LanguageSelectorView(isPresented: $showLanguageSelector)
                        .environmentObject(LocalizationManager.shared)
                }
                
                // 首页卡片显示设置
                Section(header: Text("home_cards".localized)) {
                    // 资产卡片
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                        Text("asset_card".localized)
                        Spacer()
                        Toggle("", isOn: $showAssetCard)
                            .labelsHidden()
                    }
                    
                    // 习惯卡片
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                        Text("habit_card".localized)
                        Spacer()
                        Toggle("", isOn: $showHabitCard)
                            .labelsHidden()
                    }
                    
                    // 成就卡片
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                        Text("achievement_card".localized)
                        Spacer()
                        Toggle("", isOn: $showAchievementCard)
                            .labelsHidden()
                    }
                    
                    // 焦虑卡片
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                        Text("anxiety_card".localized)
                        Spacer()
                        Toggle("", isOn: $showAnxietyCard)
                            .labelsHidden()
                    }
                }
                // 数据管理
                Section(header: Text("数据管理")) {
                    Button(role: .destructive) {
                        showDeleteAllAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                            Text("删除所有记录")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    .disabled(isDeletingAll)
                    .alert("确认删除所有记录？", isPresented: $showDeleteAllAlert) {
                        Button("删除", role: .destructive) {
                            isDeletingAll = true
                            deleteAllErrorMessage = nil
                            do {
                                let descriptor = FetchDescriptor<Record>()
                                let records = try modelContext.fetch(descriptor)
                                for rec in records {
                                    modelContext.delete(rec)
                                }
                                if !records.isEmpty {
                                    try modelContext.save()
                                }
                                print("已删除 \(records.count) 条记录")
                            } catch {
                                deleteAllErrorMessage = error.localizedDescription
                                print("删除所有记录失败: \(error)")
                            }
                            isDeletingAll = false
                        }
                        Button("取消", role: .cancel) {}
                    } message: {
                        Text("此操作不可恢复，将删除所有日记/周记/月记/季记/年记记录。")
                    }

                    if let errorMsg = deleteAllErrorMessage {
                        Text("删除失败：\(errorMsg)")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("settings".localized)
            .navigationBarItems(trailing: Button("done".localized) {
                dismiss()
            })
            .onLanguageChange {
                // 强制视图刷新以响应语言变化
                // 视图会自动刷新，不需要手动触发
            }
        }
    }

    

}



struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
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
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    // 首页卡片显示控制
    @AppStorage("showAssetCard") private var showAssetCard = true
    @AppStorage("showHabitCard") private var showHabitCard = true
    @AppStorage("showAchievementCard") private var showAchievementCard = true
    @AppStorage("showAnxietyCard") private var showAnxietyCard = true
    
    // 语言设置
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showLanguageSelector = false
    
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
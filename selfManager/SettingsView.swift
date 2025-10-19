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
    // 首页卡片显示控制
    @AppStorage("showAssetCard") private var showAssetCard = true
    @AppStorage("showHabitCard") private var showHabitCard = true
    @AppStorage("showAchievementCard") private var showAchievementCard = true
    @AppStorage("showAnxietyCard") private var showAnxietyCard = true
    
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
                
                // 首页卡片显示设置
                Section(header: Text("首页卡片显示")) {
                    // 资产卡片
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                        Text("资产卡片")
                        Spacer()
                        Toggle("", isOn: $showAssetCard)
                            .labelsHidden()
                    }
                    
                    // 习惯卡片
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                        Text("习惯卡片")
                        Spacer()
                        Toggle("", isOn: $showHabitCard)
                            .labelsHidden()
                    }
                    
                    // 成就卡片
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                        Text("成就卡片")
                        Spacer()
                        Toggle("", isOn: $showAchievementCard)
                            .labelsHidden()
                    }
                    
                    // 焦虑卡片
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                        Text("焦虑卡片")
                        Spacer()
                        Toggle("", isOn: $showAnxietyCard)
                            .labelsHidden()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("设置")
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
        }
    }

    

}



struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
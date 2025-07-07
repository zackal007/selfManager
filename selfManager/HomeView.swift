//
//  ContentView.swift
//  selfManager
//
//  Created by zack on 24.6.25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    // 用户信息
    let userName = "Name"
    let userDescription = "我想成为一个大老板，我要环游世界，我要拥有一座庄园"
    let userTags = ["TAG1", "TAG1"]
    
    // 资产信息
    let assets = (现金: 10, 负债: 200, 其他: 10)
    
    // 目标信息
    let goals = ["目标1", "目标2", "目标3", "目标3"]
    let goalProgress = [0.7, 0.3, 0.8, 0.5] // 目标完成进度
    
    // 心情记录
    let moods = ["😊", "😊", "😎"]
    let moodDates = ["07/03", "07/03", "07/03"]
    
    // 成就图标
    let achievements = ["⚡️", "🎊", "🎃", "🎄", "🏂"]
    
    // 缺点/待改进项
    let weakPoints = ["⚡️", "🎊", "🎃", "🎄", "🏂"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 顶部标题
                HStack {
                    Text("个人概览")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "bell.badge")
                            .font(.title2)
                            .foregroundColor(Color(.systemBlue))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 用户信息卡片
                userProfileSection
                
                // 资产信息
                assetSection
                
                // 目标信息
                goalSection
                
                // 心情和成就并排显示
                HStack(spacing: 12) {
                    // 心情记录
                    moodSection
                        .frame(maxWidth: .infinity)
                    
                    // 成就展示
                    achievementSection
                        .frame(maxWidth: .infinity)
                }
                
                // 缺点/待改进项
                weakPointsSection
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // 用户信息区域 - 健康风格设计
    private var userProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 用户头像
                Text("👤")
                    .font(.system(size: 50))
                    .frame(width: 60, height: 60)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 4) {
                    // 用户名
                    Text(userName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    // 标签
                    HStack(spacing: 6) {
                        ForEach(userTags, id: \.self) { tag in
                            Text("# \(tag)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemBlue).opacity(0.1))
                                .foregroundColor(Color(.systemBlue))
                                .cornerRadius(4)
                        }
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color(.systemBlue))
                    }
                }
                
                Spacer()
                
                // 编辑按钮
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .foregroundColor(Color(.systemBlue))
                        .font(.headline)
                }
            }
            
            // 用户描述
            Text(userDescription)
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
                .padding(.top, 4)
                .lineLimit(2)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // 资产信息区域 - 健康风格设计
    private var assetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("💰")
                        .font(.title3)
                    Text("资产概览")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                // 目标进度
                HStack(spacing: 4) {
                    Text("220")
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.systemBlue))
                    Text("/")
                        .foregroundColor(Color(.secondaryLabel))
                    Text("1000")
                        .foregroundColor(Color(.secondaryLabel))
                }
                .font(.footnote)
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            // 资产数据
            HStack(spacing: 0) {
                // 现金
                VStack(spacing: 4) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("现金")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Text("\(assets.现金)W")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 1, height: 30)
                
                // 负债
                VStack(spacing: 4) {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("负债")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Text("\(assets.负债)W")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 1, height: 30)
                
                // 其他
                VStack(spacing: 4) {
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text("其他")
                            .font(.caption)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Text("\(assets.其他)W")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // 目标信息区域 - 健康风格设计
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("🎯")
                        .font(.title3)
                    Text("近期目标")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                // 目标总数
                Text("共有99个目标")
                    .font(.footnote)
                    .foregroundColor(Color(.secondaryLabel))
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            // 目标列表
            VStack(spacing: 16) {
                ForEach(0..<goals.count, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // 目标名称
                            Text(goals[index])
                                .font(.subheadline)
                                .foregroundColor(Color(.label))
                            
                            Spacer()
                            
                            // 进度百分比
                            Text("\(Int(goalProgress[index] * 100))%")
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        
                        // 进度条
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .frame(width: geometry.size.width, height: 6)
                                    .foregroundColor(Color(.systemGray5))
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .frame(width: min(CGFloat(goalProgress[index]) * geometry.size.width, geometry.size.width), height: 6)
                                    .foregroundColor(index % 4 == 0 ? Color(.systemGreen) : 
                                                    index % 4 == 1 ? Color(.systemRed) : 
                                                    index % 4 == 2 ? Color(.systemBlue) : 
                                                    Color(.systemOrange))
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // 心情记录区域 - 健康风格设计
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("😊")
                        .font(.title3)
                    Text("心情")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            // 心情日历
            HStack(spacing: 8) {
                ForEach(0..<moods.count, id: \.self) { index in
                    VStack(spacing: 6) {
                        Text(moodDates[index])
                            .font(.caption2)
                            .foregroundColor(Color(.secondaryLabel))
                        
                        Text(moods[index])
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
            .frame(height: 80) // 固定高度，与成就模块保持一致
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // 成就展示区域 - 健康风格设计
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("🏆")
                        .font(.title3)
                    Text("成就")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            // 成就图标 - 改为HStack布局，与心情模块保持一致
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements, id: \.self) { achievement in
                        Text(achievement)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }
                }
            }
            .frame(height: 80) // 固定高度，与心情模块保持一致
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // 缺点/待改进项区域 - 健康风格设计
    private var weakPointsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 标题和emoji图标
                HStack(spacing: 6) {
                    Text("🔄")
                        .font(.title3)
                    Text("待改进项")
                        .font(.headline)
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                // 详情按钮
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            // 缺点图标
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(weakPoints, id: \.self) { point in
                        VStack {
                            Text(point)
                                .font(.title3)
                                .frame(width: 50, height: 50)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                            
                            Text("待改进")
                                .font(.caption2)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Item.self, inMemory: true)
}

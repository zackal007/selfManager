//
//  AchievementDetailView.swift
//  selfManager
//
//  Created by Assistant on 2024
//

import SwiftUI
import SwiftData
import UIKit

struct AchievementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Goal.createTime, order: .reverse) private var goals: [Goal]
    
    private var achievementGoals: [Goal] {
        goals.filter { !$0.isDeleted && $0.tags.contains(BuiltInTags.achievement) }
    }
    private var totalCount: Int { achievementGoals.count }
    private var completedCount: Int { achievementGoals.filter { $0.progress >= 1.0 }.count }
    private var unlockRate: Double { totalCount == 0 ? 0.0 : Double(completedCount) / Double(totalCount) }

    private let columns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AchievementStatsCard(total: totalCount, completed: completedCount, rate: unlockRate)
                SectionHeader(title: "achievement_list".localized)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(achievementGoals) { goal in
                        NavigationLink(destination: GoalDetailView(goal: goal)) {
                            AchievementCard(goal: goal)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("achievement_center".localized)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("back".localized)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(UIColor.label))
            Spacer()
        }
    }
}

private struct AchievementStatsCard: View {
    let total: Int
    let completed: Int
    let rate: Double
    
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("total_achievements".localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    HStack(alignment: .bottom, spacing: 6) {
                        Text("\(completed)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(UIColor.label))
                        Text("/\(total)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    ProgressView(value: rate)
                        .tint(Color(UIColor.systemBlue))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("unlock_rate".localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    HStack(alignment: .bottom, spacing: 6) {
                        Text("\(Int(rate * 100))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(UIColor.label))
                        Text("%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    HStack(spacing: 6) {
                        Image(systemName: rate >= 0.5 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(rate >= 0.5 ? Color(UIColor.systemGreen) : Color(UIColor.systemRed))
                        Text(String(format: "%@%.1f%%", rate >= 0.5 ? "+" : "-", abs(rate * 100 - 50)))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(rate >= 0.5 ? Color(UIColor.systemGreen) : Color(UIColor.systemRed))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

private struct AchievementCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                // 使用目标的背景图片作为图标（裁剪为小方块），无则回退为奖杯
                let iconSize: CGFloat = 28
                if let bgName = goal.backgroundImage, !bgName.isEmpty,
                   let uiImage = SMImageCache.shared.image(named: bgName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: iconSize, height: iconSize)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .clipped()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                } else {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(UIColor.systemYellow))
                        .frame(width: iconSize, height: iconSize)
                        .background(Color(UIColor.systemYellow).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Text(goal.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
            }
            Text("progress".localized + " \(Int(goal.progress * 100))%")
                .font(.system(size: 12))
                .foregroundColor(Color(UIColor.secondaryLabel))
            ProgressView(value: min(max(goal.progress, 0), 1))
                .tint(Color(UIColor.systemBlue))
            
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// 保留模型定义以兼容现有数据查询
@Model
final class Achievement: Identifiable, ObservableObject {
    var id: UUID
    var emoji: String
    var name: String
    var achievementDescription: String
    var category: String
    var isCompleted: Bool
    var completionDate: Date?
    var creationDate: Date

    init(id: UUID = UUID(), emoji: String, name: String, achievementDescription: String, category: String, isCompleted: Bool, completionDate: Date? = nil, creationDate: Date = Date()) {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.achievementDescription = achievementDescription
        self.category = category
        self.isCompleted = isCompleted
        self.completionDate = completionDate
        self.creationDate = creationDate
    }
}

#Preview {
    AchievementDetailView()
}
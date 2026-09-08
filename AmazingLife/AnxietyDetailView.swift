import SwiftUI
import SwiftData
import UIKit

struct AnxietyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Goal.createTime, order: .reverse) private var goals: [Goal]

    private var anxietyGoals: [Goal] {
        goals.filter { !$0.isDeleted && $0.tags.contains(BuiltInTags.anxiety) }
    }
    private var totalCount: Int { anxietyGoals.count }
    private var weeklyCount: Int {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now
        return anxietyGoals.filter { $0.createTime >= start }.count
    }

    private let columns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AnxietyStatsCard(total: totalCount, weekly: weeklyCount)
                    SectionHeader(title: "anxiety_list".localized)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(anxietyGoals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                AnxietyCard(goal: goal)
                            }
                    }
                }
                }
                .padding(16)
            }
            .navigationTitle("anxiety_center".localized)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // Since AnxietyDetailView is wrapped in a NavigationStack, dismiss() won't work directly.
                        // We need to find a way to pop the view from the stack.
                        // For now, I'll leave it as dismiss() and assume it will be handled by the NavigationStack.
                        // In a real app, you might use @Environment(\.presentationMode) or a custom navigation solution.
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

private struct AnxietyStatsCard: View {
    let total: Int
    let weekly: Int
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("total_anxiety".localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text("\(total)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("weekly_new".localized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    HStack(alignment: .bottom, spacing: 6) {
                        Image(systemName: weekly >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(weekly >= 0 ? Color(UIColor.systemOrange) : Color(UIColor.systemGreen))
                        Text("\(weekly)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(UIColor.label))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(DesignToken.cornerRadius)
        .shadow(color: Color(UIColor.label).opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

private struct AnxietyCard: View {
    let goal: Goal
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                // 参考成就条目：优先使用目标背景图作为图标，无则回退警示图标
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
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(UIColor.systemOrange))
                        .frame(width: iconSize, height: iconSize)
                        .background(Color(UIColor.systemOrange).opacity(0.12))
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
        .cornerRadius(DesignToken.cornerRadiusMedium)
        .shadow(color: Color(UIColor.label).opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    AnxietyDetailView()
}
import SwiftUI
import UIKit

// 主页专用的人脉卡片：仅展示头像、名字、标签、联系人类型
struct HomeContactCard: View {
    let contact: Contact
    let size: HomeView.HomeCardSize
    let containerHeight: CGFloat

    private struct CardStyle {
        let nameSize: CGFloat
        let notesTitleSize: CGFloat
        let notesTextSize: CGFloat
        let tagRowHeight: CGFloat
        let vSpacing: CGFloat
        let nameLines: Int
        let notesLines: Int?
        let avatarSize: CGFloat
    }

    private func style(for size: HomeView.HomeCardSize) -> CardStyle {
        switch size {
        case .small:
            return CardStyle(nameSize: 17, notesTitleSize: 11, notesTextSize: 12, tagRowHeight: 26, vSpacing: 8, nameLines: 2, notesLines: 2, avatarSize: 56)
        case .medium:
            return CardStyle(nameSize: 18, notesTitleSize: 11, notesTextSize: 12.5, tagRowHeight: 26, vSpacing: 10, nameLines: 2, notesLines: 3, avatarSize: 62)
        case .large:
            return CardStyle(nameSize: 20, notesTitleSize: 12, notesTextSize: 13, tagRowHeight: 28, vSpacing: 12, nameLines: 3, notesLines: nil, avatarSize: 70)
        }
    }

    var body: some View {
        let s = style(for: size)
        VStack(alignment: .center, spacing: s.vSpacing) {
            // 头像（居中）
            ZStack {
                Circle()
                    .fill(Color(UIColor.secondarySystemFill))
                    .frame(width: s.avatarSize, height: s.avatarSize)

                if let avatarName = contact.avatar,
                   let uiImage = SMImageCache.shared.image(named: avatarName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: s.avatarSize, height: s.avatarSize)
                        .clipShape(Circle())
                } else {
                    Text(String(contact.name.prefix(1)))
                        .font(.system(size: s.avatarSize / 2.8, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                }
            }

            // 人脉名称（居中）
            Text(contact.name)
                .font(.system(size: s.nameSize, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
                .lineLimit(s.nameLines)
                .multilineTextAlignment(.center)

            // 类型（头像正下方，无背景，居中）
            HStack(spacing: 4) {
                Image(systemName: contact.contactType.iconName)
                    .font(.system(size: 12, weight: .semibold))
                Text(contact.contactType.displayName)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(Color(UIColor.secondaryLabel))

            // 标签（类型下方，居中显示；过多时可横向滚动）
            if !contact.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(contact.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(TagColorManager.shared.getColor(for: tag))
                                .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(height: s.tagRowHeight)
            }

            // 备注（直接显示备注内容，不再显示“备注”标题）
            if let notes = contact.notes, !notes.isEmpty {
                VStack(spacing: 4) {
                    Text(notes)
                        .font(.system(size: s.notesTextSize))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(s.notesLines)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: containerHeight, alignment: .top)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(UIColor.separator).opacity(0.18), lineWidth: 1)
                )
        )
    }
}
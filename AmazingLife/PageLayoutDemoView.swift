//
//  PageLayoutDemoView.swift
//  AmazingLife
//
//  PageLayoutView 模板演示页面
//

import SwiftUI

struct PageLayoutDemoView: View {
    @State private var selectedTabIndex = 0
    @State private var viewMode: PageViewMode = .gallery
    @State private var navigationPath = NavigationPath()

    private let tabs: [PageTabItem] = [
        PageTabItem(id: 0, title: "全部"),
        PageTabItem(id: 1, title: "工作"),
        PageTabItem(id: 2, title: "生活"),
        PageTabItem(id: 3, title: "学习"),
        PageTabItem(id: 4, title: "健康")
    ]

    var body: some View {
        PageLayoutView(
            headerConfig: PageHeaderConfig(
                title: "演示页面",
                menuContent: {
                    AnyView(
                        Menu {
                            Button(action: {
                                withAnimation { viewMode = .gallery }
                            }) {
                                Label("画廊视图", systemImage: "square.grid.2x2")
                            }

                            Button(action: {
                                withAnimation { viewMode = .list }
                            }) {
                                Label("列表视图", systemImage: "list.bullet")
                            }

                            Divider()

                            Button(action: {}) {
                                Label("按名称排序", systemImage: "textformat")
                            }

                            Button(action: {}) {
                                Label("按时间排序", systemImage: "clock")
                            }

                            Divider()

                            Button(action: {}) {
                                Label("回收站", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18))
                        }
                    )
                }
            ),
            tabs: tabs,
            selectedTabIndex: $selectedTabIndex,
            viewMode: $viewMode,
            fabConfig: FABConfig(
                isEnabled: true,
                action: { print("点击了添加按钮") }
            ),
            navigationPath: $navigationPath,
            onNavigate: { route in
                print("导航到: \(route)")
            },
            galleryContentBuilder: { tabId in
                galleryContent(for: tabId)
            },
            listContentBuilder: { tabId in
                listContent(for: tabId)
            }
        )
        .edgesIgnoringSafeArea(.bottom)
    }

    // MARK: - 画廊视图内容
    @ViewBuilder
    private func galleryContent(for tabId: Int) -> some View {
        VStack(spacing: 12) {
            ForEach(0..<12, id: \.self) { index in
                HStack(spacing: 12) {
                    ForEach(0..<2, id: \.self) { col in
                        let itemIndex = index * 2 + col
                        if itemIndex < 30 {
                            demoGalleryCard(index: itemIndex, tabId: tabId)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func demoGalleryCard(index: Int, tabId: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: ["star.fill", "book.fill", "heart.fill", "briefcase.fill", "graduationcap.fill"][index % 5])
                        .foregroundColor(.blue)
                )

            Text("项目 \(index + 1)")
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)

            Text("Tab \(tabId)")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    // MARK: - 列表视图内容
    @ViewBuilder
    private func listContent(for tabId: Int) -> some View {
        VStack(spacing: 12) {
            ForEach(0..<15, id: \.self) { index in
                demoListRow(index: index, tabId: tabId)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func demoListRow(index: Int, tabId: Int) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: ["star.fill", "book.fill", "heart.fill", "briefcase.fill", "graduationcap.fill"][index % 5])
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("列表项目 \(index + 1)")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("这是第 \(tabId) 个标签页")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

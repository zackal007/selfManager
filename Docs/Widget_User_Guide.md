# 小组件使用指引

## 添加扩展
- 在 Xcode 中为项目新增 Widget Extension，命名为 `CoreWidgets`。
- 将 `selfManager/Widgets/` 目录下的文件加入扩展目标。
- 在扩展的 `Info.plist` 中启用 `WidgetKit`。

## 数据同步
- 在主 App 的 `Signing & Capabilities` 添加 App Groups，例如 `group.selfmanager.widget`。
- 在扩展中添加相同的 App Group。
- 主 App 已在 `selfManager/Utils/WidgetSharedDataManager.swift` 写入摘要数据并触发刷新。

## 支持尺寸
- 小：`systemSmall`（约 1×1）
- 中：`systemMedium`（约 4×2）
- 大：`systemLarge`（约 4×4）

## 配置
- 小组件支持选择展示内容类型（度量或快捷入口），在添加时通过配置界面选择。

## 快捷入口
- 可在扩展中为视图添加 `widgetURL` 以跳转到 App 对应页面，需在主 App 注册 URL Scheme。

## 适配
- 使用系统动态字体与自动布局，支持浅色/深色模式。

## 刷新与更新
- 时间线每 30 分钟自动更新。
- 主 App 进入前台与数据同步后触发刷新。

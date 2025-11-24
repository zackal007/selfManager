## 目标
- 全量普查现有字号、按场景归档
- 对比行业标杆，确定合理字号梯度
- 输出统一的字号规范与全局样式常量
- 执行页面替换与适配，并验证可读性

## 现状快照（抽样）
- 导航/标题常用：`24`（如 HomeView.swift:308、TagsView.swift:381）
- 页面区块标题：`20`（如 TagsView.swift:780/861/943）
- 正文：`16/17`（如 TagsView.swift:474、HomeView.swift:1321/1331/1341）
- 辅助/说明：`12/13/14`（如 TagsView.swift:226/308/332、HomeView.swift:1174/1194）
- 特例：`60`（空状态巨型符号 TrashView.swift:42）、`30`（HomeView.swift:1646）
- 返回按钮文本：`17`（TagsView.swift:1021、TagCategoryListView.swift:62/255）
- 示例引用：RecordView 标题 `20`（RecordView.swift:72）、列表项副文 `13/12`（多处）

## 竞品分析方法
- 选取 3–5 个标杆（如备忘录、微信、Notion、Things、Apple HIG 示例）
- 使用屏幕测量工具采集：
  - 一级标题：28–34pt
  - 二级标题：22–26pt
  - 正文：16–20pt
  - 辅助：12–14pt
  - 弹窗/角标：10–12pt（不低于 11pt 的最小可读）
- 记录截图与测量值，形成对比表（字号/使用场景/示例截图）

## 拟定字号梯度（建议）
- NavBar 标题：`24–26pt`（默认 `24`）
- 页面主标题：`22–24pt`（默认 `22`）
- 区块标题：`18–20pt`（默认 `18`）
- 正文：`16–17pt`（默认 `16`）
- 次级文字/按钮：`14–15pt`（默认 `14`）
- 辅助说明/注释：`12–13pt`（默认 `13`）
- 最小可读：≥`11pt`（仅角标/徽章）
- 特殊展示（Hero/空状态大数值）：`28–34pt`或更大，但纳入白名单组件

## 适配规则
- 支持 Dynamic Type：所有字号通过 `relative`/`UIFontMetrics`/SwiftUI 动态类型缩放
- iPhone 小尺寸优先不缩至低于 `12pt`；iPad 可提升一个梯度
- 文字最小缩放：不低于 `11pt`；大标题允许按系统缩放但保留行高与断行策略

## 落地方案
- 新增全局常量文件：`Utils/AppTypography.swift`
  - `struct AppFont { static let navTitle: Font; pageTitle; sectionTitle; body; subtext; caption; badge; }`
  - `enum AppFontSize { navTitle=24, pageTitle=22, sectionTitle=18, body=16, subtext=14, caption=13, badge=11 }`
  - 提供辅助修饰符：`appFont(_:)`、`appScaled(_:)`（封装动态类型）
- 替换策略：
  - 第一阶段（低风险）：返回按钮文字、列表副文、辅助标签
    - 如：TagsView.swift:1021 改为 `AppFont.subtext`
  - 第二阶段（核心）：导航标题、页面主标题、区块标题
    - 如：HomeView.swift:308/1155、TagsView.swift:381/780/861/943 使用 `AppFont.navTitle/pageTitle/sectionTitle`
  - 第三阶段（特例）：空状态/大数字统一为 `AppFont.hero（30–34）`
    - 如：TrashView.swift:42、HomeView.swift:1646
- 代码替换方式：仅将 `.font(.system(size:…))` 替换为 `AppFont.xxx`，不改动布局与颜色

## 验证与测试
- 可读性走查：典型页面（首页、目标详情、记录、标签）
- 动态类型测试：系统字体大小调至 `Large/ExtraLarge`，检查换行与截断
- 自动化快照测试：关键组件截图对比（前后像素差）
- 性能与回归：确保无卡顿；不修改多线程逻辑

## 交付物
- 《APP字号使用规范》（结构化条目 + 对比表）
- `Utils/AppTypography.swift` 全局常量与修饰符
- 首批页面替换提交（以 PR 形式，不含文档提交到仓库）

## 长期机制
- 在 UI 组件库固化 `AppFont` 使用
- 设计走查每次上线前执行
- 静态检查（Lint）扫描 `.font(.system(size:))` 直写并告警

## 需要确认
- 是否接受以上梯度与默认值
- 是否按“三阶段”推进替换
- 是否纳入 Dynamic Type 全量支持
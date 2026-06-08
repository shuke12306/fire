# Fire v2.0 大版本规划：交互体验与功能设计文档

> 路线方案：基础夯实 → 功能扩展 → 原生差异化 → 发布准备
> 目标周期：16+ 周 | 交付策略：阶段化交付，每阶段有独立可验证成果
> 核心定位：在功能对等基础上，通过原生独有体验实现差异化

---

## 一、现状评估

### 1.1 Rust Core — 功能完整

`fire-core` 已覆盖全部 14 个 API 模块。Session 生命周期（含 epoch 防重放、auth strike、CF challenge）完整；Topics/Posts/Users/Search/Notifications/MessageBus/Presence/Interactions/Creation 全部实现。UniFFI 桥接暴露 7 个子 handle 给平台。

**缺失：** LDC Credit / CDK OAuth 尚无 Rust 模块。

### 1.2 iOS — 功能丰富，体验有打磨空间

| 模块 | 完成度 | 关键差距 |
|------|--------|----------|
| 首页/话题列表 | ★★★★☆ | Feed kind 中英文标题不一致；`FireFeedKindSelector` 与 `FilteredTopicListView` 使用不同的视觉风格 |
| 话题详情 | ★★★★★ | AsyncDisplayKit 渲染路径成熟；缺话题内搜索 |
| 通知 | ★★★★☆ | 缺上下文菜单；`notificationAlert` 事件处理为 no-op |
| 搜索 | ★★★★☆ | 缺搜索结果上下文菜单 |
| 编辑器 | ★★★☆☆ | 缺 Markdown 工具栏、引用插入、链接预览；`PostEditorView` 使用基础 `TextEditor` 与主编辑器不一致 |
| 私信 | ★★★★☆ | 功能完整 |
| 个人资料 | ★★★★☆ | 缺关注列表入口的发现引导 |
| 书签/草稿 | ★★★★☆ | 功能完整 |
| 开发者工具 | ★★★★★ | APM、网络追踪、日志、诊断导出齐全 |
| 无障碍 | ★★☆☆☆ | UIKit 路径标注完善；SwiftUI 视图几乎无 `.accessibilityLabel` |
| 暗黑模式 | ★★★★☆ | 主题系统成熟；部分硬编码颜色未走 Token |
| 国际化 | ★☆☆☆☆ | 全量中文字符串硬编码，无 NSLocalizedString |
| 视觉一致性 | ★★★☆☆ | 圆角（10/12/14/16/18/20 混用）、背景色系统（至少 4 种写法）、空状态组件已建但未复用 |

**架构问题：**
- `FireAppViewModel` 2313 行，承担全部功能的门面角色
- 8 个独立 ViewModel 重复实现分页/加载/错误模式
- 多个列表视图未使用 `ListKit` 抽象（通知、私信、阅读历史、草稿、搜索）

### 1.3 Android — 核心对齐，辅助页面缺失

| 模块 | 完成度 | 关键差距 |
|------|--------|----------|
| 首页/话题列表 | ★★★★☆ | 功能与 iOS 对齐 |
| 话题详情 | ★★★★☆ | 功能与 iOS 对齐 |
| 通知 | ★★★☆☆ | 缺通知历史全屏页 |
| 搜索 | ★★★★☆ | 功能完整 |
| 编辑器 | ★★★★☆ | 功能完整 |
| 私信 | ★★★★☆ | 功能完整 |
| 个人资料 | ★★★☆☆ | 缺关注列表、徽章详情、活动时间线 |
| 书签 | ★★★★☆ | 功能完整 |
| **草稿列表** | **未实现** | 编辑器有草稿保存，但无独立列表页 |
| **阅读历史** | **未实现** | Rust 已有 API |
| **推送通知（FCM）** | **未实现** | 需要 Firebase 集成 |
| 开发者工具 | 未实现 | APM、诊断等无对应页面 |
| 无障碍 | ★★☆☆☆ | 基础 content descriptions，覆盖不全 |

---

## 二、P1 基础夯实（4-5 周）

> 目标：消除视觉不一致、补齐 Accessibility、统一架构模式、Android 核心页面补全

### 2.1 视觉 Token 统一（iOS + Android，1 周）

**圆角 Token 规范化：**

当前混用 10/12/14/16/18/20 六种圆角。收敛为 4 个 Token：

| Token | 值 | 用途 |
|-------|----|------|
| `FireTheme.cornerRadius` | 20 | 大卡片、面板、Sheet |
| `FireTheme.mediumCornerRadius` | 14 | 行级组件、状态芯片、分类标签 |
| `FireTheme.smallCornerRadius` | 10 | 输入框、搜索栏、小按钮 |
| `FireTheme.pillRadius` | .infinity | 胶囊形标签、信任等级药丸 |

全局替换硬编码值为 Token 引用。

**背景色 Token 统一：**

将 `Color(.systemGroupedBackground)`、`Color(.secondarySystemBackground)`、`FireSceneBackground`、`.scrollContentBackground(.hidden)` 统一收敛到 `FireTheme` 的 3 个语义色：

| Token | 语义 | 适配值 |
|-------|------|--------|
| `FireTheme.canvas` | 页面最底层 | 自动适配 light/dark |
| `FireTheme.surface` | 卡片/面板层 | 自动适配 light/dark |
| `FireTheme.surfaceSecondary` | 分组/凹陷区 | 自动适配 light/dark |

**Feed Kind Selector 统一：**

将 `FireFilteredTopicListView` 中的简易 `Capsule().fill()` 替换为 `FireFeedKindSelector`（使用 `matchedGeometryEffect`），确保同一交互在首页和筛选页视觉一致。

**Feed Kind 标题语言统一：**

当前 `TopicListKindState.title` 返回英文（"Latest", "New"），而 `privateMessagesInbox` 返回中文。统一为中文标题，为后续国际化铺路。

### 2.2 无障碍标注补全（iOS，1 周）

**SwiftUI 视图批量标注：**

对以下视图添加 `.accessibilityLabel()` / `.accessibilityHint()`：
- `FireTopicRow` — 读取话题标题、回复数、查看数、分类
- `FireComposerView` — 编辑区、工具栏按钮（上传/预览）
- `FireSearchView` — 搜索字段、结果行、筛选器
- `FireHomeView` — 创建按钮、搜索按钮
- `FireBookmarksView` — 书签行、删除操作
- `FireDraftsView` — 草稿行、继续编辑、删除
- `FireOnboardingView` — 登录按钮、品牌区域
- `FireNotificationsView` — 通知行、标记已读
- `FireProfileView` — 各统计项、操作按钮

**加载骨架屏标注：**
- 所有 skeleton/placeholder 视图标记 `.accessibilityHidden(true)`
- 使用 `.accessibilityAnnouncement` 在加载完成时播报

**按钮标签：**
- 所有仅图标按钮添加 `accessibilityLabel`
- 添加 `accessibilitySortPriority` 确保关键元素优先朗读

### 2.3 暗黑模式修复（iOS，3 天）

- 替换 `FireComposerView` 中的 `Color.black.opacity(0.06)` 为自适应 `FireTheme.divider`
- 替换 `FireComposerView` 中的 `Color.black.opacity()` 描边为 `FireTheme.border`
- 检查所有 `Color.black`/`Color.white` 硬编码用法，替换为语义色

### 2.4 架构统一 — 通用分页 Store 提取（iOS + Android，1 周）

**iOS：提取 `FirePaginatedStore<Item>`**

当前 8 个 ViewModel 独立实现 `hasLoadedOnce`、`isLoading`、`isLoadingMore`、`errorMessage`、分页加载逻辑。提取为：

```
FirePaginatedStore<Item: Identifiable>
  @Published items: [Item]
  @Published isLoading: Bool
  @Published isLoadingMore: Bool
  @Published hasLoadedOnce: Bool
  @Published blockingError: String?
  @Published nonBlockingError: String?

  func load(forceRefresh: Bool)
  func loadMore()
  func reset()
```

受益的 ViewModel：
- `FireFilteredTopicListViewModel`
- `FirePrivateMessagesViewModel`
- `FireBookmarksViewModel`
- `FireReadHistoryViewModel`
- `FireDraftsViewModel`
- `FireNotificationStore`（recent + full 合并）
- `FireSearchStore`

**Android：同等地提取 `PaginatedViewModel<Item>` 基类。**

### 2.5 空状态组件复用（iOS + Android，3 天）

`FireEmptyFeedState` 已存在于 `FireComponents.swift` 但从未被使用。各视图自建空状态。

统一方案：
- 所有列表视图使用 `FireEmptyFeedState`（或其 Android 等价物）
- 支持 3 种状态：空数据、加载失败、无搜索结果
- 配合 Shimmer 动画替换静态 `.redacted(reason: .placeholder)`

### 2.6 上下文菜单（iOS + Android，3 天）

为以下元素添加长按上下文菜单：

| 元素 | 菜单项 |
|------|--------|
| 话题行（首页/搜索/书签） | 收藏、分享、在新窗口打开、静音/关注 |
| 通知行 | 标记已读、跳转到话题、跳转到用户 |
| 搜索结果行 | 收藏、分享 |

### 2.7 Android 缺失页面补全（Android，2 周）

**草稿列表页：**
- `DraftsFragment` + `DraftsViewModel`
- 分页加载、继续编辑（跳转到对应编辑器）、滑动删除
- Rust 核心已暴露 `fetchDrafts()` / `deleteDraft()`

**推送通知（FCM）：**
- Firebase Cloud Messaging 集成
- `FirebaseMessagingService` 实现
- 通知 Channel 配置
- Token 注册与刷新

**通知历史全屏页：**
- `NotificationHistoryFragment` + `NotificationHistoryViewModel`
- 分组显示、分页加载

**阅读历史页：**
- `ReadHistoryFragment` + `ReadHistoryViewModel`
- 调用 Rust 核心 `fetchReadHistory()` 分页加载

**话题阅读计时：**
- 等价于 iOS `FireTopicTimingTracker`
- 通过 Rust 核心报告阅读时间

### 2.8 `FireAppViewModel` 拆分启动（iOS，1 周）

当前 `FireAppViewModel` 2313 行。P1 阶段先提取最独立的 3 个模块：

1. **`FireTopicInteractionService`** — 收藏、Reaction、投票、标记等话题内交互
2. **`FireNotificationService`** — 通知获取、标记已读、计数
3. **`FireSearchService`** — 搜索执行、结果管理

`FireAppViewModel` 保留 session 管理、MessageBus 协调、路由等核心职责。

---

## 三、P2 功能补全（5-6 周）

> 目标：补齐 API 表面中的未实现功能，LDC/CDK OAuth 优先

### 3.1 LDC Credit / CDK OAuth（全栈，2 周）

**Rust 层（新建模块）：**

在 `fire-core` 中新增 `src/core/ldc.rs` 和 `src/core/cdk.rs`：

- LDC OAuth 授权 URL 生成 → 加载审批页 → 用户确认 → 回调换取 Token → 获取用户信息（余额、支付记录）
- CDK OAuth 对称流程（不同 user-info 结构）
- Connect HTML 统计页解析（信任等级进度抓取）
- LDC 奖励/分发 API（Basic auth）

`fire-models` 新增对应模型类型。

**iOS 层：**

- 个人资料页新增「LDC 信用」入口 → 显示余额、支付历史
- 「CDK 连接」入口 → 授权绑定、查看状态
- Connect 统计页 → 原生渲染信任等级进度

**Android 层：**

- 对称实现 iOS 的 LDC/CDK UI

### 3.2 线程视图（iOS + Android，1.5 周）

Rust 模型层已有 `TopicThread`、`TopicThreadFlatPost`、`TopicTreeRow`。需要在原生 UI 层实现：

**话题详情页新增「线程」视图模式：**
- 切换入口在话题详情顶部工具栏
- 线程视图展示帖子回复树结构
- 支持展开/折叠子线程
- 保留「树状」视图作为默认，线程视图作为可选项

### 3.3 编辑器增强（iOS + Android，1.5 周）

**Markdown 工具栏：**
- 在键盘上方添加格式化快捷栏：粗体、斜体、删除线、代码、代码块、引用、有序/无序列表、链接、图片
- 点击按钮在光标位置插入对应 Markdown 标记

**引用插入：**
- 话题详情中选中帖子内容 → 「引用回复」→ 自动在编辑器中插入 `[quote]` 块

**链接预览：**
- 粘贴 URL 时自动生成预览卡片（标题、描述、缩略图）

**PostEditorView 升级：**
- 将 `FirePostEditorView` 从基础 `TextEditor` 升级为 `FireComposerTextView`，与主编辑器保持一致

### 3.4 话题通知级别控制（iOS + Android，3 天）

Rust 已有 `setTopicNotificationLevel` API。需要：

- 话题详情工具栏新增「通知」按钮
- 弹出选择：静音（muted）/常规（regular）/跟踪（tracking）/关注（watching）
- 状态反映在工具栏图标上

### 3.5 表情/Reaction 选择器增强（iOS + Android，3 天）

- 扩展现有 Reaction 选择器，展示可用 Reaction 列表（Rust 已有 `fetchAvailableReactions` API）
- 支持搜索表情
- 展示 Reaction 用户列表

### 3.6 书签提醒 UI（iOS + Android，2 天）

Rust 已有 bookmark reminder API。需要：

- 书签编辑器中的「提醒」日期选择器
- 提醒触发时的本地通知
- 提醒管理视图（列出所有待处理提醒）

### 3.7 话题内搜索（iOS + Android，3 天）

- 话题详情页工具栏新增搜索按钮
- 搜索面板输入关键词
- 高亮匹配帖子并跳转
- 上/下一个匹配导航

---

## 四、P3 原生差异化（5-6 周）

> 目标：在坚实的功能基础上，叠加原生端独有的体验优势

### 4.1 iOS Widget（2 周）

**今日热门 Widget（小/中/大）：**
- Small：未读数 + 最新话题标题
- Medium：2-3 条热门话题
- Large：5 条热门话题 + 分类标签

**未读数 Widget：**
- Small 圆形/矩形显示未读通知数
- 点击跳转到通知页

**技术方案：**
- WidgetKit + SwiftUI
- 通过 App Group 共享数据
- Rust 核心定时获取数据写入共享 UserDefaults

### 4.2 Android Widget（1.5 周）

**Glance Widget：**
- 未读通知数
- 热门话题列表
- Material You 动态颜色适配

### 4.3 Haptic 反馈全面覆盖（iOS，1 周）

当前仅 CTA 按钮有 `fireSuccessFeedback`。扩展到：

| 交互 | 反馈 |
|------|------|
| 点赞/取消点赞 | `.selectionChanged` |
| Reaction 切换 | `.selectionChanged` |
| 收藏/取消收藏 | `.selectionChanged` |
| 下拉刷新完成 | `.success` |
| 发送成功 | `.success` |
| 发送失败 | `.error` |
| Tab 切换 | `.selectionChanged`（轻） |
| 上下文菜单弹出 | `.selectionChanged` |
| 长按操作 | `.mediumImpact` |

### 4.4 Toast/Snackbar 组件（iOS + Android，3 天）

替代当前非关键反馈使用的 `.alert()`（阻塞交互）：

- 编辑器自动保存确认
- 草稿已保存
- 操作成功（收藏、Reaction）
- 网络恢复提示

非模态、自动消失、不阻断用户操作流。

### 4.5 离线缓存层（iOS + Android，1.5 周）

**目标：** 网络不可用时显示上次成功加载的数据而非空白错误页。

**策略：**
- 列表数据：`FirePaginatedStore` 在加载成功后缓存到本地 SQLite（Rust `fire-store` 已有基础设施）
- 话题详情：首次加载的帖子集合缓存
- 失败时：优先展示缓存数据 + 底部「离线模式」提示条
- 写操作：队列化，网络恢复后自动重试

### 4.6 Shimmer 加载动画（iOS + Android，3 天）

替换静态 `.redacted(reason: .placeholder)`：

- 渐变光效从左到右扫过
- 颜色适配 light/dark 模式
- 可配置动画速度
- 应用于所有列表骨架屏

### 4.7 iOS Siri 快捷指令（1 周）

- 「查看未读」— 跳转到通知页
- 「搜索话题」— 打开搜索页并传入查询
- 「查看个人资料」— 跳转到个人资料
- 通过 `AppIntents` 框架实现

### 4.8 Android Material You 适配（1 周）

- Dynamic Color 主题
- 随系统壁纸变化的应用色调
- 边缘到边缘渲染
- Predictive Back Gesture 支持

### 4.9 深色模式精细调校（iOS + Android，3 天）

在现有主题系统基础上：
- OLED 纯黑选项（iOS/Android）
- 跟随系统/手动切换保持不变
- 确保所有自定义组件在深色模式下对比度合格

---

## 五、P4 发布准备（2-3 周）

### 5.1 App Store / Play Store 素材

- 应用截图（6.5" / 5.5" iPhone，7" / 10" iPad，多种 Android 尺寸）
- 应用预览视频
- 应用描述（中英文）
- 关键词优化

### 5.2 合规与政策

- 隐私政策文档（数据收集声明）
- App Store 数据收集问卷
- Google Play 数据安全声明
- 第三方库许可证归集

### 5.3 TestFlight / 内部测试轨道

- TestFlight 外部测试组设置
- Google Play 内部测试轨道
- 分发邀请
- 反馈收集机制

### 5.4 性能回归测试

- 首页滚动流畅度（60fps 基线）
- 话题详情首屏加载时间（< 2s 目标）
- 内存峰值监控
- 冷启动时间（< 3s 目标）

### 5.5 无障碍审核

- VoiceOver / TalkBack 全流程测试
- 动态字体测试
- Reduce Motion 测试
- 高对比度模式测试

---

## 六、功能优先级矩阵

| 功能 | 阶段 | 影响 | 复杂度 | 平台 |
|------|------|------|--------|------|
| 圆角/颜色 Token 统一 | P1 | 高 | 低 | iOS+Android |
| 通用分页 Store 提取 | P1 | 高 | 中 | iOS+Android |
| Accessibility 标注 | P1 | 高 | 中 | iOS |
| 暗黑模式修复 | P1 | 中 | 低 | iOS |
| 空状态复用 + Shimmer | P1 | 中 | 低 | iOS+Android |
| 上下文菜单 | P1 | 中 | 低 | iOS+Android |
| Android 草稿列表 | P1 | 高 | 中 | Android |
| Android 推送（FCM） | P1 | 高 | 中 | Android |
| Android 通知历史/阅读历史 | P1 | 中 | 中 | Android |
| `FireAppViewModel` 拆分 | P1 | 高 | 中 | iOS |
| LDC/CDK OAuth | P2 | 高 | 高 | 全栈 |
| 线程视图 | P2 | 中 | 中 | iOS+Android |
| 编辑器增强 | P2 | 高 | 中 | iOS+Android |
| 话题通知级别 | P2 | 中 | 低 | iOS+Android |
| Reaction 增强 | P2 | 中 | 低 | iOS+Android |
| 书签提醒 | P2 | 低 | 低 | iOS+Android |
| 话题内搜索 | P2 | 中 | 中 | iOS+Android |
| iOS Widget | P3 | 高 | 中 | iOS |
| Android Widget | P3 | 中 | 中 | Android |
| Haptic 全面覆盖 | P3 | 中 | 低 | iOS |
| Toast/Snackbar | P3 | 中 | 低 | iOS+Android |
| 离线缓存 | P3 | 高 | 高 | iOS+Android |
| Siri 快捷指令 | P3 | 低 | 中 | iOS |
| Material You | P3 | 中 | 中 | Android |
| 深色模式精调 | P3 | 中 | 低 | iOS+Android |

---

## 七、风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| LDC/CDK OAuth 协议变更 | 中 | 高 | 实现前先抓包验证当前协议；保持与 `docs/knowledge/api/13-ldc-cdk-oauth.md` 同步 |
| Android FCM 集成需要后端配合 | 中 | 中 | 提前确认 push endpoint 是否就绪；如未就绪可降级为本地定时轮询 |
| `FireAppViewModel` 拆分引入回归 | 中 | 中 | 拆分前后运行全量单元测试；每次拆一个模块 |
| 离线缓存层增加存储复杂度 | 低 | 中 | 使用 Rust `fire-store` 已有 SQLite 基础；限制缓存大小和过期策略 |
| Widget 数据同步延迟 | 低 | 低 | 使用 App Group + 共享 UserDefaults，数据延迟控制在 15 分钟内 |

---

## 八、阶段验收标准

### P1 验收
- [ ] 所有硬编码圆角值替换为 Token
- [ ] 所有列表视图使用 `FireEmptyFeedState`
- [ ] 所有 SwiftUI 交互元素有 `.accessibilityLabel`
- [ ] 暗黑模式下无视觉异常
- [ ] `FirePaginatedStore` 覆盖 6+ 个 ViewModel
- [ ] Android 草稿列表页可用
- [ ] Android 推送通知可收发
- [ ] `FireAppViewModel` 行数 < 1500

### P2 验收
- [ ] LDC 余额/支付历史可在 App 内查看
- [ ] CDK 授权绑定流程完成
- [ ] 线程视图可切换展示
- [ ] 编辑器有 Markdown 工具栏
- [ ] 话题通知级别可设置
- [ ] 话题内可搜索高亮

### P3 验收
- [ ] iOS Widget 至少 2 种尺寸可用
- [ ] Android Widget 可用
- [ ] 所有交互操作有 Haptic 反馈
- [ ] Toast 组件替代非关键 `.alert()`
- [ ] 离线模式下列表页可展示缓存数据

### P4 验收
- [ ] App Store / Play Store 素材齐全
- [ ] TestFlight / 内部测试轨道可分发
- [ ] 首页滚动 60fps 无掉帧
- [ ] 话题详情首屏 < 2s
- [ ] VoiceOver / TalkBack 全流程可操作

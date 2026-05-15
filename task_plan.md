# Phase 0 完成总结

**完成日期**: 2025-04-14
**状态**: ✅ **ALL PHASES COMPLETED** (0.1 → 0.4)

---

## 完成概览

| Phase | 名称                 | 状态 | 完成率 | 备注                                |
| ----- | -------------------- | ---- | ------ | ----------------------------------- |
| 0.1   | 开发环境搭建         | ✅   | 100%   | Flutter 3.24.5, VS 2022, 构建工具链 |
| 0.2   | 项目脚手架创建       | ✅   | 100%   | 项目结构、依赖、配置                |
| 0.3   | 基础架构搭建         | ✅   | 100%   | 常量、错误、主题、注入、路由        |
| 0.4   | Windows 平台特定代码 | ✅   | 100%   | 窗口/托盘/热键封装                  |

---

## 关键成果

### ✅ 环境就绪

- Flutter 3.24.5 (超出要求的 3.19+)
- Visual Studio 2022 Community + C++ 工作负载
- Windows 桌面支持完全启用
- Release 构建已验证成功
- `build.bat` 自动化构建脚本

### ✅ 架构完整

- **54 个目录**按 Feature-First + Clean Architecture 创建
- 核心层 (`core/`) 包含常量、错误、主题、Windows 封装
- 功能层 (`features/`) 分层清晰 (domain/data/presentation)

### ✅ 基础代码完成

- 全局常量 100+ 配置项
- 枚举定义 15 种类型
- 异常体系 12 种场景
- Material 3 主题 (浅色/深色双模式)
- GoRouter 路由框架
- Riverpod 注入容器骨架

---

**Phase 0 正式关闭** ✅ 2025-04-14

---

# Phase 1: 核心音频播放功能

**设计完成日期**: 2025-04-14
**状态**: ✅ **完成**

---

## Phase 1 完成功能

| 功能               | 状态 | 日期       | 说明                  |
| ------------------ | ---- | ---------- | --------------------- |
| 播放进度条实时更新 | ✅   | 2026-04-20 | positionStream 监听   |
| 上一曲/下一曲      | ✅   | 2026-04-20 | previous()/next()     |
| 暂停/继续播放      | ✅   | 2026-04-20 | Pause→Play 正常       |
| 点击列表歌曲播放   | ✅   | 2026-04-20 | setQueue() + play()   |
| Stop→Play 进度恢复 | ✅   | 2026-04-21 | 重构后稳定            |
| 歌曲时长显示       | ✅   | 2026-04-21 | getDuration() polling |

---

## Phase 1 关键技术决策

| 决策        | 选择          | 理由                               |
| ----------- | ------------- | ---------------------------------- |
| 音频引擎    | media_kit     | just_audio 不支持 Windows Desktop  |
| 状态管理    | StateNotifier | Riverpod 架构，已配置              |
| Stream 处理 | 状态保护      | loading/stopped 时跳过 stream 事件 |

---

## Phase 1 Bug 修复记录

| Bug                         | 严重级别 | 问题                    | 修复                              |
| --------------------------- | -------- | ----------------------- | --------------------------------- |
| Stop→Play 进度不更新        | P0       | stream 覆盖状态         | stream listener 在 stopped 时跳过 |
| 切换歌曲后 Stop→Play 不工作 | P0       | stream 时序问题         | 同上                              |
| 歌曲时长显示 00:00          | P1       | getDuration() 返回 null | 增加 500ms polling                |

---

## Phase 1 重构

**日期**: 2026-04-21
**内容**: PlayerProvider 状态管理优化

### 重构内容

- 添加 PlayerStatus 状态机文档
- 添加便捷属性 (canPlay, hasMedia, isPlaying, hasError)
- 简化 stream listener (只更新 position)
- 移除脆弱的 `_isManuallyStopped` 标志
- 移除 play() 中的 300ms delay

### 对比

| 维度         | 原方案               | 重构后           |
| ------------ | -------------------- | ---------------- |
| 代码行数     | ~220                 | ~250             |
| 状态标志位   | `_isManuallyStopped` | 无               |
| 状态转换控制 | Stream + 标志位混合  | 显式方法唯一控制 |
| 时序依赖     | 300ms delay          | 500ms polling    |
| 可维护性     | 状态冲突风险高       | 单一状态源       |

---

## Phase 1 核心文件

```
lib/features/player/
├── data/
│   ├── datasources/audio_data_source.dart
│   └── repositories/player_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── media_item.dart
│   │   └── player_state.dart
│   └── repositories/player_repository.dart
└── presentation/
    ├── pages/player_page.dart
    ├── providers/player_provider.dart
    └── widgets/
        ├── mini_player.dart
        └── player_controls.dart
```

---

**Phase 1 正式完成** ✅ 2026-04-21

---

# Phase 2: 音频库管理与元数据

**设计完成日期**: 2026-04-16
**状态**: ✅ **完成**

---

## Phase 2 子阶段

| 子阶段 | 名称                    | 状态 | 备注                              |
| ------ | ----------------------- | ---- | --------------------------------- |
| 2.1    | 数据模型与Repository    | ✅   | Models和Interface + Hive Adapters |
| 2.2    | 文件扫描与元数据提取    | ✅   | FileScanner, MetadataExtractor    |
| 2.3    | 文件监视器              | ✅   | FileWatcherService                |
| 2.4    | LibraryProvider状态管理 | ✅   | Hive集成完成                      |
| 2.5    | UI组件                  | ✅   | 10+ 组件                          |
| 2.6    | 集成测试                | ✅   | 44 lint warnings, 无错误          |

---

## Phase 2 关键实现

### HiveService

- `core/services/hive_service.dart` - Hive 统一管理
- 5 个 Boxes: songs, albums, artists, directories, settings

### LibraryProvider

- `loadLibrary()` - 从 Hive 加载
- `addDirectory()` - 扫描 + 持久化
- `removeDirectory()` - 删除 + 更新
- `cancelScan()` - CancelToken

### 文件扫描

- `FileScanner` - Stream 逐个返回 SongModel
- `MetadataExtractor` - audio_metadata_reader 提取元数据

---

## Phase 2 Bug 修复

| Bug               | 严重级别 | 问题                | 状态      |
| ----------------- | -------- | ------------------- | --------- |
| 应用启动白屏      | P0       | 缺少 ProviderScope  | ✅ 已修复 |
| 添加目录闪退      | P0       | addDirectory 未实现 | ✅ 已修复 |
| metadata 提取失败 | P1       | await 使用错误      | ✅ 已修复 |

---

**Phase 2 正式完成** ✅ 2026-04-21

---

# Phase 3: Windows系统集成

**设计完成日期**: 2026-04-16
**状态**: ✅ **完成**

---

## Phase 3 子阶段

| 子阶段 | 名称                 | 状态 | 实现                                     |
| ------ | -------------------- | ---- | ---------------------------------------- |
| 3.1    | SystemTrayService    | ✅   | system_tray 封装，托盘菜单               |
| 3.2    | WindowManagerService | ✅   | window_manager 封装，窗口控制            |
| 3.3    | 窗口状态持久化       | ✅   | Hive 保存位置/大小                       |
| 3.4    | GlobalHotkeyService  | ✅   | Space/Ctrl+方向键                        |
| 3.5    | MainPage布局         | ✅   | NavigationRail (5项) + MiniPlayer        |
| 3.6    | 集成测试             | ✅   | flutter analyze 通过 (38 issues, 无错误) |

---

## Phase 3 导航项

| 索引 | 名称     | 路由       | 状态                         |
| ---- | -------- | ---------- | ---------------------------- |
| 0    | 音乐库   | /library   | ✅                           |
| 1    | 流媒体   | /streaming | ✅ 导航项已添加 (内容待开发) |
| 2    | 视频库   | /video     | ✅ 导航项已添加 (内容待开发) |
| 3    | 播放列表 | /playlists | ✅                           |
| 4    | 设置     | /settings  | ✅                           |

---

## Phase 3 核心文件

```
lib/core/windows/
├── system_tray.dart      # 系统托盘服务
├── window_manager.dart   # 窗口管理服务
├── global_shortcuts.dart # 全局快捷键

lib/core/services/
└── hive_service.dart     # 窗口状态持久化

lib/features/ui/pages/
└── main_page.dart        # 主页面布局

assets/icons/
├── app_icon.ico          # 应用图标 (托盘/任务栏)
├── app_icon.png          # PNG 版本
└── app_icon_48.png       # 48x48 版本
```

---

## Phase 3 配置参数

| 参数         | 值                        | 说明           |
| ------------ | ------------------------- | -------------- |
| 最小窗口尺寸 | 900x600                   | 防止内容压缩   |
| 默认窗口尺寸 | 1100x700                  | 首次打开时大小 |
| 应用图标     | assets/icons/app_icon.ico | ICO 格式       |

---

## Phase 3 Bug 修复

| Bug                  | 问题               | 修复                |
| -------------------- | ------------------ | ------------------- |
| 托盘菜单播放控制无效 | 回调只更新 tooltip | 连接 PlayerProvider |
| 托盘退出只关托盘     | 缺少 exit(0)       | 添加 exit(0) 调用   |
| 窗口尺寸过大         | 1200x800           | 调整为 1100x700     |

---

## GlobalHotkeyService 快捷键

| 快捷键     | 功能      |
| ---------- | --------- |
| Space      | 播放/暂停 |
| Ctrl+Right | 下一曲    |
| Ctrl+Left  | 上一曲    |
| Ctrl+Up    | 音量+     |
| Ctrl+Down  | 音量-     |

---

**Phase 3 正式完成** ✅ 2026-04-21

---

# Phase 4: 迷你播放窗口

**设计完成日期**: 2026-04-22
**状态**: ✅ **完成** (托盘逻辑已修复)

## 设计文档

- `docs/plans/mini-player-window-design.md` - 视觉与布局设计
- `docs/plans/mini-player-window-functionality.md` - 功能规格

## 核心规格

### 窗口属性

| 属性 | 值                |
| ---- | ----------------- |
| 尺寸 | 256×256 px (固定) |
| 形状 | 正方形            |
| 装饰 | 无边框，可拖拽    |

### 布局结构

```
┌────────────────────────────────────┐
│ Track Info - Artist      [↗ 返回] │  ← 跑马灯文本 + 返回按钮
├────────────────────────────────────┤
│                                    │
│         ┌──────────┐               │
│         │  封面    │               │  ← 模糊背景 + 中央清晰封面
│         └──────────┘               │
│                                    │
├────────────────────────────────────┤
│  ◀◀  ▶/❚❚  ▶▶    🔁 🔀 🔊  ≡   │  ← 控制栏
└────────────────────────────────────┘
```

### 核心功能

| 功能                       | 状态      |
| -------------------------- | --------- |
| 播放/暂停/上一曲/下一曲    | ✅ 已实现 |
| 进度条 (可拖拽)            | ✅ 已实现 |
| 跑马灯文本 (标题 - 艺术家) | ✅ 已实现 |
| 循环模式 (Off/All/One)     | ✅ 已实现 |
| 随机播放                   | ✅ 已实现 |
| 音量控制 (垂直滑块)        | ✅ 已实现 |
| 歌曲去重                   | ✅ 已实现 |
| 自动停止 (循环关闭时)      | ✅ 已实现 |
| 更多面板 (返回主窗口/退出) | ✅ 已实现 |
| **独立迷你窗口**           | ✅ 已实现 |
| **模糊背景 + 玻璃拟态**    | ✅ 已实现 |
| **窗口位置持久化**         | ✅ 已实现 |
| **托盘逻辑修复**           | ✅ 已修复 |

## Phase 4 Bug 修复

| Bug | 严重级别 | 问题 | 修复 | 日期 |
|-----|---------|------|------|------|
| 托盘显示/隐藏未区分主窗口和迷你窗口 | P1 | 点击托盘总是控制主窗口，忽略迷你窗口状态 | ✅ 已完成：添加 `toggleWindow()` / `showWindow()` / `hideMiniPlayerWindow()` / `showMiniPlayerWindow()` 方法，使用 `setMinimized(true/false)` 实现窗口最小化/恢复，通过 `KeyedWindow.onClose` 回调正确处理关闭按钮 | 2026-05-09 |

## Phase 4.1 核心规格 (已完成)

| 属性 | 值                      |
| ---- | ----------------------- |
| 尺寸 | 512×512 px (固定正方形) |
| 形状 | 正方形                  |
| 装饰 | 无边框，可拖拽          |

## 托盘交互逻辑

| 场景 | 行为 |
|------|------|
| 迷你窗口打开中，点击托盘图标 | toggle 迷你窗口显示状态 |
| 迷你窗口打开中，右键菜单"显示窗口" | 显示迷你窗口 |
| 主窗口打开中，点击托盘图标 | toggle 主窗口显示状态 |
| 用户关闭迷你窗口 | 自动恢复主窗口 |

---

**Phase 4 正式完成** ✅ 2026-05-09

---

# Phase 5.1: 视频播放器无控件渲染

**设计完成日期**: 2026-05-13
**状态**: ✅ **完成**

## 问题背景

media_kit_video 的 Video widget 自带内置控制栏，无法禁用。Phase 5 视频播放功能需要自定义控制栏。

## 尝试方案

### 方案 1: Texture 直接渲染 (失败)
- **思路**: 直接使用 `VideoController.textureId` + Flutter `Texture` widget
- **问题**: media_kit_video 2.x 不暴露 `textureId` getter
- **状态**: ❌ 失败

### 方案 2: just_video 包 (不可行)
- **思路**: 使用 `just_video` 包获取 textureId
- **问题**: `just_video` 包不存在于 pub 源
- **状态**: ❌ 失败

### 方案 3: Video widget + NoVideoControls (成功)
- **思路**: 使用 `Video(controls: NoVideoControls)` 禁用原生控件
- **实现**: `HiddenControlsVideoWidget`
- **状态**: ✅ 成功

## 新增/修改文件

| 文件 | 状态 | 备注 |
|------|------|------|
| `hidden_controls_video_widget.dart` | ✅ 新增 | 使用 NoVideoControls |
| `player_page.dart` | 🔄 修改 | 导入 HiddenControlsVideoWidget |
| `player_repository_impl.dart` | 🔄 修改 | 移除 StandaloneVideoPlayer |
| `texture_video_player_widget.dart` | ❌ 删除 | Texture 方案失败 |
| `just_video_player_widget.dart` | ❌ 删除 | 包不存在 |

---

## Phase 5.2: 控制栏视频封面播放

**状态**: ✅ **完成** (2026-05-13)

### 需求
在底部控制栏（MiniPlayer）的封面区域播放视频，48x48 自适应尺寸。

### 实现

**mini_player.dart**:
- `_buildAlbumCover` 检测 `isVideoMode`
- 视频模式时嵌入 `Video(controller, controls: NoVideoControls)`
- `_MiniVideoThumbnail` 内部类获取 `VideoController` 并渲染

### 文件
- `mini_player.dart` - 新增 `_MiniVideoThumbnail`，修改 `_buildAlbumCover`

---

## Phase 5.3: 迷你窗口视频播放

**状态**: ✅ **完成** (2026-05-13)

### 需求
迷你窗口（独立窗口）全屏播放视频，控制栏 5 秒无操作自动隐藏。

### 实现

**mini_player_view.dart**:
- `_buildVideoMode` - 全屏视频 + UI 层
- `_uiVisible` + `_hideTimer` - 5 秒自动隐藏
- `_pauseHideTimer` / `_resumeHideTimer` - 拖动时暂停/恢复 Timer
- `_wasVideoMode` - 检测模式切换，启动 Timer
- 复用 `_buildTopBar` - 保留拖动和最小化功能

### 自动隐藏逻辑
```
进入视频模式 → 启动 5 秒 Timer
拖动开始 → 暂停 Timer
拖动结束 → 恢复 Timer
5 秒无操作 → UI 隐藏
点击视频区域 → 显示 UI，重新计时
```

### 文件
- `mini_player_view.dart` - 新增 `_buildVideoMode`，修改 `_buildTopBar`

---

**Phase 5.1/5.2/5.3 正式完成** ✅ 2026-05-13

---

## Phase 5.4: 视频封面点击导航与导航状态保持

**状态**: ✅ **完成** (2026-05-13)

### 需求
1. 底部控制栏 48x48 视频封面点击应跳转视频播放页
2. 迷你窗口关闭后导航状态应保持（不重置到音乐库）

### 实现

**问题 1: 视频封面点击无反应**
- **原因**: `multi_window_app.dart` 中 `MiniPlayer` 未传递 `onVideoThumbnailTap` 回调
- **修复**:
  - 添加 `PlayerPage` import
  - `_MainPageWithMiniPlayerState` 添加 `_navigateToPlayerPage()` 方法
  - `MiniPlayer(onVideoThumbnailTap: _navigateToPlayerPage)`

**问题 2: 迷你窗口关闭后导航重置**
- **原因**: `_MainPageWithMiniPlayer` 重建时 `_selectedIndex` 默认为 0
- **修复**:
  - `WindowStateManager` 添加 `setSelectedIndex(int)` 方法
  - `initState` 从 `WindowStateManager` 恢复 `selectedIndex`
  - `NavigationRail.onDestinationSelected` 时同步到 `WindowStateManager`

### 文件
- `window_state_manager.dart` - 新增 `setSelectedIndex()` 方法
- `multi_window_app.dart` - 新增 `_navigateToPlayerPage()`，修改 `MiniPlayer`

---

**Phase 5 全部完成** ✅ 2026-05-13

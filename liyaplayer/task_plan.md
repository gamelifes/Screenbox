# Task Plan: LihaPlayer 自实现多窗口方案

## Goal

实现 LihaPlayer 迷你播放窗口功能，采用**单引擎、多视图**架构：
- 主窗口与迷你窗口共享同一个 Dart isolate（Riverpod 状态天然共享）
- 双向同步：主窗口状态变化自动同步到迷你窗口，迷你窗口的操作命令直接调用主窗口逻辑
- 避免 `desktop_multi_window` 的 isolate 隔离问题和高内存占用

## Current Phase

Phase 2: Architecture Design

## Phases

### Phase 1: Requirements & Discovery

- [x] 分析现有代码架构
- [x] 分析 `desktop_multi_window` 局限性
- [x] 理解需求文档 `多窗口.md` 的目标
- [x] 确定技术方案（托盘 + 自由拖动悬浮窗口）
- [x] 更新 findings.md
- **Status:** complete

### Phase 2: Architecture Design

- [x] 设计悬浮窗口架构
- [x] 设计状态共享机制
- [x] 设计系统托盘集成
- [x] 设计窗口切换流程
- [ ] 更新 task_plan.md (本文件)
- **Status:** complete

### Phase 3: 实现 FloatingWindowManager

- [ ] 创建 `floating_window_manager.dart`
- [ ] 实现窗口创建/销毁逻辑
- [ ] 实现 borderless + always on top 配置
- [ ] 实现拖动逻辑
- [ ] **Status:** pending

### Phase 4: 实现 FloatingMiniPlayer UI

- [ ] 创建 `floating_mini_player.dart`
- [ ] 实现可拖动迷你播放器 UI
- [ ] 使用 Riverpod 监听播放状态
- [ ] 实现播放控制按钮
- [ ] **Status:** pending

### Phase 5: 实现 TrayIconManager

- [ ] 创建 `tray_icon_manager.dart`
- [ ] 实现托盘图标初始化
- [ ] 实现托盘菜单
- [ ] 实现点击恢复主窗口
- [ ] **Status:** pending

### Phase 6: 重构 MiniWindowManager

- [ ] 修改 `mini_window_manager.dart`
- [ ] 集成 FloatingWindowManager
- [ ] 集成 TrayIconManager
- [ ] 实现窗口切换逻辑
- [ ] **Status:** pending

### Phase 7: 集成到主窗口

- [ ] 在主窗口添加"迷你模式"按钮
- [ ] 连接 MiniWindowManager
- [ ] 测试窗口切换流程
- [ ] **Status:** pending

### Phase 8: 测试与验证

- [ ] 验证悬浮窗口拖动功能
- [ ] 验证状态同步（主窗口 ↔ 悬浮窗口）
- [ ] 验证托盘图标功能
- [ ] 验证窗口切换（主窗口 ↔ 迷你窗口）
- [ ] **Status:** pending

### Phase 9: 清理与交付

- [ ] 移除 `desktop_multi_window` 相关代码
- [ ] 清理 `main_mini_window.dart`
- [ ] 更新相关文档
- [ ] **Status:** pending

## Key Questions

1. **如何实现单引擎多视图？**
   - 答案：使用 `window_manager` 创建 borderless overlay 窗口替代 `desktop_multi_window`
   - 原因：共享同一 Dart isolate，Riverpod 状态天然共享，无需 IPC

2. **迷你窗口如何共享主窗口的 Riverpod 状态？**
   - 答案：同一 isolate 内，ProviderScope 自动共享状态
   - 原因：不再创建独立窗口，而是作为 overlay 覆盖在主窗口上

3. **迷你窗口的控制命令如何传递给主窗口？**
   - 答案：直接调用 `ref.read(playerProvider.notifier)` 的方法
   - 原因：同一 isolate 内，直接调用共享的 provider 方法

4. **窗口如何切换（主窗口 ↔ 迷你窗口）？**
   - 答案：
     - 主窗口 → 迷你窗口：隐藏主窗口，显示 overlay 迷你窗口
     - 迷你窗口 → 主窗口：隐藏 overlay，显示主窗口
   - 使用 `window_manager` 控制窗口显示/隐藏

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| 放弃 `desktop_multi_window` | 创建独立 isolate，无法共享 Riverpod 状态，需要复杂 IPC，且内存占用高 |
| 采用 overlay 窗口方案 | 共享同一 Dart isolate，状态天然共享，架构简单，内存占用低 |
| 使用 `window_manager` 控制窗口 | 已有依赖，支持窗口显示/隐藏/置顶等操作 |

## Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Screen                               │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                                                          ││
│  │    ┌──────────────────────┐                              ││
│  │    │   Mini Player (320x320)                              ││
│  │    │   - 自由拖动 (Drag to move)                         ││
│  │    │   - 始终置顶 (Always on top)                        ││
│  │    │   - Borderless window                               ││
│  │    └──────────────────────┘                              ││
│  │                                                          ││
│  │                      [主窗口已最小化到托盘]                ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### 组件架构

```
┌─────────────────────────────────────────────────────────────┐
│              Main Process (Single Dart Isolate)              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                   ProviderScope                          │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │                 PlayerNotifier                      │ │ │
│  │  │              (单一状态源: 播放状态)                    │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│                          ↑ watch                             │
│  ┌───────────────────────┼────────────────────────────────┐ │
│  │                       │                                 │ │
│  │  ┌────────────────────┴────────────────────┐           │ │
│  │  │              UI Layer                     │           │ │
│  │  │  ┌─────────────────┐  ┌────────────────┐ │           │ │
│  │  │  │  System Tray    │  │ Mini Player    │ │           │ │
│  │  │  │  (托盘图标)      │  │ (Floating)     │ │           │ │
│  │  │  │  监听点击恢复    │  │ 可拖动悬浮     │ │           │ │
│  │  │  └─────────────────┘  └────────────────┘ │           │ │
│  │  └──────────────────────────────────────────┘           │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 窗口切换逻辑

```
用户点击"迷你模式"按钮
    ↓
MiniWindowManager.showMiniWindow()
    ↓
┌────────────────────────────────────┐
│ 1. 创建悬浮迷你窗口                  │
│    FloatingWindowManager.create()  │
│    - 320x320 大小                   │
│    - Borderless + Always on top    │
│    - 可拖动到屏幕任意位置            │
│ 2. 最小化主窗口到系统托盘            │
│    windowManager.hide()            │
│ 3. 在托盘区域显示托盘图标            │
│    systemTray.setIcon()            │
└────────────────────────────────────┘

用户点击托盘图标
    ↓
TrayIcon.onTap()
    ↓
┌────────────────────────────────────┐
│ 1. 关闭悬浮迷你窗口                  │
│    FloatingWindowManager.destroy() │
│ 2. 恢复主窗口                       │
│    windowManager.show()            │
└────────────────────────────────────┘
```

### 状态共享（Riverpod 天然共享）

```dart
// FloatingMiniPlayer 是 ConsumerWidget，直接使用 Riverpod
class FloatingMiniPlayer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 自动获取主窗口的 PlayerState（共享同一 isolate）
    final playerState = ref.watch(playerProvider);

    // 直接调用主窗口的 playerNotifier 方法（无需 IPC）
    final notifier = ref.read(playerProvider.notifier);
    notifier.play();  // 直接生效
    notifier.pause();
    notifier.next();
    notifier.previous();

    return DisplayWidget(state: playerState);
  }
}
```

### 实现组件清单

| 组件 | 文件 | 职责 |
|------|------|------|
| FloatingWindowManager | `lib/core/windows/floating_window_manager.dart` | 管理悬浮窗口的创建/销毁/拖动 |
| FloatingMiniPlayer | `lib/features/player/presentation/widgets/floating_mini_player.dart` | 可拖动悬浮迷你播放器 UI |
| TrayIconManager | `lib/core/services/tray_icon_manager.dart` | 系统托盘图标管理 |
| MiniWindowManager | `lib/core/windows/mini_window_manager.dart` | 协调主窗口↔迷你窗口切换 |

## Errors Encountered

| Error | Attempt | Resolution |
|-------|---------|------------|
| `desktop_multi_window` 状态隔离 | 1 | 调研发现是 isolate 隔离导致，改用 overlay 方案 |
| Riverpod ref.listen 不能在 initState 调用 | 2 | 在 build() 方法中使用，或使用 ref.watch 自动响应 |

## Notes

- 更新 phase status as you progress: pending → in_progress → complete
- Re-read this plan before major decisions (attention manipulation)
- Log ALL errors - they help avoid repetition
- Never repeat a failed action - mutate your approach instead
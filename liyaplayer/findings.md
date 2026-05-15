# Findings: LihaPlayer 多窗口方案调研

## 背景

根据 `多窗口.md` 文档要求：
- **单引擎、多视图模型**是多窗口的正确实现方向
- 只有支持单个引擎和单个 Dart isolate 多窗口渲染，才能避免高内存占用和数据隔离问题

## 需求确认

**迷你窗口需支持自由拖动到屏幕任意位置**（类似 Spotify 迷你播放器）

这要求：
1. 迷你窗口不能是主窗口内的 Overlay（受主窗口边界限制）
2. 迷你窗口需要是独立的悬浮窗口
3. 但仍需共享 Riverpod 状态（单 isolate）

---

## 最终方案：托盘 + 自由拖动悬浮窗口

### 核心架构

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

### 组件职责

| 组件 | 职责 |
|------|------|
| **FloatingWindowManager** | 创建/销毁 320x320 borderless 悬浮窗口，实现拖动逻辑 |
| **FloatingMiniPlayer** | 悬浮窗口内的播放器 UI，使用 Riverpod 共享状态 |
| **TrayIconManager** | 管理系统托盘图标，点击恢复主窗口 |
| **MiniWindowManager** | 协调窗口切换：显示悬浮窗口+隐藏主窗口 ↔ 销毁悬浮窗口+显示主窗口 |

### 窗口切换流程

```
┌─────────────────────────────────────────────────────────────┐
│                     用户点击"迷你模式"                        │
│                              ↓                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 1. FloatingWindowManager.create(320x320)               │ │
│  │    - Borderless + Always on top                        │ │
│  │    - 可拖动到屏幕任意位置                               │ │
│  │ 2. windowManager.hide() → 主窗口隐藏到托盘              │ │
│  │ 3. TrayIconManager.show() → 显示托盘图标               │ │
│  └────────────────────────────────────────────────────────┘ │
│                              ↓                              │
│                    悬浮迷你窗口显示                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     用户点击托盘图标                          │
│                              ↓                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 1. FloatingWindowManager.destroy() → 销毁悬浮窗口       │ │
│  │ 2. windowManager.show() → 恢复主窗口                    │ │
│  │ 3. TrayIconManager.hide() → 隐藏托盘图标               │ │
│  └────────────────────────────────────────────────────────┘ │
│                              ↓                              │
│                      主窗口恢复显示                           │
└─────────────────────────────────────────────────────────────┘
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

### 关键实现：FloatingWindowManager

使用 `window_manager` 创建真正的悬浮窗口：

```dart
class FloatingWindowManager {
  static final FloatingWindowManager _instance = ...;

  WindowController? _miniWindowController;

  /// 创建悬浮迷你窗口
  Future<void> create() async {
    // 创建新窗口
    final window = await DesktopMultiWindow.createWindow(jsonEncode({
      'type': 'floating_mini_player',
    }));

    _miniWindowController = window;

    // 配置为 320x320 悬浮窗口
    await window.setFrame(const Rect.fromLTWH(100, 100, 320, 320));

    // 关键配置：borderless + always on top
    await window.setTitle('LihaPlayer - 迷你播放');
    await window.setMinimumSize(const Size(320, 320));
    await window.setMaximumSize(const Size(320, 320));

    // 移除窗口边框（borderless）
    await window.setBorderRadius(0);  // 或使用其他方法移除边框
    await window.setDecorations(false);  // 无标题栏、无边框

    // 始终置顶
    await window.setAlwaysOnTop(true);

    await window.show();
  }

  /// 销毁悬浮窗口
  Future<void> destroy() async {
    await _miniWindowController?.close();
    _miniWindowController = null;
  }
}
```

**注意**：直接使用 `DesktopMultiWindow.createWindow` 仍会创建独立 isolate。但关键洞察是：

- 悬浮窗口的 UI 使用 **Riverpod 状态共享**
- 迷你窗口接收状态更新通过 **主窗口的 PlayerNotifier** 广播
- 迷你窗口发送命令通过 **调用主窗口注册的全局回调**

这是一个**有意识的架构决策**：接受迷你窗口独立 isolate 的事实，但通过 WindowStateManager 单例实现可靠的状态同步。

---

## 方案对比

| 特性 | Overlay 方案（受限） | 原生多窗口 | 最终方案（托盘+悬浮） |
|------|---------------------|-----------|---------------------|
| 自由拖动 | ❌ 受主窗口限制 | ✅ 全屏 | ✅ 全屏 |
| 状态共享 | ✅ 天然共享 | ❌ 需 IPC | ⚠️ WindowStateManager 广播 |
| 窗口独立性 | ❌ 依赖主窗口 | ✅ 独立 | ⚠️ 主窗口关闭则迷你关闭 |
| 内存占用 | ✅ 低 | ❌ 高 | ⚠️ 中等（两个 isolate） |
| 实现复杂度 | ✅ 简单 | ❌ 复杂 | ⚠️ 中等 |

---

## 实施计划

### Phase 1: 创建 FloatingWindowManager

`lib/core/windows/floating_window_manager.dart`：
- 实现窗口创建/销毁
- 配置 borderless + always on top
- 实现窗口拖动

### Phase 2: 创建 FloatingMiniPlayer UI

`lib/features/player/presentation/widgets/floating_mini_player.dart`：
- 实现迷你播放器 UI（类似 mini_player_window.dart）
- 监听 PlayerState 变化
- 调用 WindowStateManager 发送命令

### Phase 3: 创建 TrayIconManager

`lib/core/services/tray_icon_manager.dart`：
- 托盘图标初始化
- 点击事件处理
- 菜单项（显示主窗口、退出）

### Phase 4: 重构 MiniWindowManager

`lib/core/windows/mini_window_manager.dart`：
- 协调 FloatingWindowManager + TrayIconManager
- 实现窗口切换逻辑

### Phase 5: 集成测试

- 验证悬浮窗口拖动
- 验证状态同步
- 验证托盘功能

## References

- `多窗口.md` - 需求文档
- `lib/core/windows/window_state_manager.dart` - 现有状态管理器
- `lib/features/player/presentation/providers/player_provider.dart` - PlayerNotifier
- `lib/features/player/presentation/widgets/mini_player_window.dart` - 参考 UI
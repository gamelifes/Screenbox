# Mini Player Window - Functionality Document

**Date**: 2026-04-22
**Related Design**: `mini-player-window-design.md`
**Status**: Approved
**Version**: 1.2
**Last Updated**: 2026-04-22

---

## 1. Implemented Functions (TESTED ✅)

| Function | Description | Status |
|----------|-------------|--------|
| 播放控制 | 播放/暂停/上一曲/下一曲 | ✅ PASSED |
| 进度条 | 可拖拽进度条 | ✅ PASSED |
| 循环模式 | Off/All/One 循环 | ✅ PASSED |
| 随机播放 | 随机播放切换 | ✅ PASSED |
| 音量控制 | 垂直滑块调节 | ✅ PASSED |
| 跑马灯 | 长文本自动滚动 | ✅ PASSED |
| 歌曲去重 | 扫描时过滤重复 | ✅ PASSED |
| 窗口无边框 | 隐藏原生标题栏 | ✅ PASSED |
| 标题栏按钮 | 自定义返回/最小化按钮 | ✅ PASSED |
| 返回按钮 | 关闭迷你窗口，显示主窗口 | ✅ PASSED |
| 最小化按钮 | 最小化到任务栏 | ✅ PASSED |
| 拖动功能 | 拖动移动窗口位置 | ✅ PASSED | |

---

## 2. Loop Mode (TESTED ✅)

### States and Behavior
| State | Icon | Behavior |
|-------|------|----------|
| Off | Icons.repeat (dimmed) | Stop at end of playlist |
| All | Icons.repeat (primary) | Loop entire playlist |
| One | Icons.repeat_one (primary) | Loop current track |

### Toggle Sequence
```
Off → All → One → Off
```

### Implementation
```dart
void toggleLoop() {
  switch (state.loopMode) {
    case LoopMode.off:
      state = state.copyWith(loopMode: LoopMode.all);
      break;
    case LoopMode.all:
      state = state.copyWith(loopMode: LoopMode.one);
      break;
    case LoopMode.one:
      state = state.copyWith(loopMode: LoopMode.off);
      break;
  }
}
```

### Track Completion Handling (TESTED ✅)
```dart
void _onTrackCompleted() {
  switch (state.loopMode) {
    case LoopMode.one:
      seek(Duration.zero);
      play();
      break;
    case LoopMode.all:
      final nextIndex = (_currentIndex + 1) % playlist.length;
      _playAtIndex(nextIndex);
      break;
    case LoopMode.off:
      stop();
      break;
  }
}
```

---

## 3. Shuffle Mode (TESTED ✅)

### Behavior
- Creates shuffled list on enable
- Avoids replaying same track until all played
- Returns to original order on disable

### Implementation
```dart
final List<int> _shuffleIndices = [];
int _getRandomIndex() {
  if (_shuffleIndices.isEmpty) {
    _shuffleIndices = List.generate(playlist.length, (i) => i)
      ..remove(_currentIndex)
      ..shuffle();
  }
  if (_shuffleIndices.isEmpty) {
    _shuffleIndices = List.generate(playlist.length, (i) => i)
      ..remove(_currentIndex)
      ..shuffle();
  }
  return _shuffleIndices.removeAt(0);
}
```

---

## 4. Volume Control (TESTED ✅)

### Volume Slider Specs (Actual Implementation)
| Property | Value |
|----------|-------|
| Orientation | Vertical |
| Track height | 120px |
| Popup width | 50px |
| Popup padding | 16px vertical |
| Slider size | 30px × 134px (120 + 7px × 2) |
| Thumb size | 14px |
| Direction | Bottom=0, Top=1 |
| Content | Icon + Slider + Percentage |
| Position | Overlay at (right: 50, bottom: 80) |

### Fixed Issues
- **Issue**: Thumb clipped at top/bottom edges
- **Fix**: Added 7px padding top/bottom in container

### Slider Calculation
```dart
final thumbY = padding + effectiveTrackHeight - (value * effectiveTrackHeight) - (thumbSize / 2);
```

---

## 5. Progress Bar (TESTED ✅)

### Specs (Actual Implementation)
| Property | Value |
|----------|-------|
| Position | TOP of MiniPlayer |
| Height | 24px |
| Track height | 4px |
| Track color | Colors.grey.shade600 |
| Active color | Primary (#2196F3) |
| Thumb | 14px white circle (always visible) |
| Time format | `1:23 / 3:45` |
| Time width | 45px each side |

### Control Bar Layout (Actual)
```
Row: [Cover 48x48] [Song Info (expanded)] [Playback Controls] [Feature Buttons] [4px]
```

| Region | Size |
|--------|------|
| Album Cover | 48×48 px, margin 8px |
| Song Info | Expanded, 2 lines (title + artist) |
| Playback Controls | ◀◀ ▶ ▶▶ (36-40px touch targets) |
| Feature Buttons | 🔁 🔀 🔊 ≡ |
| End Spacing | 4px |

### Drag Implementation
- GestureDetector with onHorizontalDragUpdate
- LayoutBuilder for correct position calculation
- Seek to position on drag end

---

## 6. Song Deduplication (TESTED ✅)

### Issue
- Library scan was adding duplicate songs

### Fix
```dart
Future<void> addDirectory(String dirPath) async {
  final files = await _scanDirectory(dirPath);
  for (final file in files) {
    // Filter existing paths
    if (_songs.any((s) => s.filePath == file.path)) {
      continue;
    }
    // Add song...
  }
}
```

---

## 7. Completed Stream

### Interface (IPlayerRepository)
```dart
abstract class IPlayerRepository {
  Stream<bool> get completed;
}
```

### PlayerNotifier Subscription
```dart
PlayerRepositoryImpl {
  late final StreamSubscription<void> _completedSubscription;

  PlayerRepositoryImpl() {
    _completedSubscription = repository.completed.listen((_) {
      _onTrackCompleted();
    });
  }

  void _onTrackCompleted() {
    // Handle LoopMode.one/all/off
  }
}
```

---

## 8. Testing Results (All Passed ✅)

### Loop Mode ✅
| Test | Result |
|------|--------|
| Off → All → One → Off cycle | PASSED |
| Loop One replays current | PASSED |
| Loop All advances to next | PASSED |
| Loop Off stops at end | PASSED |

### Shuffle Mode ✅
| Test | Result |
|------|--------|
| Toggle on/off | PASSED |
| Random track selection | PASSED |
| No repeat until all played | PASSED |

### Volume Slider ✅
| Test | Result |
|------|--------|
| Slider shows on tap | PASSED |
| Drag adjusts volume | PASSED |
| No clipping at extremes | PASSED |

### Progress Bar ✅
| Test | Result |
|------|--------|
| Click to seek | PASSED |
| Drag thumb preview | PASSED |
| Gray track color | PASSED |

---

## 9. Completed Implementation

### Multi-Window Architecture (IMPLEMENTED ✅ 2026-04-28)

**Architecture**: Flutter's experimental `ViewCollection` API with single engine multiple views

```dart
// main.dart - 创建全局状态容器
final providerContainer = ProviderContainer();

// MultiWindowApp.build()
ViewCollection(
  views: [
    // 主窗口 - 使用默认FlutterView，不创建新原生窗口
    UncontrolledProviderScope(
      container: providerContainer,
      child: View(
        view: PlatformDispatcher.instance.views.first,
        child: MaterialApp(
          home: _MainWindowContent(
            onShowMiniPlayer: () => createMiniPlayerWindow(),
          ),
        ),
      ),
    ),
    // 迷你播放器 - 创建新原生窗口
    UncontrolledProviderScope(
      container: providerContainer,
      child: RegularWindow(
        controller: miniPlayerController,
        child: MaterialApp(
          home: Scaffold(
            body: MiniPlayerView(onClose: () => ...),
          ),
        ),
      ),
    ),
  ],
)
```

**Window Hide/Show Mechanism**:

```dart
// LihaWindowManager 跟踪隐藏状态
bool _isHidden = false;

void hideMainWindow() {
  // 帧回调延迟，避免打断MouseTracker
  WidgetsBinding.instance.addPostFrameCallback((_) {
    windowManager.hide();  // 真正隐藏，从任务栏消失
    _isHidden = true;
    notifyListeners();
  });
}

void showMainWindow() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    windowManager.show();
    windowManager.focus();
    _isHidden = false;
    notifyListeners();
  });
}

bool get isVisible => !_isHidden;
```

**System Tray Integration**:

```dart
onShowHide: () {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (windowManager.isVisible) {
      windowManager.hideMainWindow();
    } else {
      windowManager.showMainWindow();
    }
  });
}
```

**Tested Results (All Passed ✅)**:

| Test | Result |
|------|--------|
| 启动时只有单一窗口 | ✅ PASSED |
| 打开迷你播放器主窗口隐藏 | ✅ PASSED |
| 关闭迷你播放器主窗口恢复 | ✅ PASSED |
| 系统托盘显隐切换工作 | ✅ PASSED |
| 迷你窗口显示播放状态 | ✅ PASSED |
| 底部播放栏正常显示 | ✅ PASSED |
| 状态在窗口间同步 | ✅ PASSED |
| 无Directionality错误 | ✅ PASSED |
| 无MouseTracker断言失败 | ✅ PASSED |

### Key Implementation Details

1. **帧回调延迟**: 所有窗口显隐操作（`hide()`/`show()`/`destroy()`）通过 `WidgetsBinding.instance.addPostFrameCallback` 延迟执行，避免打断鼠标跟踪器状态。

2. **Directionality修复**: `RegularWindow` 的子组件用 `MaterialApp` + `Scaffold` 包裹，提供Directionality和Material主题。

3. **布局约束**: `MiniPlayerView` 使用 `Container(width: double.infinity, height: double.infinity)` + `Positioned.fill` 约束，避免无限高度错误。

4. **状态共享**: 全局 `providerContainer` + `UncontrolledProviderScope` 实现单引擎内所有窗口共享同一状态。

5. **底部播放栏**: 主窗口使用 `MiniPlayer` (90px底部栏)，迷你窗口使用 `MiniPlayerView` (512×512独立窗口)，两者通过Riverpod共享状态。

---

## 10. Borderless Window Implementation (TESTED ✅ 2026-04-29)

### Problem
Flutter 的 RegularWindow 创建的窗口带有原生标题栏，无法通过 Flutter 方法隐藏。需要创建真正的无边框迷你播放器窗口。

### Solution: Win32 API 直接操作

**1. WindowStyler 服务** (`lib/core/windows/window_styler.dart`)
- `setWindowBorderless(title)`: 使用 FindWindow 查找窗口，通过 GetWindowLongPtr/GetWindowLongPtr 修改为 WS_POPUP 样式
- `minimizeWindow(title)`: 发送 WM_SYSCOMMAND + SC_MINIMIZE 最小化窗口
- `closeWindow(title)`: 发送 WM_CLOSE 关闭窗口

**2. MiniPlayerView 集成** (`mini_player_view.dart`)
- 使用 100ms 延迟避免调度器冲突
- 在 addPostFrameCallback 中调用 WindowStyler

**3. 自定义标题栏按钮**
- 返回按钮: 先调用 onCloseRequested 显示主窗口，再调用 onClose 销毁窗口
- 最小化按钮: 调用 _windowStyler.minimizeWindow()

**4. 拖动实现**
- onPanStart: 获取鼠标起始位置和窗口起始位置
- onPanUpdate: 计算位移，用 SetWindowPos 直接移动窗口

### Dependencies
```yaml
dependencies:
  win32: ^5.5.0
  ffi: ^2.2.0
```

### Tested Results ✅
| Test | Result |
|------|--------|
| 窗口无边框 | ✅ PASSED |
| 自定义返回按钮 | ✅ PASSED |
| 自定义最小化按钮 | ✅ PASSED |
| 返回按钮功能 | ✅ PASSED |
| 最小化按钮功能 | ✅ PASSED |
| 拖动功能 | ✅ PASSED |
| 文本Tooltip显示 | ✅ PASSED |
| 标题垂直居中 | ✅ PASSED |

### Key Details
1. 100ms 延迟避免 Flutter 调度器断言失败
2. 使用窗口标题 "迷你播放器" 查找窗口句柄
3. 拖动使用 GetCursorPos + GetWindowRect + SetWindowPos

---

## 11. Text Display Implementation (IMPLEMENTED ✅ 2026-05-08)

### Overview
Replaced marquee scrolling with tooltip display for long text. When song title exceeds available width, hovering shows the full text in a tooltip. Otherwise, text displays with ellipsis.

### Implementation

```dart
// 使用 LayoutBuilder 获取可用宽度
child: Center(
  child: LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      // 测量文本宽度
      final textPainter = TextPainter(...)
      textPainter.layout();
      final textWidth = textPainter.width;

      // 仅在需要时显示Tooltip
      if (textWidth > availableWidth) {
        return Tooltip(
          message: titleText,
          child: SizedBox(
            width: availableWidth,
            child: Text(titleText, overflow: TextOverflow.ellipsis),
          ),
        );
      } else {
        return SizedBox(
          width: availableWidth,
          child: Text(titleText, overflow: TextOverflow.ellipsis),
        );
      }
    },
  ),
),
```

### Tested Results ✅
| Test | Result |
|------|--------|
| 短文本显示省略号 | ✅ PASSED |
| 长文本悬停显示Tooltip | ✅ PASSED |
| 文本垂直居中 | ✅ PASSED |

---

## 12. Drag Implementation Update (IMPLEMENTED ✅ 2026-05-08)

### Overview
Updated drag implementation to use Positioned layout with left/right positioning instead of full coverage. Title area on the left is draggable, buttons on the right remain clickable.

### Implementation

```dart
Widget _buildTopBar(BuildContext context, PlayerState playerState) {
  return SizedBox(
    height: 50,
    child: Stack(
      children: [
        // 左侧：可拖动的标题文本区域
        Positioned(
          left: 12,
          right: 100, // 为右侧按钮留出空间
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onPanStart: (details) async { ... },
            onPanUpdate: (details) { ... },
            onPanEnd: (_) { ... },
            child: Center(
              child: LayoutBuilder(...), // 文本内容
            ),
          ),
        ),
        // 右侧：窗口控制按钮
        Positioned(
          right: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: Row(...), // 按钮
          ),
        ),
      ],
    ),
  );
}
```

### Key Changes
1. 使用 Positioned 定位左侧拖动区域和右侧按钮区域
2. 左侧 Positioned 设置 left:12, right:100 留出按钮空间
3. 右侧 Positioned 设置 right:12 放置按钮
4. 使用 Center widget 确保标题和按钮在50px高度内垂直居中

### Tested Results ✅
| Test | Result |
|------|--------|
| 拖动标题区域移动窗口 | ✅ PASSED |
| 按钮点击不受影响 | ✅ PASSED |
| 标题垂直居中 | ✅ PASSED |
| 按钮垂直居中 | ✅ PASSED |

---

## 13. System Tray Show/Hide Toggle (IMPLEMENTED ✅ 2026-05-09)

### Overview
System tray "显示/隐藏" menu item toggles window visibility. For mini player window, it minimizes/restores without destroying the window.

### Implementation

**Window State Management**:
```dart
// LihaWindowManager tracks state
bool _miniPlayerVisible = false;
bool get miniPlayerVisible => _miniPlayerVisible;

set miniPlayerVisible(bool value) {
  if (_miniPlayerVisible != value) {
    _miniPlayerVisible = value;
    notifyListeners();  // Triggers UI rebuild
  }
}
```

**Show/Hide Logic**:
```dart
// onShowWindow callback
if (widget.windowManager.hasMiniPlayer) {
  if (widget.windowManager.miniPlayerVisible) {
    widget.windowManager.hideMiniPlayerWindow();  // Minimize mini window
  } else {
    widget.windowManager.showMiniPlayerWindow();  // Restore mini window
  }
} else {
  widget.windowManager.toggleMainWindow();
}
```

**Mini Window Hide** (minimize, not destroy):
```dart
Future<void> hideMiniPlayerWindow() async {
  final controller = miniWindow.controller as dynamic;
  controller.setMinimized(true);  // Use Flutter's internal API
  miniPlayerVisible = false;
}
```

**Mini Window Show** (restore from minimized):
```dart
Future<void> showMiniPlayerWindow() async {
  final controller = miniWindow.controller as dynamic;
  controller.setMinimized(false);  // Restore window
  await windowManager.hide();      // Hide main window
  miniPlayerVisible = true;
}
```

### Close Button Behavior

**KeyedWindow.onClose Callback**:
When mini player close button (X) is clicked, the `onClose` callback properly destroys the window and restores main window:

```dart
onClose: () {
  debugPrint('[MultiWindowApp] keyedWindow.onClose called');
  controller.destroy();        // Destroy mini window
  windowManager.remove(key);  // Remove from manager
  _showMainWindow();          // Show main window
},
```

### Architecture Changes

1. **KeyedWindow.onClose field**: Added callback for close action
2. **LihaWindowManager.remove()**: Resets `miniPlayerVisible = false` via setter
3. **MultiWindowApp._mainWindowVisible**: Computed property based on `hasMiniPlayer` and `miniPlayerVisible`
4. **MultiWindowApp listens to windowManager**: Triggers `setState()` on changes

### Tested Results ✅
| Test | Result |
|------|--------|
| 无迷你窗口时托盘切换主窗口显隐 | ✅ PASSED |
| 打开迷你播放器后托盘"显示/隐藏"最小化迷你窗口 | ✅ PASSED |
| 再次托盘"显示/隐藏"恢复迷你窗口 | ✅ PASSED |
| 点击迷你窗口关闭按钮，窗口销毁且主窗口显示 | ✅ PASSED |

---

**Document Version**: 1.6
**Updated**: 2026-05-09
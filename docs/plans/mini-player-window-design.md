# Mini Player Window Design Document

**Date**: 2026-04-22
**Status**: Approved
**Version**: 1.2
**Last Updated**: 2026-04-22

---

## 1. Overview

### Purpose

Create a compact mini player widget embedded in the main window's bottom area, providing core playback controls alongside the main content.

### Implemented Features (Tested ✅)

- Playback controls (Play/Pause/Previous/Next)
- Draggable progress bar
- Loop mode (Off/All/One cycle)
- Shuffle mode
- Vertical volume slider
- Marquee text for long titles
- More panel (Return to main / Quit)

---

## 2. Layout Structure

### MiniPlayer Widget (Embedded in MainWindow)

| Property | Value                              |
| -------- | ---------------------------------- |
| Height   | 90px                               |
| Width    | Full width (minus navigation rail) |
| Position | Bottom of main content area        |

### Layout Structure (Actual Implementation)

```
┌────────────────────────────────────────────────────────────┐
│ 1:23 ══════════●══════════════════ 3:45                   │  ← Progress Bar (24px height)
├────────────────────────────────────────────────────────────┤
│ [封面]  歌曲标题              ◀◀  ▶  ▶▶   🔁 🔀 🔊  ≡   │
│  48x48  艺术家名                                        │
└────────────────────────────────────────────────────────────┘
```

### MiniPlayer Internal Layout (Actual)

```
┌────────────────────────────────────────────────────────────────┐
│ [时间] ═══════════●═════════════════════ [时间]              │  ← Progress Row (24px)
├────────────────────────────────────────────────────────────────┤
│ ┌──────┐                    │ ◀◀  ▶  ▶▶ │ 🔁 🔀 🔊  ≡    │
│ │封面  │ 歌曲标题            │  播放控制  │  功能按钮  │ 4px │
│ │48x48 │ 艺术家名            │           │           │     │
│ └──────┘                     │           │           │     │
└────────────────────────────────────────────────────────────────┘
```

### Layout Regions

| Region            | Position           | Size                                                |
| ----------------- | ------------------ | --------------------------------------------------- |
| Progress Bar      | Top                | 24px height, full width with 8px horizontal padding |
| Album Cover       | Bottom-left        | 48×48 px, 8px margins                               |
| Song Info         | Bottom-center-left | Expanded, 2 lines (title + artist)                  |
| Playback Controls | Bottom-right       | ◀◀ ▶ ▶▶                                             |
| Feature Buttons   | Bottom-right-most  | 🔁 🔀 🔊 ≡                                          |
| End Spacing       | Bottom-right       | 4px                                                 |

### Progress Bar Specification

| Property         | Value             |
| ---------------- | ----------------- |
| Height           | 24px              |
| Left time width  | 45px              |
| Right time width | 45px              |
| Track height     | 4px               |
| Thumb size       | 14px circle       |
| Track color      | #404040           |
| Active color     | Primary (#2196F3) |
| Format           | `1:23 / 3:45`     |

---

## 3. Visual Design

### Color Palette

| Element         | Color                   | Notes                   |
| --------------- | ----------------------- | ----------------------- |
| Background      | #1E1E1E                 | Dark background         |
| Surface         | #2A2A2A                 | Elevated surfaces       |
| Text Primary    | #FFFFFF                 | Song title              |
| Text Secondary  | #B0B0B0                 | Artist name             |
| Button Normal   | #FFFFFF @ 80%           | Control icons           |
| Button Hover    | #FFFFFF                 | Icon highlight on hover |
| Button Active   | Primary Color (#2196F3) | Active state (playing)  |
| Progress Track  | #404040                 | Inactive progress       |
| Progress Active | Primary Color           | Filled progress         |
| Progress Thumb  | #FFFFFF                 | Draggable thumb         |

### Component Specifications

#### Album Cover

- Size: 48×48 px (actual code: lines 234-236)
- Shape: RoundedRectangle, borderRadius: 6px
- Shadow: BoxShadow blur: 4, offset: (0, 2), color @ 20%
- Margin: left 8px, right 8px
- Fallback: Gradient purple + Music note icon (size 24px)

#### Song Info

- Layout: Column with 2 lines
- Title: fontSize 13px, fontWeight w500, maxLines 1, overflow ellipsis
- Artist: fontSize 11px, color onSurfaceVariant, maxLines 1, overflow ellipsis
- Padding: horizontal 8px
- No marquee (uses ellipsis instead)

#### Progress Bar

- Track height: 4px (code line 137)
- Track color: Colors.grey.shade600 (#595959)
- Active color: Primary (#2196F3)
- Thumb: 14px circle, white, visible always (no hover required)
- Time text: fontSize 10px, onSurfaceVariant color
- Padding: horizontal 8px

#### Playback Control Buttons

| Button     | Icon                                   | Icon Size | Touch Target      |
| ---------- | -------------------------------------- | --------- | ----------------- |
| Previous   | Icons.skip_previous                    | 24px      | 36×36 (padding 8) |
| Play/Pause | Icons.play_circle / Icons.pause_circle | 32px      | 40×40 (padding 8) |
| Next       | Icons.skip_next                        | 24px      | 36×36 (padding 8) |

#### Feature Buttons

| Button  | Icon                            | Active State              |
| ------- | ------------------------------- | ------------------------- |
| Loop    | Icons.repeat / Icons.repeat_one | Primary color when active |
| Shuffle | Icons.shuffle                   | Primary color when active |
| Volume  | Icons.volume_up                 | -                         |
| More    | Icons.more_vert                 | -                         |

#### Volume Slider Popup (TESTED ✅)

| Property           | Value                                  |
| ------------------ | -------------------------------------- |
| Popup position     | right: 50, bottom: 80 (from parent)    |
| Popup size         | 50px width, auto height                |
| Popup padding      | vertical 16px                          |
| Popup style        | Material elevation 8, borderRadius 12  |
| Content            | Volume icon + Slider + Percentage      |
| Track height       | 120px                                  |
| Slider widget size | 30px width × 134px (120 + 7×2 padding) |
| Thumb size         | 14px circle                            |
| Direction          | Bottom=0, Top=1                        |

---

## 4. PlayerState (Implemented)

```dart
enum LoopMode { off, all, one }

class PlayerState {
  final PlayerStatus status;
  final String? currentSongPath;
  final String? currentSongTitle;
  final String? currentSongArtist;
  final Duration position;
  final Duration? duration;
  final LoopMode loopMode;           // off, all, one
  final bool isShuffleOn;
  final double volume;               // 0.0 - 1.0
  final String? errorMessage;
}
```

### Implemented Methods (PlayerNotifier)

| Method              | Description                 | Status    |
| ------------------- | --------------------------- | --------- |
| `toggleLoop()`      | Cycle Off → All → One → Off | ✅ TESTED |
| `toggleShuffle()`   | Toggle shuffle mode         | ✅ TESTED |
| `setVolume(double)` | Set volume 0.0-1.0          | ✅ TESTED |

---

## 5. File Structure

### Bottom Mini Player (主窗口底部)
```
lib/features/player/
├── presentation/
│   ├── widgets/
│   │   ├── mini_player.dart          # 底部迷你播放栏 (90px高度)
│   │   └── mini_player_view.dart    # 独立迷你播放器窗口内容 (512×512)
│   └── providers/
│       └── player_provider.dart      # Riverpod状态管理
```

### Mini Player View (独立窗口)
- **组件**: `MiniPlayerView` (mini_player_view.dart)
- **布局**: 512×512 窗口，包含模糊背景、封面、进度条、控制栏
- **包裹**: `MaterialApp` → `Scaffold` → `MiniPlayerView`
- **状态**: 通过全局 `providerContainer` + `UncontrolledProviderScope` 共享

---

## 6. Mini Player Window (Independent Window)

### Layout Structure (512×512)

```
┌────────────────────────────────────┐
│ Song Title - Artist      [↗ Close] │  ← Top Bar (50px)
├────────────────────────────────────┤
│ 0:00 ══════════●══════════ 3:45   │  ← Progress Bar (24px)
├────────────────────────────────────┤
│                                    │
│         ┌──────────┐               │
│         │  Cover   │               │  ← Cover Area (Expanded)
│         │  200×200 │               │
│         └──────────╯               │
│                                    │
├────────────────────────────────────┤
│  ◀◀  ▶/❚❚  ▶▶    🔁 🔀 ☰        │  ← Control Bar (70px)
└────────────────────────────────────┘
```

### Implementation Architecture

```
MultiWindowApp
├── ViewCollection
│   ├── View (view: default FlutterView)  ← 主窗口
│   │   └── UncontrolledProviderScope
│   │       └── MaterialApp → _MainWindowContent
│   │           └── MiniPlayer (底部90px播放栏)
│   └── RegularWindow (迷你播放器窗口)
│       └── UncontrolledProviderScope
│           └── MaterialApp
│               └── Scaffold
│                   └── MiniPlayerView (512×512)
└── LihaWindowManager (状态管理)
```

### Key Components

| Component | Role |
|-----------|------|
| `ViewCollection` | Flutter实验性API，单引擎管理多视图 |
| `View` widget | 将内容映射到特定FlutterView（主窗口） |
| `RegularWindow` | 创建新原生窗口（迷你播放器） |
| `MiniPlayerView` | 独立窗口的UI内容 |
| `LihaWindowManager` | 管理窗口显隐状态 |
| `window_manager` | 原生窗口hide/show（真正隐藏，非最小化） |

### Key Implementation Details

1. **Directionality修复**: `RegularWindow` 的子组件用 `MaterialApp` + `Scaffold` 包裹，提供Directionality和Material主题，避免 `No Directionality widget found` 错误。

2. **布局约束**: `MiniPlayerView` 外层用 `Container(width: double.infinity, height: double.infinity)` 提供有限约束，内部用 `Positioned.fill` 约束 `Column`，避免无限高度错误。

3. **帧回调延迟**: 所有窗口显隐操作（`hide()`/`show()`/`destroy()`）通过 `WidgetsBinding.instance.addPostFrameCallback` 延迟执行，避免打断MouseTracker状态。

4. **状态共享**: `main.dart` 创建全局 `providerContainer`，每个视图用 `UncontrolledProviderScope(container: providerContainer)` 包装。

### Tested Features

| Feature | Status |
|---------|--------|
| 迷你窗口独立显示 (512×512) | ✅ PASSED |
| 模糊背景显示 | ✅ PASSED |
| 进度条和封面显示 | ✅ PASSED |
| 播放控制按钮工作 | ✅ PASSED |
| 关闭按钮隐藏窗口 | ✅ PASSED |
| 主窗口正确隐藏/显示 | ✅ PASSED |
| 状态在窗口间同步 | ✅ PASSED |

---

**Document Version**: 1.4
**Updated**: 2026-04-28── domain/
│   ├── entities/
│   │   └── player_state.dart      # PlayerState + LoopMode enum
│   └── repositories/
│       └── player_repository.dart # completed stream
├── data/
│   └── repositories/
│       └── player_repository_impl.dart # completed stream
└── presentation/
    ├── providers/
    │   └── player_provider.dart   # toggleLoop, toggleShuffle, setVolume
    └── widgets/
        └── mini_player.dart       # Mini player widget
```

---

## 6. Acceptance Criteria (Implemented Only)

### ✅ All Tested and Passing

- [x] Loop mode cycles Off → All → One → Off
- [x] Shuffle mode toggles correctly
- [x] Volume slider shows and adjusts without clipping
- [x] Progress bar drag-to-seek works
- [x] PlayerState has LoopMode, isShuffleOn, volume fields
- [x] Song deduplication in library scan
- [x] Auto-stop at track end when loop is off
- [x] Loop One replays current track
- [x] Loop All advances to next track

---

## 7. Pending Features (Not Yet Implemented)

### Phase 4.2: Enhanced Visuals

| Feature            | Description                            | Status     |
| ------------------ | -------------------------------------- | ---------- |
| Blurred background | Full album art blur effect (sigma: 30) | ⏳ Pending |
| Glassmorphism      | Semi-transparent overlay + blur        | ⏳ Pending |
| Cover shadow       | Enhanced shadow on cover image         | ⏳ Pending |

### Phase 4.3: Enhanced Features

| Feature              | Description                 | Status     |
| -------------------- | --------------------------- | ---------- |
| Keyboard shortcuts   | Space, arrows for control   | ⏳ Pending |
| Cover art extraction | Extract from audio metadata | ⏳ Pending |
| Volume icon states   | Mute/low/medium/high icons  | ⏳ Pending |

### Phase 4.4: Standalone Mini Player Window (IMPLEMENTED ✅)

**Status**: ✅ Implemented and Tested (2026-04-28)

**Window Specs**:

- Size: 400×400 px (fixed)
- Frame: Standard window frame
- Layout:

```
┌────────────────────────────────────┐
│ Song Title - Artist      [−][×]  │  ← Standard title bar
├────────────────────────────────────┤
│                                    │
│         ┌──────────┐               │
│         │  Cover   │               │  ← Blurred background
│         └──────────╯               │
│                                    │
├────────────────────────────────────┤
│  ◀◀  ▶/❚❚  ▶▶    🔁 🔀 🔊  ≡   │  ← Control Bar
└────────────────────────────────────┘
```

**Implementation Architecture**:

```
MultiWindowApp
├── ViewCollection
│   ├── View (view: default FlutterView)
│   │   └── _MainWindowContent → _MainPageWithMiniPlayer
│   │       └── (System tray onShowHide → windowManager.hideMainWindow/showMainWindow)
│   └── RegularWindow (mini player window)
│       └── MiniPlayerWindowContent
└── LihaWindowManager (state management)
```

**Key Components**:

| Component | Role |
|-----------|------|
| `ViewCollection` | Flutter's experimental API for managing multiple views in single engine |
| `View` widget | Maps content to a specific FlutterView |
| `RegularWindow` | Creates new native window for mini player |
| `LihaWindowManager` | Manages window state (isHidden, hideMainWindow, showMainWindow) |
| `window_manager` package | Native window hide/show (hide from taskbar, not just minimize) |

**Key Implementation Details**:

1. **Single Window Problem Solved**: Previously, wrapping main content in `RegularWindow` caused two windows (empty default + content). Solution: Use `View` widget to display content on default FlutterView without creating new native window.

2. **True Window Hiding**: `window_manager.hide()` completely hides the window from taskbar. Not just minimizing which still shows in taskbar.

3. **State Management**: `LihaWindowManager` tracks `_isHidden` state and notifies listeners when window visibility changes.

4. **System Tray Integration**: Tray's `onShowHide` callback toggles window visibility via `windowManager.isHidden` check.

**Tested Features**:

| Feature | Status |
|---------|--------|
| Main window hides when mini player opens | ✅ PASSED |
| Main window shows when mini player closes | ✅ PASSED |
| System tray show/hide button works | ✅ PASSED |
| Only one window displays at startup | ✅ PASSED |
| Mini player creates independent window | ✅ PASSED |

---

## 8. Borderless Window Design (IMPLEMENTED ✅ 2026-04-29)

### Problem
RegularWindow creates windows with native title bars that cannot be hidden using Flutter-only methods.

### Solution: Win32 API Direct Style Manipulation

#### Window Layout After Borderless
```
┌────────────────────────────────────┐
│ [返回][标题···拖动区域···][最小化] │  ← Custom title bar (50px)
├────────────────────────────────────┤
│ 0:00 ════════●═══════════ 3:45   │
├────────────────────────────────────┤
│                                    │
│         ┌──────────┐               │
│         │  Cover  │               │
│         └──────────┘               │
│                                    │
├────────────────────────────────────┤
│  ◀◀  ▶/❚❚  ▶▶    🔁 🔀 🔊    │
└────────────────────────────────────┘
```

#### Custom Title Bar Specs

| Property | Value |
|----------|-------|
| Height | 50px |
| Background | Transparent (overlay on content) |
| Return button | right: 0, icon: arrow_back |
| Minimize button | right: 54, icon: minimize |
| Drag area | Positioned.fill (remaining area) |
| Title text | Padding left: 12, fontSize: 13 |

#### Window Styling (WindowStyler)

| Method | Win32 API | Description |
|--------|----------|-----------|
| setWindowBorderless | FindWindow + SetWindowLongPtr | WS_POPUP style |
| minimizeWindow | PostMessage WM_SYSCOMMAND | SC_MINIMIZE |
| closeWindow | PostMessage WM_CLOSE | Close window |

#### Drag Implementation Specs

| Property | Value |
|----------|-------|
| Gesture | GestureDetector.onPanStart/Update/End |
| Start position | GetCursorPos |
| Window start | GetWindowRect |
| Move | SetWindowPos |
| Flags | SWP_NOZORDER \| SWP_NOSIZE |

#### Dependencies Added
```yaml
dependencies:
  win32: ^5.5.0
  ffi: ^2.2.0
```

### Implementation Files
- `lib/core/windows/window_styler.dart` - WindowStyler service
- `lib/features/player/presentation/widgets/mini_player_view.dart` - UI integration

---

**Document Version**: 1.4
**Updated**: 2026-04-29

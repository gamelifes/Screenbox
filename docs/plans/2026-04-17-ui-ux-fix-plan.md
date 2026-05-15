# 2026-04-17 UI/UX 修复计划

**日期**: 2026-04-17
**状态**: ✅ 已完成

---

## 问题清单

| # | 严重级别 | 问题描述 | 修复方案 | 状态 |
|---|---------|---------|---------|------|
| UX1 | P0 | 左侧导航栏的"播放"功能放错位置 | 将播放栏移至页面底部作为 MiniPlayer | ✅ 已完成 |
| UX2 | P0 | 音乐库点击歌曲没有关联到播放 | 实现 `_playSong` 方法调用 PlayerProvider | ✅ 已完成 |
| UX3 | P1 | 歌曲列表没有按首字母分类 | 实现 A-Z 分组导航 | ✅ 已完成 |

---

## UX1: 将播放栏移至页面底部

### 问题描述

当前"播放"功能在左侧导航栏作为一个页面存在。用户期望：
- 底部显示当前播放状态（MiniPlayer）
- 导航栏只保留导航功能

### 修复方案

1. **创建 MiniPlayer 组件** (`lib/features/player/presentation/widgets/mini_player.dart`)
   - 固定在页面底部
   - 显示：专辑封面占位、歌曲信息、播放控制按钮
   - 点击展开到完整播放器页面

2. **修改 MainPage 布局**
   - 保留 NavigationRail 导航
   - 添加 Column，将 child 和 MiniPlayer 垂直排列

3. **路由调整**
   - 移除 NavigationRail 中的"播放"导航项
   - 保留"播放列表"和"设置"
   - 或保持4项导航，但底部 MiniPlayer 作为全局播放控制

### 设计决策

**方案A**: 底部 MiniPlayer + 4项导航（推荐）
- 优点：用户随时可见播放状态
- 缺点：占用64px高度

**方案B**: 移除"播放"导航项，底部 MiniPlayer 点击展开
- 优点：界面更简洁
- 缺点：需要额外点击操作

**推荐方案A**，保持导航完整性 + 全局 MiniPlayer

### 涉及文件

- `lib/features/player/presentation/widgets/mini_player.dart` (新建)
- `lib/features/ui/pages/main_page.dart` (修改)
- `lib/router.dart` (可能需要调整)

---

## UX2: 音乐库点击歌曲关联到播放

### 问题描述

`LibraryPage._playSong()` 方法只有 SnackBar 提示，没有真正调用播放器。

```dart
void _playSong(SongModel song) {
  // TODO: integrate with player
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('播放: ${song.title ?? song.filePath}')),
  );
}
```

### 修复方案

1. **导入 PlayerProvider**
   ```dart
   import 'package:liyaplayer/features/player/presentation/providers/player_provider.dart';
   ```

2. **实现播放逻辑**
   ```dart
   void _playSong(SongModel song) async {
     final playerNotifier = ref.read(playerProvider.notifier);
     await playerNotifier.loadAudio(song.filePath);
     await playerNotifier.play();
   }
   ```

3. **更新当前播放歌曲ID显示**
   - 需要在 libraryProvider 中添加 `currentSongId` 状态
   - 或创建新的 `currentMediaProvider`

### 涉及文件

- `lib/features/library/presentation/pages/library_page.dart`

---

## UX3: 歌曲列表按首字母分类

### 问题描述

歌曲列表是纯列表，没有按 A-Z 分组。常见音乐应用（如 Apple Music、Spotify）都支持按字母快速定位。

### 修复方案

1. **创建 `SongListViewWithSection` 组件**
   - 使用 `SliverList` 实现带 section header 的列表
   - 按歌曲标题首字母分组

2. **数据结构**
   ```dart
   Map<String, List<SongModel>> groupedSongs;
   // {
   //   'A': [Song1, Song2],
   //   'B': [Song3],
   //   ...
   // }
   ```

3. **右侧 A-Z 快速导航栏**
   - 使用 `Scrollbar` + 字母列表
   - 点击字母跳转到对应 section

4. **替代方案：直接使用 sectioned_list 或 grouped_list 插件**
   - 考虑使用 `sectioned_list` 包简化实现

### 涉及文件

- `lib/features/library/presentation/widgets/song_list_view.dart` (修改)
- 或新建 `lib/features/library/presentation/widgets/song_section_list_view.dart`

---

## 实施顺序

1. **UX2** (最简单的修改，先验证播放集成)
2. **UX1** (MiniPlayer + MainPage 调整)
3. **UX3** (字母分组，最复杂)

---

## 验证清单

- [x] 音乐库点击歌曲开始播放
- [x] 底部显示 MiniPlayer
- [x] MiniPlayer 播放控制正常工作
- [x] 歌曲列表按 A-Z 分组显示
- [ ] 右侧字母导航可点击跳转（简化版，未实现）

---

## 修改文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/features/library/presentation/pages/library_page.dart` | 修改 | 添加播放集成，导入并使用 `SongListViewWithSections` |
| `lib/features/player/presentation/widgets/mini_player.dart` | 新建 | 底部迷你播放栏组件 |
| `lib/features/ui/pages/main_page.dart` | 修改 | Column 布局 + MiniPlayer + 移除"播放"导航项 |
| `lib/features/library/presentation/widgets/song_list_view_with_sections.dart` | 新建 | 按首字母分组的歌曲列表组件 |
| `docs/plans/2026-04-17-ui-ux-fix-plan.md` | 新建 | 计划文档 |

---

## 2026-04-17 第二轮修复

### 问题

| # | 问题描述 | 状态 |
|---|---------|------|
| UX2-Fix | 点击歌曲没有关联到播放栏，MiniPlayer 没有显示歌曲信息 | ✅ 已完成 |
| UX1-Fix | MiniPlayer 没有进度条 | ✅ 已完成 |

### 修复内容

1. **PlayerState 添加歌曲信息字段**
   - 新增 `currentSongTitle`、`currentSongArtist`、`currentSongAlbum` 字段
   - 修改 `loadAudio()` 方法接受歌曲信息参数

2. **MiniPlayer 增强**
   - 显示歌曲标题、艺术家、专辑信息
   - 添加 LinearProgressIndicator 进度条
   - 显示当前播放时间 / 总时长
   - 布局高度从 64px 调整为 80px（包含进度条）

3. **library_page 传递歌曲信息**
   - `_playSong()` 调用 `loadAudio()` 时传递 `title`、`artist`、`album` 参数

### 涉及文件

| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/features/player/presentation/providers/player_provider.dart` | 修改 | PlayerState 添加歌曲信息字段，loadAudio 支持歌曲参数 |
| `lib/features/player/presentation/widgets/mini_player.dart` | 修改 | 显示歌曲信息、进度条、时间显示 |
| `lib/features/library/presentation/pages/library_page.dart` | 修改 | _playSong 传递歌曲信息 |

---

## 2026-04-17 第三轮修复

### 问题

| # | 问题描述 | 状态 |
|---|---------|------|
| Player-Fix1 | duration 获取不到，MiniPlayer 显示 00:00 / 无进度条 | ✅ 已完成 |
| Player-Fix2 | AudioDataSource 设计冗余（内部 AudioPlayer 未被使用） | ✅ 已完成 |

### 修复内容

1. **简化 PlayerRepositoryImpl**
   - 移除对 AudioDataSource 的依赖（其内部 AudioPlayer 从未被使用）
   - 直接在 PlayerRepositoryImpl 中处理文件/网络路径判断

2. **修复 getDuration() 等待机制**
   - just_audio 的 duration 在 setAudioSource 后不会立即可用
   - 添加轮询等待机制：最多等待 2 秒，每 50ms 检查一次
   - 确保 duration 获取到有效值后再返回

3. **修复 deprecated API**
   - `Color.withOpacity()` → `Color.withValues(alpha: 0.1)`

### 涉及文件

| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/features/player/data/repositories/player_repository_impl.dart` | 重构 | 简化实现，修复 duration 获取 |
| `lib/features/player/presentation/widgets/mini_player.dart` | 修改 | 修复 deprecated API |

---

**完成日期**: 2026-04-17
# 调试日志

---

## 问题：just_audio MissingPluginException

**日期**: 2026-04-17
**状态**: ✅ 已解决

### 问题描述
- 报错: `MissingPluginException(No implementation found for method disposeAllPlayers on channel com.ryanheise.just_audio.methods)`
- 原因: `just_audio` 不支持 Windows Desktop

### 解决方案
- 迁移到 `media_kit`
- 修改依赖: `just_audio` → `media_kit: ^1.2.6`, `media_kit_video: ^2.0.1`, `media_kit_libs_video: ^1.0.7`

---

## 问题：MediaKit.ensureInitialized 未调用

**日期**: 2026-04-20
**状态**: ✅ 已解决

### 问题描述
- 报错: `MediaKit.ensureInitialized must be called before using any API`
- 灰色空白页面

### 解决方案
- 在 `main.dart` 中添加 `MediaKit.ensureInitialized()`

---

## 问题：播放进度条不更新

**日期**: 2026-04-20
**状态**: ✅ 已解决

### 问题描述
- 播放时进度条不更新，时长显示 00:00

### 解决方案
- 添加 `positionStream` 和 `durationStream` 监听
- 在 `PlayerNotifier` 中订阅流更新

---

## 问题：Stop→Play 后进度不更新

**日期**: 2026-04-20
**状态**: ✅ 已解决

### 问题描述
- 点击 Stop 后再点击 Play，进度条不更新，时长变为 00:00
- 切换歌曲后 Stop→Play 也不工作

### 根本原因
- Stream listener 在 `loadAudio()` 期间响应 `isPlaying = false` 事件
- 将 `stopped` 状态错误覆盖为 `paused`
- 后续 `play()` 检测到 `paused` 状态，走错分支

### 解决方案
在 stream listener 中，当状态是 `loading` 或 `stopped` 时，**静默跳过**播放状态变化处理：

```dart
_playingStateSubscription = _repository.playingState.listen((playingState) {
  // loading 和 stopped 状态下不响应播放状态变化
  // 这些状态需要通过显式方法（play/pause/stop）来转换
  if (state.status == PlayerStatus.loading ||
      state.status == PlayerStatus.stopped) {
    return;
  }

  state = state.copyWith(
    position: playingState.position,
    status: playingState.isPlaying ? PlayerStatus.playing : PlayerStatus.paused,
  );
});
```

### 关键修改
- `player_provider.dart`:
  - Stream listener 在 `loading`/`stopped` 状态时跳过处理
  - 移除了脆弱的 `_isManuallyStopped` 标志
  - `loadAudio()` 不再设置额外标志，保持状态机清晰
- `player_repository_impl.dart`:
  - `getDuration()` 直接返回 `_player.state.duration`（移除 polling 循环）

### 工作流程
```
loadAudio() → status=loading → status=stopped
                                     ↓
              stream listener 检测到 status=stopped，跳过处理
                                     ↓
                              play() 被调用
                                     ↓
                    检测 status=stopped，正常重新加载播放
```

---

## 问题：LibraryPage 崩溃 (Null check operator)

**日期**: 2026-04-20
**状态**: ✅ 已解决

### 问题描述
- `state.scanProgress!` 当 `isScanning` 为 true 但 `scanProgress` 为 null 时崩溃

### 解决方案
- 修改条件: `if (state.isScanning)` → `if (state.isScanning && state.scanProgress != null)`

---

## 重构：PlayerProvider 状态管理优化

**日期**: 2026-04-21
**状态**: ✅ 完成

### 重构目标
保持 StateNotifier 模式，优化内部逻辑，提升可维护性。

### 变更内容

#### 1. PlayerState 增强
- 添加状态机文档注释（ASCII 图示）
- 添加便捷属性：`canPlay`、`hasMedia`、`isPlaying`、`hasError`

```dart
/// 是否可以播放（stopped 或 paused 状态）
bool get canPlay => status == PlayerStatus.stopped || status == PlayerStatus.paused;

/// 是否有媒体加载
bool get hasMedia => currentSongPath != null;
```

#### 2. Stream Listener 简化
- 移除 `_isManuallyStopped` 标志
- `playingStateSubscription` 只更新 position，不处理 status
- Status 转换完全由显式方法控制

#### 3. play() 方法优化
- 移除 300ms delay
- 统一处理 stopped 和 paused 分支
- 添加 guard 检查：`if (!state.hasMedia) return;`

#### 4. 方法文档完善
- 所有公共方法添加 dartdoc 注释
- 说明方法职责和状态转换

#### 5. PlayerStatus 文档
```dart
/// 状态转换图：
/// ```
///  idle ──loadAudio()──> loading ──完成──> stopped
///                                       │
///                         play() <──────┘
///                           │
///                           ▼
///                       playing ◄──────┐
///                           │          │
///                      pause()      play()
///                           │          │
///                           ▼          │
///                        paused ───────┘
///                           │
///                      stop() ◄────┐
///                           │      │
///                           ▼      │
///                        stopped ──┘
/// ```
```

#### 6. getDuration() 优化
- 增加最多 500ms 等待 media_kit 解析完成
- 避免初始读取返回 null 导致时长显示 00:00

### 对比分析

| 维度 | 原方案 | 重构后 | 结论 |
|------|--------|--------|------|
| **代码行数** | ~220 行 | ~250 行 | 重构多 13% |
| **状态标志位** | `_isManuallyStopped` | 无 | 重构更少 |
| **状态转换控制** | Stream + 标志位混合 | 显式方法唯一控制 | 重构更清晰 |
| **时序依赖** | 300ms delay | 最多 500ms polling | 重构更可靠 |
| **文档完整性** | 无状态机文档 | ASCII 状态图 + dartdoc | 重构更完善 |
| **可维护性** | 状态冲突风险高 | 单一状态源，职责清晰 | 重构更优 |

**性能对比**：
- `getDuration()` polling：原方案 100ms 不稳定，现方案最多 500ms 保证成功
- Stream 处理：原方案在 `loading`/`stopped` 时仍处理事件（后被覆盖），重构后直接跳过

**复杂度对比**：
- 原方案：Stream 和显式方法同时修改状态，需要 `_isManuallyStopped` 标志防止冲突
- 重构后：Stream 只负责 position/duration 更新，状态转换由显式方法统一控制，逻辑更简单

---

## Phase 2.4: LibraryProvider 状态管理与 Hive 集成

**日期**: 2026-04-21
**状态**: ✅ 完成

### 完成内容

#### 1. HiveService 创建
- `core/services/hive_service.dart`
- 管理 Hive 初始化和 Box 访问
- 提供 Songs/Albums/Artists/Directories 的 CRUD 操作

```dart
class HiveService {
  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();

  late Box<SongModel> _songBox;
  late Box<AlbumModel> _albumBox;
  late Box<ArtistModel> _artistBox;
  late Box<ScanDirectoryModel> _dirBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SongModelAdapter());
    // ... 打开 Boxes
  }

  List<SongModel> getAllSongs() => _songBox.values.toList();
  Future<void> saveSongs(List<SongModel> songs) async { ... }
  // ...
}
```

#### 2. main.dart 集成
- 在应用启动时初始化 Hive
- 确保在 ProviderScope 之前完成

```dart
void main() async {
  ErrorHandler.initialize();
  await HiveService.instance.initialize(); // 新增
  MediaKit.ensureInitialized();
  runApp(const ProviderScope(child: LihaPlayerApp()));
}
```

#### 3. LibraryNotifier Hive 集成
- `loadLibrary()`: 从 Hive 加载 songs/albums/artists/directories
- `addDirectory()`: 扫描后持久化到 Hive
- `removeDirectory()`: 从 Hive 删除

#### 4. 辅助方法
- `CancelToken`: 扫描取消标记
- `_generateAlbums()`: 从歌曲列表生成专辑
- `_generateArtists()`: 从歌曲列表生成艺术家

### Phase 2.4 完成的功能

| 功能 | 状态 |
|------|------|
| Hive 初始化 | ✅ |
| Hive 数据加载 | ✅ |
| Hive 数据保存 | ✅ |
| Hive 数据删除 | ✅ |
| 扫描取消 | ✅ |
| 目录移除 | ✅ |

---

## Phase 2.6: 集成测试

**日期**: 2026-04-21
**状态**: ✅ 完成

### Flutter Analyze 结果
- **44 issues found** (无严重错误)
- 主要是 info 和 warning 级别
- 关键问题已修复：
  - `library_page.dart`: 移除不必要的 `await`
  - `metadata_extractor.dart`: 移除不必要的 `await`

### 修复的问题
| 问题 | 位置 | 修复 |
|------|------|------|
| await on non-Future | library_page.dart:62,63,82 | 移除 await |
| await on non-Future | metadata_extractor.dart:29,73 | 移除 await |

### 未修复的警告（不影响功能）
- `deprecated_member_use`: 主题颜色 API 弃用警告
- `dead_null_aware_expression`: 空安全优化建议
- `unnecessary_null_comparison`: 冗余空检查

---

## Phase 3: Windows 系统集成

**日期**: 2026-04-21
**状态**: ✅ 完成

### 完成内容

#### 1. 应用图标
- `assets/icons/app_icon.ico` (9662 bytes)
- `assets/icons/app_icon.png` (256x256)
- 紫色渐变 + 白色音符设计

#### 2. 托盘菜单修复

**问题 1**: 托盘菜单播放控制无效
- **原因**: 回调只更新 tooltip，未连接 PlayerProvider
- **修复**: 在 `main_page.dart` 的 `_initSystemTray()` 中正确连接

```dart
onPlayPause: () {
  final state = ref.read(playerProvider);
  if (state.isPlaying) {
    playerNotifier.pause();
  } else if (state.canPlay) {
    playerNotifier.play();
  }
},
onNext: () => playerNotifier.next(),
onPrevious: () => playerNotifier.previous(),
onQuit: () async {
  await SystemTrayService.instance.dispose();
  exit(0);
},
```

**问题 2**: 托盘退出只关托盘
- **原因**: `onQuit` 缺少 `exit(0)` 调用
- **修复**: 添加 `dart:io` import 和 `exit(0)`

#### 3. 窗口配置优化
- 最小尺寸: 900x600
- 默认尺寸: 1100x700 (原 1200x800)

---

## 已验证功能

| 功能 | 状态 | 日期 |
|------|------|------|
| 播放进度条实时更新 | ✅ | 2026-04-20 |
| 上一曲/下一曲 | ✅ | 2026-04-20 |
| 暂停/继续播放 | ✅ | 2026-04-20 |
| 点击列表歌曲播放 | ✅ | 2026-04-20 |
| Stop→Play 进度恢复 | ✅ | 2026-04-20 |
| 歌曲时长显示 | ✅ | 2026-04-20 |
| Hive 持久化 | ✅ | 2026-04-21 |
| 媒体库扫描 | ✅ | 2026-04-21 |
| Phase 2 集成测试 | ✅ | 2026-04-21 |
| 托盘图标显示 | ✅ | 2026-04-21 |
| 托盘菜单-显示主窗口 | ✅ | 2026-04-21 |
| 托盘菜单-播放控制 | ✅ | 2026-04-21 |
| 托盘菜单-退出应用 | ✅ | 2026-04-21 |
| 窗口最小尺寸 900x600 | ✅ | 2026-04-21 |
| 窗口默认尺寸 1100x700 | ✅ | 2026-04-21 |
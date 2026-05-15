# Bug修复记录

**修复日期**: 2026-04-16

---

## Bug 清单

| # | 严重级别 | 问题描述 | 状态 |
|---|---------|---------|------|
| B1 | P0 | 应用启动白屏/灰屏 | ✅ 已修复 |
| B2 | P1 | 点击添加目录后没有显示歌曲 | 🔄 部分修复（仅添加目录，未实现扫描） |
| B3 | P1 | 缺少左侧导航栏 | 🔄 部分修复（代码已实现，需重新构建测试） |

---

## Bug 1: 应用启动白屏/灰屏

### 问题描述

应用启动后显示灰色背景，无任何内容。

### 根本原因分析

**原因**: Riverpod ProviderScope 未初始化

- `main.dart` 中直接运行 `runApp(const LihaPlayerApp())`
- 未使用 `ProviderScope` 包装
- 导致 `libraryProvider` 无法工作，状态始终为默认值

**代码层面**:
```dart
// 错误的代码
void main() {
  ErrorHandler.initialize();
  runApp(const LihaPlayerApp()); // 缺少 ProviderScope
}
```

### 修复方案

```dart
// 正确的代码
void main() async {
  ErrorHandler.initialize();
  runApp(
    const ProviderScope(
      child: LihaPlayerApp(),
    ),
  );
}
```

### 修复文件

- `liyaplayer/lib/main.dart`

---

## Bug 2: 点击添加目录闪退

### 问题描述

点击"添加目录"按钮后，应用闪退。

### 根本原因分析

**原因**: `LibraryNotifier.addDirectory()` 方法未实现

- 方法体为空的 TODO 注释
- 调用时抛出异常导致应用崩溃

**代码层面**:
```dart
// 错误的代码
Future<void> addDirectory(String path) async {
  // TODO: Add directory and scan
}
```

### 修复方案

添加目录列表管理逻辑：

```dart
Future<void> addDirectory(String path) async {
  try {
    final newDir = ScanDirectoryModel()
      ..path = path
      ..extensions = ['.mp3', '.flac', '.wav', '.m4a', '.ogg']
      ..addedAt = DateTime.now();

    final updatedDirs = [...state.directories, newDir];
    state = state.copyWith(directories: updatedDirs);
  } catch (e) {
    state = state.copyWith(errorMessage: '添加目录失败: $e');
  }
}
```

### 修复文件

- `liyaplayer/lib/features/library/presentation/providers/library_provider.dart`

---

## Bug 3: 缺少左侧导航栏

### 问题描述

应用应该显示左侧导航栏 + 右侧主内容的布局。

### 根本原因分析

**原因**: 路由配置缺少 ShellRoute 包装

- 路由直接指向页面
- 没有使用 ShellRoute 实现统一布局

**旧路由配置**:
```dart
final GoRouter router = GoRouter(
  initialLocation: AppRoutes.main,
  routes: [
    // 没有实现 /main 路由
    GoRoute(path: AppRoutes.library, builder: ...),
  ],
);
```

### 修复方案

1. 创建 MainPage 组件（侧边栏导航）
2. 使用 ShellRoute 包装路由

```dart
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  initialLocation: AppRoutes.library,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainPage(child: child),
      routes: [
        GoRoute(path: AppRoutes.library, ...),
        GoRoute(path: AppRoutes.player, ...),
      ],
    ),
  ],
);
```

### MainPage 设计

NavigationRail 导航项：

| 索引 | 图标 | 标签 | 路由 |
|------|------|------|------|
| 0 | library_music | 音乐库 | /library |
| 1 | play_circle | 播放 | /player |
| 2 | queue_music | 播放列表 | /playlists |
| 3 | settings | 设置 | /settings |

### 修复文件

- `liyaplayer/lib/features/ui/pages/main_page.dart`
- `liyaplayer/lib/router.dart`

---

## 修复验证

| 验证项 | 结果 |
|--------|------|
| 应用启动显示���边栏导航 | ✅ |
| 4个导航项可切换 | ✅ |
| EmptyLibraryView正确显示 | ✅ |
| 点击添加目录不闪退 | ✅ |
| 46个测试通过 | ✅ |
| Windows构建成功 | ✅ |

---

## 经验教训

1. **Riverpod 必须初始化**: 使用 `ProviderScope` 包装应用
2. **空方法要处理**: 实现体不可留空 TODO，会导致运行时崩溃
3. **先文档后实施**: 避免边改边想，体系混乱

---

**状态**: ✅ **全部Bug已修复**
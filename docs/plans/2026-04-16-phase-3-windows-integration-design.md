# Phase 3: Windows系统集成设计

**设计日期**: 2026-04-16  
**状态**: 🔄 **待实施**

---

## 1. 设计目标

实现原生 Windows 桌面体验，包括：
- 系统托盘（最小化到托盘、托盘菜单）
- 窗口管理（状态持久化、最小/最大/关闭）
- 全局快捷键
- 高DPI适配

---

## 2. 关键设计决策

| 决策 | 选项 | 选择 | 理由 |
|------|------|------|------|
| 系统托盘插件 | system_tray / tray_manager | system_tray | pub.dev 最流行，Windows支持好 |
| 窗口管理插件 | window_manager / bitsdojo_window | window_manager | 官方维护，功能完整 |
| 全局热键 | hotkey_manager / custom | hotkey_manager | pub.dev 热门包 |
| 托盘图标 | 内置资源 / 用户自定义 | 用户自定义 | 允许用户替换 |

---

## 3. 功能模块设计

### 3.1 SystemTrayService (系统托盘)

**位置**: `lib/core/windows/system_tray_service.dart`

```dart
class SystemTrayService {
  /// 初始化托盘
  Future<void> initialize();

  /// 设置托盘图标
  Future<void> setIcon(String iconPath);

  /// 设置托盘菜单
  Future<void> setContextMenu(List<MenuItem> items);

  /// 显示托盘通知
  Future<void> showNotification(String title, String body);

  /// 销毁托盘
  Future<void> dispose();
}
```

**菜单项**:
- 显示/隐藏窗口
- 播放/暂停
- 下一曲
- 上一曲
- 分隔线
- 退出

### 3.2 WindowManagerService (窗口管理)

**位置**: `lib/core/windows/window_manager_service.dart`

```dart
class WindowManagerService {
  /// 初始化窗口管理
  Future<void> initialize();

  /// 最小化窗口
  Future<void> minimize();

  /// 最大化窗口
  Future<void> maximize();

  /// 关闭窗口
  Future<void> close();

  /// 判断是否最大化
  Future<bool> isMaximized();

  /// 最小化到托盘
  Future<void> minimizeToTray();

  /// 设置焦点
  Future<void> focus();
}
```

### 3.3 WindowStatePersistence (窗口状态持久化)

**位置**: `lib/core/windows/window_state.dart`

**存储内容**:
- `x`: 窗口X坐标
- `y`: 窗口Y坐标
- `width`: 窗口宽度
- `height`: 窗口高度
- `isMaximized`: 是否最大化
- `isFullScreen`: 是否全屏

**存储方式**: Hive 数据库

### 3.4 GlobalHotkeyService (全局热键)

**位置**: `lib/core/windows/global_hotkey_service.dart`

| 热键 | 功能 |
|------|------|
| Space | 播放/暂停 |
| Ctrl+Right | 下一曲 |
| Ctrl+Left | 上一曲 |
| Ctrl+Up | 音量增加 |
| Ctrl+Down | 音量减少 |
| F11 | 全屏切换 |

---

## 4. UI设计

### 4.1 主页面布局

```
┌─────────────────────────────────────────────────────┐
│ [≡] LihaPlayer           [─][□][×] │
├────┬────────────────────────────────────────────┤
│    │                                            │
│ 🎵 │                                            │
│    │            主内容区域                         │
│ ▶  │                                            │
│    │                                            │
│ ☰ │                                            │
│ ⚙ │                                            │
│    │                                            │
├────┴────────────────────────────────────────────┤
│ [◀][▶][▶][▶]  ═══════●═══════  🔊━━━━         │
└─────────────────────────────────────────────────────┘
    侧边栏              底部迷你播放器
```

### 4.2 NavigationRail 导航项

| 索引 | 图标 | 标签 | 路由 |
|------|------|------|------|
| 0 | library_music | 音乐库 | /library |
| 1 | play_circle | 播放 | /player |
| 2 | queue_music | 播放列表 | /playlists |
| 3 | settings | 设置 | /settings |

---

## 5. 技术实现

### 5.1 依赖配置

```yaml
dependencies:
  system_tray: ^2.0.3
  window_manager: ^0.3.4
  hotkey_manager: ^0.2.0
```

### 5.2 路由配置

使用 `ShellRoute` 实现侧边栏+内容布局：

```dart
ShellRoute(
  builder: (context, state, child) => MainPage(child: child),
  routes: [
    GoRoute(path: '/library', builder: (_, __) => LibraryPage()),
    GoRoute(path: '/player', builder: (_, __) => PlayerPage()),
    // ...
  ],
)
```

### 5.3 初始化顺序

```dart
void main() async {
  // 1. 初始化 Hive
  await Hive.initFlutter();

  // 2. 初始化 WindowManager
  await WindowManagerService().initialize();

  // 3. 初始化 SystemTray
  await SystemTrayService().initialize();

  // 4. 初始化 GlobalHotkey
  await GlobalHotkeyService().initialize();

  // 5. 运行应用
  runApp(const ProviderScope(child: LihaPlayerApp()));
}
```

---

## 6. 验收标准

- [ ] 应用启动显示侧边栏导航
- [ ] 4个导航项可切换
- [ ] 可最小化到系统托盘
- [ ] 托盘菜单点击有效
- [ ] 窗口状态正确保存恢复
- [ ] 全局热键工作
- [ ] 高DPI显示正常

---

## 7. 已知风险与解决方案

| 风险 | 影响 | 解决方案 |
|------|------|------|
| system_tray Windows 兼容性 | 托盘可能不显示 | 测试多个 Windows 版本 |
| 全局热键冲突 | 热键被其他应用占用 | 提供设置修改热键 |
| 高DPI模糊 | 界面模糊 | 使用 256x256 图标 |

---

## 8. 实施计划

| 步骤 | 任务 | 依赖 |
|------|------|------|
| 3.1 | SystemTrayService 实现 | 依赖配置 |
| 3.2 | WindowManagerService 实现 | 3.1 |
| 3.3 | 窗口状态持久化 | 3.2 |
| 3.4 | GlobalHotkeyService | 3.1 |
| 3.5 | MainPage 布局 | 路由配置 |
| 3.6 | 集成测试 | 全部 |

---

## 9. 相关文档

- `DEVELOPMENT_PLAN.md` - Phase 3 规划
- `docs/architecture.md` - 架构决策

---

**下一步**: 开始实施 Phase 3.1 - SystemTrayService
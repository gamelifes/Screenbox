# LihaPlayer Windows 桌面播放器 - 开发计划方案

## 项目概述

**项目名称**: LihaPlayer  
**目标平台**: Windows 桌面 (Windows 10/11, x64)  
**核心功能**: 音乐库管理、视频库管理、网络流媒体播放  
**技术框架**: Flutter 3.19+ (Windows Desktop)

---

## 一、技术栈选型

### 核心框架
- **Flutter SDK**: 3.19+ (稳定版，支持 Material 3)
- **Dart**: 3.3+ (空安全、模式匹配)
- **Windows 支持**: `flutter config --enable-windows-desktop`

### 媒体播放引擎

#### 音视频播放
- **主选**: `media_kit` (推荐)
- 功能: 跨平台音视频播放、广泛格式支持、流媒体、字幕
- Windows 支持: ✅ 原生支持 Windows 7+
- 维护状态: 活跃，完整的 Windows 实现
- 支持平台: Android, iOS, Linux, macOS, Windows, Web

#### 相关包
- `media_kit`: ^1.2.6 - 核心播放引擎
- `media_kit_video`: ^2.0.1 - 视频渲染组件
- `media_kit_libs_video`: ^1.0.7 - Windows 原生依赖 (包含音频解码器)

### 状态管理
- **首选**: `Riverpod 2.4+`
  - 理由: 编译时安全、无需 BuildContext、测试友好、代码简洁
  - 适合场景: 复杂媒体状态、多页面共享
- **备选**: `Bloc 8.1+`
  - 理由: 事件驱动、状态流清晰、适合大型应用
- **不推荐**: Provider (功能不足)、GetX (紧耦合)

### 本地存储
- **数据库**: `Hive 2.2+` (推荐)
  - 优势: 纯 Dart 实现、无需原生依赖、性能优异、跨平台
  - 适用: 媒体库、播放列表、设置
- **备选**: `Drift (Moor)` (SQLite 封装)
  - 优势: 类型安全 SQL、 migrations、复杂查询
  - 适用: 需要复杂关联查询的场景
- **简单设置**: `shared_preferences`
  - 用途: 用户偏好、简单配置

### 文件系统
- `path_provider` - 获取 Windows 特殊目录 (AppData、Documents)
- `file_picker` - Windows 文件选择对话框
- `storage_info` - 磁盘空间信息 (需验证 Windows 兼容性)
- 自定义扫描器 - 使用 `dart:io` API 递归扫描

### 网络与流媒体
- `dio 5.4+` - HTTP 客户端 (支持拦截器、缓存、取消)
- `cached_network_image` - 网络图片缓存
- `web_socket_channel` - WebSocket 电台流
- `http` - 简单 HTTP 请求备用

### UI/UX 组件
- `flutter_screenutil` - 响应式屏幕适配 (支持多种桌面分辨率)
- `audio_video_progress_bar` - 自定义进度条控件
- `just_waveform` - 音频波形可视化
- `rive` 或 `lottie` - 动画效果 (可选)
- `bitsdojo_window` - 自定义窗口边框、标题栏 (可选)
- `window_manager` - 窗口控制 (最小化/最大化/关闭、状态持久化)

### Windows 系统集成 (需验证可用性)
- **系统托盘**: `system_tray` 或 `tray_manager`
- **全局快捷键**: `global_hotkeys` 或自定义平台通道
- **任务栏进度**: 通过 `dart:ffi` 调用 Windows API (ITaskbarList3)
- **文件关联**: 注册表操作 (需平台通道)
- **拖拽支持**: Flutter 内置 `DragTarget` / `Draggable`

---

## 二、Windows 桌面特定考虑

### 1. 文件系统与权限
- Windows 应用默认有文件系统访问权限 (无需动态申请)
- **重要**: 避免写入受保护目录 (Program Files、Windows)
- 建议用户数据存储在:
  - `%APPDATA%\LihaPlayer` (配置)
  - 用户自选的媒体目录 (如 `D:\Music`, `D:\Videos`)
- 处理长路径 (超过 260 字符) - 启用长路径支持或使用 `\\?\` 前缀
- 支持网络路径 (UNC: `\\server\share`)
- 符号链接和目录连接点处理

### 2. 窗口管理
- 响应式布局: 支持窗口大小变化
- 窗口状态持久化: 记住位置、大小、最大化状态到 Hive
- 多显示器支持: 记住窗口所在显示器
- Aero Snap 支持 (Windows 10/11 分屏)
- 可选: 自定义非客户区 (自定义标题栏、圆角窗口)
- DPI 缩放适配: 支持 100%/125%/150%/200% 缩放

### 3. 系统集成功能
#### 系统托盘
- 最小化到托盘
- 托盘图标右键菜单: 播放/暂停、显示/隐藏、退出
- 双击托盘图标显示/隐藏主窗口
- 托盘图标显示播放状态 (暂停/播放图标)

#### 任务栏集成
- Windows 7+ 任务栏进度条 (播放进度)
- 任务栏覆盖图标 (播放状态)
- 缩略图工具栏 (播放控制)

#### 全局快捷键
- 注册系统热键: Play/Pause、Next、Previous、Stop
- 避免与系统快捷键冲突
- 多媒体键盘按键支持

#### 文件关联
- 注册 `.mp3`, `.flac`, `.mp4`, `.mkv` 等扩展名
- "Open with LihaPlayer" 上下文菜单
- 命令行参数: `LihaPlayer.exe "file.mp3"`

#### 拖拽支持
- 拖拽文件到应用打开
- 拖拽文件到播放列表添加
- 拖拽重新排序

### 4. 性能优化
- **文件扫描**: 使用 Isolate 避免 UI 卡顿
- **内存管理**: 缩略图缓存大小限制、及时释放
- **启动优化**: 延迟加载非必要模块、预加载核心资源
- **电池续航**: 笔记本模式下减少后台活动

### 5. 打包分发
- **构建命令**: `flutter build windows --release`
- **输出目录**: `build\windows\x64\runner\Release\`
- **安装器选择**:
  - **Inno Setup** (推荐) - 免费、简单、功能完善
  - **WiX Toolset** - 企业级，MSI 包
  - **NSIS** - 轻量，脚本灵活
- **运行时**: Flutter Windows 应用捆绑 Dart 运行时
- **包体积**: 基础约 50-80MB (取决于打包选项)
- **代码签名**: 推荐使用数字证书 (SmartScreen)

### 6. 异步与多线程
- 文件扫描、元数据提取 → Isolate
- 使用 `compute()` 或 `Isolate.spawn()`
- 复杂后台任务管理 (可选 `worker_manager`)

---

## 三、项目架构设计

### 目录结构 (Feature-First + Clean Architecture)

```
LihaPlayer/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── app.dart                     # MaterialApp 配置
│   ├── injection.dart               # Riverpod Provider 容器
│   ├── router.dart                  # 路由配置 (GoRouter)
│   ├── core/                        # 核心层 (跨功能)
│   │   ├── constants/              # 常量、枚举
│   │   ├── errors/                 # 异常定义、处理
│   │   ├── theme/                  # Material 3 主题配置
│   │   ├── utils/                  # 工具类 (日期、文件等)
│   │   └── windows/                # Windows 特定代码
│   │       ├── window_manager.dart # 窗口管理封装
│   │       ├── system_tray.dart    # 系统托盘封装
│   │       └── global_shortcuts.dart # 全局热键封装
│   ├── features/                   # 功能模块 (feature-based)
│   │   ├── player/
│   │   │   ├── domain/
│   │   │   │   ├── entities/      # MediaItem, PlayerState, Playlist
│   │   │   │   ├── repositories/  # IPlayerRepository 接口
│   │   │   │   └── usecases/      # Play, Pause, Seek, Next, Previous
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   ├── repositories/
│   │   │   │   ├── datasources/   # AudioDataSource, VideoDataSource
│ │ │ │ └── services/ # media_kit 封装
│   │   │   └── presentation/
│   │   │       ├── providers/     # Riverpod StateNotifier/StateProvider
│   │   │       ├── widgets/       # PlayerControls, ProgressBar, MiniPlayer
│   │   │       └── pages/         # FullScreenPlayerPage
│   │   ├── library/
│   │   │   ├── domain/
│   │   │   │   ├── entities/      # Song, Video, Album, Artist
│   │   │   │   ├── repositories/  # ILibraryRepository
│   │   │   │   └── usecases/      # ScanDirectory, SearchMedia, GetArtists
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   ├── repositories/
│   │   │   │   ├── datasources/   # FileScanner, MetadataExtractor
│   │   │   │   └── services/      # Hive 数据库操作
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       ├── widgets/       # MediaGrid, MediaList, MediaCard
│   │   │       └── pages/         # LibraryPage (Music/Video tabs)
│   │   ├── playlist/
│   │   │   ├── domain/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       ├── widgets/       # PlaylistItem, PlaylistEditor
│   │   │       └── pages/         # PlaylistManagementPage
│   │   ├── streaming/
│   │   │   ├── domain/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       └── pages/         # RadioBrowser, StreamPlayer
│   │   ├── settings/
│   │   │   ├── domain/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   │       └── pages/         # SettingsPage (Scan dirs, theme, shortcuts)
│   │   └── ui/
│   │       ├── widgets/           # 通用组件 (SearchBar, EmptyState)
│   │       └── pages/             # MainPage (BottomNavigation)
│   └── shared/                    # 共享资源
│       ├── models/                # 通用模型 (SearchResult, filter options)
│       └── extensions/            # Dart 扩展方法
├── assets/
│   ├── icons/                     # 应用图标
│   ├── fonts/                     # 自定义字体 (可选)
│   └── images/                    # 占位图、默认封面
├── windows/
│   ├── runner/
│   │   ├── main.cpp               # Windows 入口点
│   │   ├── flutter_window.cpp     # 窗口创建与管理
│   │   ├── utils.cpp              # Windows 实用函数
│   │   └── ...
│   └── CMakeLists.txt             # CMake 配置
├── pubspec.yaml
├── analysis_options.yaml
├── lihaplayer.yaml                # 应用配置 (扫描目录、快捷键等)
├── build.bat                     # Windows 构建脚本
├── installer/
│   └── lihaplayer.iss            # Inno Setup 脚本
├── CHANGELOG.md
├── README.md
├── LICENSE
└── docs/
    ├── architecture.md
    ├── development.md
    └── windows_integration.md
```

### 依赖注入 (Riverpod)
```dart
// injection.dart
final container = ProviderContainer();

final playlistProvider = StateNotifierProvider<PlaylistNotifier, PlaylistState>(...);
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>(...);
final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>(...);
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(...);
```

---

## 四、核心功能模块详述

### 模块 1: 媒体引擎 (Player Module)

**职责**: 音频/视频播放控制、队列管理、状态管理

#### 子模块 1.1: 音频播放器
- 封装 just_audio
- 支持音频格式: MP3, FLAC, AAC, WAV, OGG, Opus
- 功能:
  - 播放/暂停/停止
  - 上一曲/下一曲
  - 进度 Seek (精确到毫秒)
  - 播放速度 (0.25x - 3.0x)
  - 音量控制 (0.0 - 1.0)
  - 无缝播放 (Gapless)
  - 交叉淡入淡出 (Crossfade 0-10s)
  - 均衡器 (10段，预设+自定义)
  - 音频焦点处理 (暂停其他应用)

#### 子模块 1.2: 视频播放器
- 封装 video_player
- 支持视频格式: MP4, MKV, AVI, MOV, WebM, HLS (.m3u8)
- 功能:
  - 全屏切换
  - 画中画 (如果 better_player)
  - 视频比例控制 (原始、拉伸、裁剪)
  - 字幕加载 (SRT, ASS)
  - 视频缩略图预览 (拖动时)
  - 亮度/对比度调节 (可选)

#### 子模块 1.3: 播放队列
- 当前播放队列 (Current Queue)
- 历史记录 (最近 100 首/个)
- 播放模式: 顺序、随机、单曲循环、列表循环
- 队列操作: 添加、删除、移动、清空

#### 子模块 1.4: 状态管理
- PlayerState (enum): idle, loading, playing, paused, stopped, error
- 状态持久化: 保存当前播放项、位置、播放模式

### 模块 2: 媒体库管理 (Library Module)

**职责**: 文件扫描、元数据提取、库索引、搜索过滤

#### 子模块 2.1: 文件扫描器
- 递归扫描用户选择的目录
- 文件类型过滤 (音频: .mp3, .flac, .m4a; 视频: .mp4, .mkv, .avi)
- 排除系统目录 (Windows, Program Files, $Recycle.Bin)
- 进度报告 (扫描进度条)
- 支持取消扫描
- 使用 Isolate 后台执行

#### 子模块 2.2: 元数据提取
- 音频: ID3v1/ID3v2 (标题、艺术家、专辑、封面、年代、流派)
- 视频: 容器元数据 (标题、时长、分辨率、编码、创建时间)
- 视频缩略图: 提取关键帧 (可选，耗时)
- 库指纹: 文件大小+修改时间 快速去重

#### 子模块 2.3: 数据库设计 (Hive)
```dart
@HiveType(typeId: 0)
class MediaItem {
  @HiveField(0) String path;
  @HiveField(1) String title;
  @HiveField(2) String? artist;
  @HiveField(3) String? album;
  @HiveField(4) int duration; // ms
  @HiveField(5) String? thumbnailPath; // 本地缓存封面
  @HiveField(6) DateTime addedAt;
  @HiveField(7) int playCount;
  @HiveField(8) DateTime? lastPlayed;
  @HiveField(9) MediaType type; // audio/video
  @HiveField(10) int fileSize;
  @HiveField(11) DateTime fileModified;
}
```

#### 子模块 2.4: 搜索与过滤
- 全文搜索: 标题、艺术家、专辑
- 按类型过滤: 音频/视频
- 按日期: 最近添加、最近播放
- 按播放次数: 最常播放
- 按专辑/艺术家分组浏览

### 模块 3: 播放列表管理 (Playlist Module)

**职责**: 用户自定义播放列表

#### 功能
- 创建/编辑/删除播放列表
- 重命名、修改封面
- 添加/移除媒体项 (从库中选择或拖拽)
- 拖拽排序
- 智能播放列表 (根据播放历史自动生成)
  - 最近常听
  - 未播放 (新添加)
  - 最爱 (高评分)
- 导入/导出
  - M3U, XSPF 格式
  - JSON (包含路径和顺序)
- 网络播放列表 URL 导入

### 模块 4: 网络流媒体 (Streaming Module)

**职责**: 在线电台、视频流播放

#### 功能
- **在线电台**
  - 预置电台库 (按流派分类)
  - 自定义电台 URL 添加 (HTTP/HTTPS 流)
  - 电台收藏
  - 显示电台名称、流派、码率
- **视频流**
  - HLS (.m3u8) 支持
  - DASH 支持 (如果 better_player)
  - 直播流缓冲优化
- **流媒体管理**
  - 流媒体历史记录
  - 收藏夹
  - 断点续播 (支持 Seek)

### 模块 5: Windows 系统集成 (Windows Integration)

**职责**: 原生 Windows 体验

#### 子模块 5.1: 系统托盘
- 托盘图标动态更新 (播放/暂停状态)
- 右键菜单:
  ```
  播放/暂停
  下一曲
  显示主窗口
  ---
  退出
  ```
- 双击托盘图标 → 显示/隐藏主窗口
- 托盘气泡通知 (曲目切换时显示)

#### 子模块 5.2: 任务栏
- 进度条显示播放进度 (通过 ITaskbarList3)
- 覆盖图标显示播放状态
- 缩略图工具栏: 播放/暂停/下一曲/音量

#### 子模块 5.3: 全局快捷键
- 注册系统热键 (RegisterHotKey API)
- 默认快捷键:
  - `Ctrl + Shift + Space` → 播放/暂停
  - `Ctrl + Shift + Right` → 下一曲
  - `Ctrl + Shift + Left` → 上一曲
  - `Ctrl + Shift + Up/Down` → 音量 +/-
- 用户可自定义

#### 子模块 5.4: 文件关联
- 注册文件扩展名关联 (HKEY_CLASSES_ROOT)
- 支持格式: .mp3, .flac, .m4a, .wav, .mp4, .mkv, .avi, .mov
- "Open with LihaPlayer" 右键菜单
- 命令行参数处理: `LihaPlayer.exe "<file_path>"`

#### 子模块 5.5: 拖拽支持
- 拖拽文件到主窗口 → 添加到当前播放列表
- 拖拽文件到任务栏图标 → 播放文件
- 播放列表内拖拽排序

#### 子模块 5.6: 窗口管理
- 记住窗口位置、大小、最大化状态
- 多显示器支持 (保存 monitor ID)
- Aero Snap 兼容 (Windows 10 分屏)
- 可选: 自定义非客户区 (自定义标题栏)

### 模块 6: UI/UX (Presentation Layer)

**职责**: 用户界面与交互

#### 主页面 layout
```
┌─────────────────────────────────────┐
│  Title Bar (自定义或系统)            │
├──────────┬──────────────────────────┤
│          │                          │
│  Sidebar │     Content Area        │
│  (Nav)   │                          │
│          │                          │
│  - Music │  - Media Grid/List      │
│  - Video │  - Search Bar           │
│  - Playlists                        │
│  - Settings                         │
│          │                          │
├──────────┴──────────────────────────┤
│  Mini Player (常驻底部)              │
└─────────────────────────────────────┘
```

#### 页面设计

**1. MainPage**
- 底部导航: 音乐库、视频库、播放列表、设置
- 侧边栏导航 (desktop 左侧)
- 顶部全局搜索框
- 常驻底部迷你播放器

**2. LibraryPage (音乐库/视频库)**
- Tab 切换: 全部、专辑、艺术家、文件夹
- Grid/List 视图切换按钮
- 下拉刷新、上拉加载更多
- 长按多选 → 添加到播放列表 / 删除
- 空状态提示 + 引导扫描

**3. FullScreenPlayerPage**
- 大专辑封面 / 视频画面
- 模糊背景 (封面高斯模糊)
- 播放控制: 播放/暂停、上一曲/下一曲、随机、循环
- 进度条 (可拖动、点击跳转)
- 音量控制 (滑块)
- 均衡器按钮 (快速预设切换)
- 歌词显示 (如果支持)

**4. PlaylistPage**
- 播放列表列表
- 创建新播放列表
- 进入播放列表详情 (显示曲目、编辑排序)
- 删除/重命名/分享

**5. SettingsPage**
- **库设置**
  - 扫描目录管理 (添加/删除)
  - 自动扫描开关 (定时)
  - 文件格式过滤
- **播放设置**
  - 默认播放模式
  - 交叉淡入时间
  - 音质偏好 (无损优先)
- **界面设置**
  - 主题切换 (深色/浅色)
  - 主题色选择
  - 语言 (i18n)
- **系统设置**
  - 启动时最小化到托盘
  - 全局快捷键配置
  - 文件关联
- **关于**
  - 版本信息
  - 检查更新

#### 主题系统
- Material 3 动态颜色 (基于系统主题)
- 支持手动选择主题色
- 深色/浅色模式自动跟随系统
- 自定义配色方案 (用户选择)

#### 响应式设计
- **手机**: 单列布局，底部导航
- **平板**: 双栏布局 (导航+内容)
- **桌面**: 三栏布局 (侧边栏导航+内容+迷你播放器常驻)
- 断点: 600px, 900px, 1200px

#### 交互细节
- 鼠标悬停效果 (按钮高亮、工具提示)
- 键盘快捷键列表 (F1 显示)
- 触觉反馈 (如果支持)
- 右键上下文菜单 (文件操作)

### 模块 7: 用户体验增强

#### 功能列表
- **睡眠定时器**: 15min / 30min / 60min / 自定义
- **播放速度**: 0.25x - 3.0x 调节
- **淡入淡出**: 交叉淡入淡出 (2-10秒)
- **播放统计**: 播放次数、总时长、最近播放时间
- **收藏系统**: 红心标记、自动生成"最爱"列表
- **历史记录**: 自动保存最近 100 条，可清空
- **均衡器预设**: 摇滚、流行、爵士、古典、自定义
- **快捷键备忘**: F1 显示快捷键列表
- **桌面歌词**: 可选独立小窗显示歌词 (未来)

---

## 五、开发阶段规划 (12周)

### Phase 1: 项目初始化与核心播放 (Week 1-2)

**目标**: 可播放本地音频/视频的最小应用

**任务清单**:
- [ ] 安装 Flutter 3.19+，启用 Windows 桌面支持
- [ ] 创建 Flutter 项目，配置 `windows/` 目录
- [ ] 初始化 Git 仓库，配置 .gitignore
- [ ] 添加基础依赖 (just_audio, video_player, riverpod, hive)
- [ ] 配置 Riverpod ProviderContainer
- [ ] 实现 AudioPlayerService 封装 just_audio
- [ ] 实现 VideoPlayerService 封装 video_player
- [ ] 实现 PlayerNotifier (状态管理)
- [ ] 创建 MiniPlayer UI (基础播放控制)
- [ ] 实现播放列表队列管理
- [ ] 测试本地音频/视频文件播放
- [ ] 单元测试 Player usecases

**交付物**:
- 可播放本地音频和视频的桌面应用
- 基本播放控制 UI
- 播放状态同步

---

### Phase 2: 媒体库与数据层 (Week 3-4)

**目标**: 完整的媒体库管理功能

**任务清单**:
- [ ] 设计 Hive 数据库 schema (MediaItem, Album, Artist)
- [ ] 实现 LibraryRepository (CRUD 操作)
- [ ] 实现 FileScanner (递归扫描，Isolate)
- [ ] 集成 metadata_god 提取元数据
- [ ] 实现重复检测与去重逻辑
- [ ] 实现 LibraryNotifier (状态管理)
- [ ] 创建 LibraryPage UI
  - Grid/List 视图
  - 搜索框与过滤
  - Tab 切换 (全部/专辑/艺术家)
- [ ] 实现排序与筛选
- [ ] 实现按字母/年代分组
- [ ] 测试扫描 1000+ 文件性能
- [ ] 单元/集成测试 Library 模块

**交付物**:
- 完整的媒体库扫描、索引、浏览功能
- 元数据正确提取显示
- 搜索与过滤可用

---

### Phase 3: Windows 系统集成 (Week 5-6)

**目标**: 原生 Windows 体验

**任务清单**:
- [ ] 调研并选择系统托盘插件 (system_tray / tray_manager)
- [ ] 实现 SystemTrayService (托盘图标、菜单)
- [ ] 实现最小化到托盘逻辑
- [ ] 实现托盘双击显示/隐藏
- [ ] 调研任务栏进度条 (ITaskbarList3 via dart:ffi)
- [ ] 实现 TaskbarService (进度条、覆盖图标)
- [ ] 调研全局热键插件
- [ ] 实现 GlobalHotkeyService (注册/注销热键)
- [ ] 实现文件关联 (注册表写入)
- [ ] 实现命令行参数处理 (打开文件)
- [ ] 实现拖拽文件到应用
- [ ] 实现窗口状态持久化 (Hive)
- [ ] 实现窗口最小/最大化/关闭按钮处理
- [ ] 测试 Windows 10 / Windows 11 兼容性
- [ ] 高 DPI 适配 (125%, 150% 缩放)

**交付物**:
- 应用可最小化到系统托盘
- 任务栏显示播放进度
- 全局热键工作
- 文件关联成功
- 窗口状态正确保存恢复

---

### Phase 4: UI/UX 主体界面 (Week 7-8)

**目标**: 美观、响应式的用户界面

**任务清单**:
- [ ] 配置 Material 3 主题 (动态颜色)
- [ ] 实现主页面框架 (侧边栏 + 内容区 + 迷你播放器)
- [ ] 实现底部导航切换
- [ ] 完善 LibraryPage UI/UX (空状态、加载态、错误态)
- [ ] 实现 PlaylistPage (列表、创建、编辑)
- [ ] 实现 FullScreenPlayerPage
  - 大封面展示
  - 模糊背景
  - 完整播放控制
  - 进度条拖动
  - 音量/均衡器面板
- [ ] 实现 SettingsPage (所有设置项)
- [ ] 响应式布局适配 (手机/平板/桌面)
- [ ] 主题切换 (深色/浅色)
- [ ] 多语言框架 (i18n)
- [ ] 动画与过渡效果
- [ ] 工具提示与帮助
- [ ] Widget 测试关键组件

**交付物**:
- 完整的 UI 界面
- 桌面自适应布局
- 美观的视觉设计
- 交互流畅

---

### Phase 5: 高级功能与优化 (Week 9-10)

**目标**: 性能优化、测试覆盖、功能完善

**任务清单**:
- [ ] 实现网络流媒体播放 (电台、HLS)
- [ ] 实现电台浏览器 / 预设库
- [ ] 实现均衡器 UI 与逻辑 (10段 EQ)
- [ ] 实现睡眠定时器
- [ ] 实现播放统计 (播放次数、时长)
- [ ] 实现历史记录自动保存
- [ ] 实现导入/导出播放列表 (M3U/XSPF)
- [ ] 性能优化:
  - 缩略图缓存大小限制 (LRU)
  - 启动速度优化 (延迟加载)
  - 扫描 10k+ 文件性能优化
  - 内存泄漏检测与修复
- [ ] 包体积分析 (flutter build --analyze-size)
  - 字体、图片资源压缩
  - 移除未使用代码
- [ ] 单元测试 (>80% 覆盖率)
- [ ] Widget 测试 (关键交互)
- [ ] 集成测试 (完整播放流程)
- [ ] 真机测试 (不同 Windows 版本、硬件配置)
- [ ] 高 DPI 多分辨率测试
- [ ] 内存/CPU 分析
- [ ] Bug 修复

**交付物**:
- 功能完整的播放器
- 测试覆盖率达标
- 性能指标达标
- 稳定的 Release 候选版本

---

### Phase 6: 打包、文档与发布 (Week 11-12)

**目标**: 可发布的最终版本

**任务清单**:
- [ ] 编写用户手册 (PDF/在线)
- [ ] 编写开发者文档 (架构说明、API)
- [ ] 完善 CHANGELOG
- [ ] 设计应用图标 (ICO 多分辨率: 16x16 到 256x256)
- [ ] 设计启动画面 (Splash Screen)
- [ ] 制作应用商店截图 (不同分辨率)
- [ ] 编写应用描述 (英文/中文)
- [ ] 准备隐私政策、许可协议
- [ ] Inno Setup 脚本编写
  - 安装/卸载
  - 创建开始菜单快捷方式
  - 创建桌面快捷方式 (可选)
  - 注册文件关联
  - 卸载时清理
- [ ] 构建 Release 版本
- [ ] 代码签名 (可选但推荐)
- [ ] 生成安装包 (Setup.exe)
- [ ] 测试安装流程
- [ ] 发布到 GitHub Releases
- [ ] 可选: 打包为 MSIX 提交 Microsoft Store
- [ ] 收集 Beta 测试反馈
- [ ] 最后 Bug 修复

**交付物**:
- 完整文档
- Windows 安装包 (Setup.exe)
- 发布页面 (GitHub Releases)
- 可安装、可运行的最终产品

---

## 六、关键技术实现要点

### 1. 音频播放器封装

```dart
class AudioPlayerService {
  final _player = AudioPlayer();
  
  Future<void> load(MediaItem item) async {
    final source = item.isUrl 
      ? AudioSource.uri(Uri.parse(item.path))
      : AudioSource.file(item.path);
    await _player.setSource(source);
  }
  
  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Stream<PlayerState> get playerState => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;
}
```

### 2. Isolate 文件扫描

```dart
Future<List<MediaFile>> scanDirectory(String path) async {
  return await compute(_scanInIsolate, path);
}

List<MediaFile> _scanInIsolate(String path) {
  final files = <MediaFile>[];
  final directory = Directory(path);
  
  for (var entity in directory.list(recursive: true, followLinks: false)) {
    if (entity is File && _isSupportedExtension(entity.path)) {
      final metadata = MetadataExtractor.extract(entity.path);
      files.add(MediaFile.fromEntity(entity, metadata));
    }
  }
  return files;
}
```

### 3. 系统托盘集成

```dart
// 使用 system_tray 插件
await SystemTray.init(
  iconPath: 'assets/icons/tray_icon.ico',
  toolTip: 'LihaPlayer',
);

final menu = Menu()
  ..buildFrom([
    MenuItemLabel(label: '播放/暂停', onClicked: (menuItem) => player.toggle()),
    MenuItemLabel(label: '下一曲', onClicked: (menuItem) => player.next()),
    MenuItemSeparator(),
    MenuItemLabel(label: '显示', onClicked: (menuItem) => window.show()),
    MenuItemLabel(label: '退出', onClicked: (menuItem) => exit(0)),
  ]);

await SystemTray.setContextMenu(menu);
```

### 4. 窗口状态持久化

```dart
class WindowStateService {
  final _box = Hive.box('settings');
  
  void saveWindowState(Window window) {
    _box.put('window_bounds', window.bounds.toOuterRect());
    _box.put('window_maximized', window.isMaximized);
  }
  
  Rect? get savedBounds => _box.get('window_bounds');
  bool get isMaximized => _box.get('window_maximized', defaultValue: false);
}
```

---

## 七、风险与挑战

### 技术风险
| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 插件 Windows 支持不完整 | 阻塞功能开发 | 提前验证各插件 Windows 兼容性；必要时开发自定义插件 |
| 后台音频限制 | 音频被系统暂停 | 正确配置 audio_service Windows 实现；测试不同电源模式 |
| 包体积过大 | 分发困难 | 代码混淆、资源压缩、Delayed Load |
| 大型库扫描卡顿 | 用户体验差 | Isolate 扫描、分批处理、进度显示、可取消 |

### 合规风险
- **隐私**: 不收集用户数据，所有媒体库本地存储
- **版权**: 不提供盗版内容源，仅支持用户自有媒体和合法流媒体
- **商店审核**: Microsoft Store 需遵守应用商店政策 (无侵犯版权功能)

### 开发风险
- **跨平台差异**: 即使只做 Windows，仍需处理 Win10/Win11 API 差异
- **插件依赖**: 选择高维护活跃度的包，定期检查安全性
- **测试覆盖不足**: 媒体播放逻辑复杂，需充分边界测试

---

## 八、质量保证

### 测试策略
- **单元测试**: Usecases, Repositories (Mock 数据源) → 目标 80%+
- **Widget 测试**: 关键 UI 组件交互 (按钮点击、导航)
- **集成测试**: E2E 播放流程 (扫描→播放→控制)
- **真机测试**: Win10 22H2, Win11 23H2; 多分辨率; 高 DPI

### 性能指标
- 冷启动 < 3 秒 (SSD)
- 内存占用 < 200MB (空闲), < 500MB (播放 1080p)
- 扫描 10k 文件 < 40 秒
- 包体积 < 100MB (完整安装包)

### 兼容性矩阵
| 系统 | 版本 | 测试状态 |
|-----|------|---------|
| Windows 10 | 1909+ | ✅ |
| Windows 11 | 21H2+ | ✅ |
| 架构 | x64 | ✅ |
| DPI 缩放 | 100%, 125%, 150%, 200% | ✅ |

---

## 九、DevOps 与发布

### 版本控制
- **分支策略**: Git Flow
  - `main` - 稳定发布分支
  - `develop` - 集成分支
  - `feature/*` - 功能分支
  - `release/*` - 预发布分支
  - `hotfix/*` - 紧急修复
- **版本号**: Semantic Versioning 2.0.0 (Major.Minor.Patch)

### CI/CD (GitHub Actions)
```yaml
on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage

  build-windows:
    needs: test
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build windows --release
      - uses: actions/upload-artifact@v3
        with:
          name: windows-exe
          path: build/windows/x64/runner/Release/
```

### 监控与反馈
- **Crash 收集**: Firebase Crashlytics (桌面版)
- **性能监控**: 自定义指标上报 (可选)
- **用户反馈**: GitHub Issues,Discord

---

## 十、后续迭代 (V2.0+)

### 可能功能
- 歌词显示与滚动 (LRC 解析、卡拉OK效果)
- 跨设备同步 (WebSocket 服务器)
- 云存储集成 (Google Drive, Dropbox)
- 音乐识别 (Shazam-like)
- 播客支持 (RSS 订阅)
- 视频下载器 (YouTube 等)
- Chromecast / AirPlay 投屏
- 音频可视化 (Canvas + audio_visualizer)
- 插件系统 (第三方扩展)
- 多语言 UI (i18n 扩展)
- 主题商店
- 音频增强 (空间音效、环绕声)

---

## 十一、关键决策记录

| 决策 | 选项 | 选择 | 理由 |
|------|------|------|------|
| 状态管理 | Riverpod / Bloc | Riverpod | 代码简洁、编译安全、无需 BuildContext |
| 音频引擎 | just_audio / assets_audio_player | just_audio | 活跃维护、功能全面、社区认可 |
| 视频引擎 | video_player / better_player | video_player (初) | 官方维护、轻量、需求简单足够 |
| 本地数据库 | Hive / sqflite | Hive | 纯 Dart、高性能、无原生依赖 |
| 架构模式 | Clean Arch / Feature-First | Feature-First | 功能模块化、团队协作友好 |
| 安装器 | Inno Setup / WiX / NSIS | Inno Setup | 免费、简单、功能足够 |

---

## 十二、任务分解与时间线

### 甘特图 (概览)

```
Week 1-2: [████████░░] Phase 1 - 核心播放
Week 3-4: [████████░░] Phase 2 - 媒体库
Week 5-6: [████████░░] Phase 3 - Windows 集成
Week 7-8: [████████░░] Phase 4 - UI/UX
Week 9-10: [░░░░░░░░░░] Phase 5 - 优化测试
Week 11-12: [░░░░░░░░░░] Phase 6 - 打包发布
```

### 详细任务清单 (可用于 GitHub Projects)

#### Phase 1 任务 (14个)
1. 环境准备 (Flutter 安装、Windows 启用)
2. 项目创建与依赖配置
3. Riverpod Provider 容器设计
4. AudioPlayerService 实现
5. VideoPlayerService 实现
6. PlayerNotifier 状态管理
7. MiniPlayer Widget 开发
8. 播放队列 Usecase
9. 本地音频播放测试
10. 本地视频播放测试
11. 播放控制单元测试
12. 错误处理机制
13. 音频焦点处理
14. Phase 1 集成测试

#### Phase 2 任务 (16个)
... (类似)

---

## 十三、附录

### A. 依赖版本清单

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  riverpod: ^2.4.8
  # Audio
  just_audio: ^0.9.36
  audio_service: ^0.18.12
  # Video
  video_player: ^2.8.1
  # Database
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2
  # File System
  path_provider: ^2.1.1
  file_picker: ^6.1.1
  # Network
  dio: ^5.4.0
  cached_network_image: ^3.3.0
  web_socket_channel: ^2.4.0
  # UI
  flutter_screenutil: ^5.9.0
  audio_video_progress_bar: ^1.0.3
  just_waveform: ^3.0.2
  # Windows Specific (待验证)
  system_tray: ^2.0.3  # 或 tray_manager
  window_manager: ^0.3.6
  # Metadata
  metadata_god: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_test: ^1.1.0
  mockito: ^5.4.2
  integration_test:
    sdk: flutter
```

### B. Windows 配置注意事项

#### `windows/runner/main.cpp`
- 修改应用名称、图标
- 配置 DPI 感知 (Per Monitor v2)
- 设置窗口类名

#### `windows/runner/CMakeLists.txt`
- 链接必要的 Windows 库 (comctl32, dwmapi, shell32)
- 设置编译器选项

#### 清单文件 (app.manifest)
- 请求 DPI 感知
- 声明 Windows 10/11 兼容性
- UAC 级别 (asInvoker)

### C. 注册表操作 (文件关联)

```dart
// 通过 platform channel 调用 Windows RegSetValueEx
// 或使用 win32 插件
void registerFileAssociation(String extension, String description) {
  final key = 'HKEY_CLASSES_ROOT\\.$extension';
  // 写入默认值 = LihaPlayer.AssocFile
  // 创建 HKEY_CLASSES_ROOT\LihaPlayer.AssocFile\shell\open\command
  // 设置为: "C:\Path\LihaPlayer.exe" "%1"
}
```

### D. 快捷键预留

| 功能 | 快捷键 | 说明 |
|------|--------|------|
| 播放/暂停 | Space / Ctrl+Shift+Space | 主界面空格键 / 全局热键 |
| 上一曲 | Ctrl+Shift+Left | 全局 |
| 下一曲 | Ctrl+Shift+Right | 全局 |
| 音量+ | Ctrl+Shift+Up | 全局 |
| 音量- | Ctrl+Shift+Down | 全局 |
| 全屏 | F11 | 视频播放器 |
| 搜索 | Ctrl+F | 全局 |
| 显示/隐藏 | Ctrl+Shift+H | 全局 (显示主窗口) |
| 退出 | Ctrl+Shift+Q | 托盘菜单 |

---

## 十四、总结

本计划方案提供了从零开发 **LihaPlayer Windows 桌面播放器** 的完整路线图，涵盖:

✅ **技术选型** - 基于 2024-2025 最新生态  
✅ **Windows 特定优化** - 托盘、热键、文件关联、打包  
✅ **架构设计** - Feature-First + Clean Architecture  
✅ **12周开发计划** - 分阶段交付，风险可控  
✅ **关键决策** - 明确技术选型理由  
✅ **实施要点** - 代码片段与实现参考  

**下一步行动**:

1. **第 0 周**: 环境准备、项目脚手架
2. **第 1 周**: 启动 Phase 1，验证核心播放功能
3. 每周迭代，每日 Standup 同步进度
4. 每周五进行代码审查

**成功标准**:
- 功能完整 (播放、库管理、系统集成)
- 性能达标 (启动<3s, 内存<200MB)
- 稳定可靠 (播放2小时无崩溃)
- 用户体验优秀 (Material 3, 响应式)

祝开发顺利! 🎵🎬

---

**文档版本**: v1.0  
**最后更新**: 2025-04-14  
**作者**: LihaPlayer Development Team

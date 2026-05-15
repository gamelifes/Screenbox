/// 应用枚举定义
/// 所有枚举统一在此定义，便于管理和复用

/// 播放器状态
enum PlayerState {
  idle, // 空闲，无媒体
  loading, // 加载中
  playing, // 正在播放
  paused, // 已暂停
  stopped, // 已停止
  error, // 错误状态
  completed, // 播放完成
}

/// 媒体类型
enum MediaType {
  audio, // 音频
  video, // 视频
  stream, // 流媒体
}

/// 播放模式
enum PlaybackMode {
  sequential, // 顺序播放
  repeatOne, // 单曲循环
  repeatAll, // 列表循环
  shuffle, // 随机播放
}

/// 扫描状态
enum ScanStatus {
  idle, // 空闲
  scanning, // 扫描中
  paused, // 暂停
  completed, // 完成
  error, // 错误
}

/// 媒体库视图模式
enum LibraryViewMode {
  list, // 列表视图
  grid, // 网格视图
}

/// 主题模式
enum ThemeMode {
  light, // 浅色
  dark, // 深色
  system, // 跟随系统
}

/// 排序方式
enum SortBy {
  title, // 标题
  artist, // 艺术家
  album, // 专辑
  dateAdded, // 添加时间
  duration, // 时长
  playCount, // 播放次数
  random, // 随机
}

/// 排序方向
enum SortOrder {
  ascending, // 升序
  descending, // 降序
}

/// 设置类别
enum SettingsCategory {
  general, // 通用
  appearance, // 外观
  playback, // 播放
  library, // 媒体库
  integrations, // 集成
  shortcuts, // 快捷键
  about, // 关于
}

/// 窗口状态
enum WindowState {
  normal, // 普通
  minimized, // 最小化
  maximized, // 最大化
  fullscreen, // 全屏
}

/// 日志级别
enum LogLevel {
  verbose, // 详细
  debug, // 调试
  info, // 信息
  warning, // 警告
  error, // 错误
  fatal, // 严重
}

/// 网络请求方法
enum HttpMethod {
  get,
  post,
  put,
  delete,
  patch,
  head,
  options,
}

/// 媒体库扫描范围
enum ScanScope {
  singleDirectory, // 单个目录
  multipleDirectories, // 多个目录
  allDrives, // 所有驱动器
}

/// 文件系统类型
enum FileSystemType {
  local, // 本地文件系统
  network, // 网络共享
  removable, // 可移动设备
}

/// 任务优先级 (用于 Isolate 调度)
enum TaskPriority {
  high, // 高优先级 (用户交互相关)
  normal, // 普通优先级
  low, // 低优先级 (后台扫描、清理)
}

/// 应用生命周期状态
enum AppLifecycleState {
  detached, // 已分离 (应用正在终止)
  inactive, // 非活跃 (应用在前台但不可交互)
  paused, // 暂停 (应用在后台)
  resumed, // 恢复 (应用在前台活跃)
  hidden, // 隐藏 (应用在后台且不可见)
}

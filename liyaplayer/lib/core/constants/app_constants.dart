/// 应用全局常量定义
/// 所有不应变化的数值、字符串、Duration 都集中在此

class AppConstants {
  // 私有构造函数，禁止实例化
  AppConstants._();

  // ============================================
  // 应用信息
  // ============================================
  static const String appName = 'LihaPlayer';
  static const String appVersion = '1.0.0';
  static const String organization = 'com.lihaplayer';

  // ============================================
  // 媒体格式支持
  // ============================================
  /// 支持的音频格式扩展名
  static const List<String> supportedAudioFormats = [
    '.mp3',
    '.flac',
    '.aac',
    '.m4a',
    '.wav',
    '.ogg',
    '.wma',
    '.aiff',
    '.aif',
    '.ape',
  ];

  /// 支持的视频格式扩展名
  static const List<String> supportedVideoFormats = [
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.mpg',
    '.mpeg',
  ];

  /// 所有支持的格式
  static const List<String> supportedFormats = [
    ...supportedAudioFormats,
    ...supportedVideoFormats,
  ];

  // ============================================
  // 文件扫描配置
  // ============================================
  /// 扫描时每个 Isolate 处理的最小文件数
  static const int scanBatchSize = 100;

  /// 最大并发扫描 Isolate 数量
  static const int maxScanIsolates = 4;

  /// 扫描超时时间 (毫秒)
  static const int scanTimeoutMs = 300000; // 5 分钟

  /// 元数据读取超时 (毫秒)
  static const int metadataReadTimeoutMs = 10000; // 10 秒

  // ============================================
  // 播放器配置
  // ============================================
  /// 默认音量 (0.0 - 1.0)
  static const double defaultVolume = 0.8;

  /// 默认播放速度
  static const double defaultPlaybackSpeed = 1.0;

  /// 音量调节步长
  static const double volumeStep = 0.1;

  /// 进度跳转步长 (秒)
  static const int seekStepSeconds = 10;

  /// 快进快退倍数 (秒)
  static const List<int> seekMultipliers = [10, 30, 60, 300];

  // ============================================
  // 缓存配置
  // ============================================
  /// 缩略图缓存最大大小 (MB)
  static const int thumbnailCacheMaxSizeBytes = 100 * 1024 * 1024; // 100 MB

  /// 网络图片缓存最大条目数
  static const int networkImageCacheMaxEntries = 200;

  // ============================================
  // 数据库配置
  // ============================================
  /// Hive Box 名称 - 歌曲
  static const String boxNameSongs = 'songs';

  /// Hive Box 名称 - 专辑
  static const String boxNameAlbums = 'albums';

  /// Hive Box 名称 - 艺术家
  static const String boxNameArtists = 'artists';

  /// Hive Box 名称 - 视频
  static const String boxNameVideos = 'videos';

  /// Hive Box 名称 - 播放列表
  static const String boxNamePlaylists = 'playlists';

  /// Hive Box 名称 - 设置
  static const String boxNameSettings = 'settings';

  // ============================================
  // Windows 集成配置
  // ============================================
  /// 托盘图标 ID (资源文件中的 ID)
  static const int trayIconId = 101;

  /// 全局热键 modifiers (Ctrl + Shift)
  static const int hotkeyModifiers = 0x0002 | 0x0004; // MOD_CONTROL | MOD_SHIFT

  /// 默认全局热键 - 播放/暂停
  static const int hotkeyPlayPause = 0x20; // VK_SPACE

  /// 默认全局热键 - 下一曲
  static const int hotkeyNext = 0x27; // VK_RIGHT

  /// 默认全局热键 - 上一曲
  static const int hotkeyPrevious = 0x25; // VK_LEFT

  /// 默认全局热键 - 增加音量
  static const int hotkeyVolumeUp = 0x26; // VK_UP

  /// 默认全局热键 - 减少音量
  static const int hotkeyVolumeDown = 0x28; // VK_DOWN

  // ============================================
  // 网络配置
  // ============================================
  /// HTTP 连接超时
  static const Duration httpConnectTimeout = Duration(seconds: 10);

  /// HTTP 接收超时
  static const Duration httpReceiveTimeout = Duration(seconds: 30);

  /// Dio 重试次数
  static const int dioRetryCount = 3;

  /// 用户代理 (用于网络请求)
  static const String userAgent = 'LihaPlayer/1.0 (Windows)';

  // ============================================
  // UI 配置
  // ============================================
  /// 迷你播放器高度
  static const double miniPlayerHeight = 80.0;

  /// 默认封面图片路径
  static const String defaultAlbumArtPath =
      'assets/images/default_album_art.png';

  /// 列表项最小高度
  static const double listItemMinHeight = 60.0;

  /// 网格项最小宽度
  static const double gridItemMinWidth = 150.0;

  // ============================================
  // 性能配置
  // ============================================
  /// 启动完成最大时间 (秒)
  static const int maxStartupTimeSeconds = 3;

  /// 内存占用警告阈值 (MB)
  static const int memoryWarningThresholdMb = 150;

  /// 内存占用危险阈值 (MB)
  static const int memoryCriticalThresholdMb = 200;

  // ============================================
  // 文件关联扩展名
  // ============================================
  static const List<String> fileAssociationExtensions = [
    ...supportedAudioFormats,
    ...supportedVideoFormats,
  ];
}

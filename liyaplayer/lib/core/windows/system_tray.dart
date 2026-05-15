import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

/// 系统托盘服务
///
/// 功能：
/// - 显示托盘图标
/// - 托盘菜单（显示/隐藏、播放控制、退出）
/// - 托盘双击显示主窗口
class SystemTrayService {
  static final SystemTrayService _instance = SystemTrayService._internal();
  static SystemTrayService get instance => _instance;
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  final SystemTray _systemTray = SystemTray();
  bool _isInitialized = false;

  /// 播放状态回调
  void Function()? onShowWindow;
  void Function()? onHideWindow;
  void Function()? onToggleWindow;
  void Function()? onPlayPause;
  void Function()? onNext;
  void Function()? onPrevious;
  void Function()? onQuit;

  /// 初始化托盘（带回调参数）
  Future<void> initialize({
    void Function()? onShowWindow,
    void Function()? onHideWindow,
    void Function()? onToggleWindow,
    void Function()? onPlayPause,
    void Function()? onNext,
    void Function()? onPrevious,
    void Function()? onQuit,
  }) async {
    if (_isInitialized) return;

    // 设置回调
    this.onShowWindow = onShowWindow;
    this.onHideWindow = onHideWindow;
    this.onToggleWindow = onToggleWindow;
    this.onPlayPause = onPlayPause;
    this.onNext = onNext;
    this.onPrevious = onPrevious;
    this.onQuit = onQuit;

    // 获取图标路径 - 使用相对路径，Windows system_tray 支持 ICO
    String iconPath;
    if (Platform.isWindows) {
      // 使用 assets 中的 ICO 图标
      // 注意：Windows system_tray 需要绝对路径
      iconPath = 'assets/icons/app_icon.ico';
    } else {
      iconPath = '';
    }

    try {
      // 初始化托盘
      await _systemTray.initSystemTray(
        title: 'LihaPlayer',
        iconPath: iconPath,
        toolTip: 'LihaPlayer - 音乐播放器',
      );

      // 构建菜单
      await _buildContextMenu();

      // 注册事件处理器
      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          // 点击托盘图标：toggle 窗口显示状态
          onToggleWindow?.call();
        } else if (eventName == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
        } else if (eventName == 'doubleClick') {
          // 双击托盘图标：显示窗口
          onShowWindow?.call();
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('SystemTray 初始化失败: $e');
    }
  }

  /// 构建右键菜单
  Future<void> _buildContextMenu() async {
    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: '显示窗口',
        onClicked: (menuItem) {
          debugPrint('[SystemTray] onClicked 显示窗口 START');
          try {
            onShowWindow?.call();
            debugPrint('[SystemTray] onClicked 显示窗口 END');
          } catch (e, st) {
            debugPrint('[SystemTray] onClicked ERROR: $e\n$st');
          }
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '播放/暂停',
        onClicked: (menuItem) => onPlayPause?.call(),
      ),
      MenuItemLabel(
        label: '上一曲',
        onClicked: (menuItem) => onPrevious?.call(),
      ),
      MenuItemLabel(
        label: '下一曲',
        onClicked: (menuItem) => onNext?.call(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '退出',
        onClicked: (menuItem) => onQuit?.call(),
      ),
    ]);
    await _systemTray.setContextMenu(menu);
  }

  /// 更新托盘提示
  Future<void> updateTooltip(String tooltip) async {
    if (!_isInitialized) return;
    await _systemTray.setToolTip(tooltip);
  }

  /// 设置托盘图标
  Future<void> setIcon(String iconPath) async {
    if (!_isInitialized) return;
    await _systemTray.setImage(iconPath);
  }

  /// 显示通知
  Future<void> showNotification(String title, String body) async {
    // system_tray 不支持通知，使用系统通知替代
    debugPrint('通知: $title - $body');
  }

  /// 释放资源
  Future<void> dispose() async {
    if (!_isInitialized) return;
    await _systemTray.destroy();
    _isInitialized = false;
  }
}

/// 全局托盘服务单例
final systemTrayService = SystemTrayService();

import 'dart:ffi';
import 'package:ffi/ffi.dart' as ffi_alloc;
import 'package:win32/win32.dart';

/// Windows 窗口样式修改服务
/// 用于将原生窗口从有标题栏样式改为无边框样式
class WindowStyler {
  WindowStyler._internal();
  static final WindowStyler _instance = WindowStyler._internal();
  factory WindowStyler() => _instance;

  /// 将指定标题的窗口改为无边框样式（WS_POPUP）
  /// 返回是否成功
  Future<bool> setWindowBorderless(String windowTitle) async {
    try {
      // 使用 FindWindowW 查找窗口
      final titlePtr = windowTitle.toNativeUtf16(allocator: ffi_alloc.calloc);
      final hwnd = FindWindow(nullptr, titlePtr);
      ffi_alloc.calloc.free(titlePtr);

      if (hwnd == 0) {
        return false;
      }

      // 获取当前窗口样式
      final currentStyle = GetWindowLongPtr(hwnd, GWL_STYLE);

      // 移除标题栏、系统菜单、边框等样式，添加 WS_POPUP
      final newStyle = (currentStyle &
              ~(WS_CAPTION |
                WS_SYSMENU |
                WS_THICKFRAME |
                WS_MINIMIZE |
                WS_MAXIMIZE)) |
          WS_POPUP | WS_VISIBLE;

      // 设置新样式
      final result = SetWindowLongPtr(hwnd, GWL_STYLE, newStyle);
      if (result == 0) {
        return false;
      }

      // 触发窗口重绘
      SetWindowPos(
        hwnd,
        NULL,
        0,
        0,
        0,
        0,
        SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED | SWP_NOSIZE | SWP_NOMOVE,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

/// 将窗口恢复到有边框样式
Future<bool> setWindowFramed(String windowTitle) async {
try {
final titlePtr = windowTitle.toNativeUtf16(allocator: ffi_alloc.calloc);
final hwnd = FindWindow(nullptr, titlePtr);
ffi_alloc.calloc.free(titlePtr);

if (hwnd == 0) {
return false;
}

final currentStyle = GetWindowLongPtr(hwnd, GWL_STYLE);
final newStyle =
(currentStyle & ~WS_POPUP) | WS_OVERLAPPEDWINDOW | WS_VISIBLE;

final result = SetWindowLongPtr(hwnd, GWL_STYLE, newStyle);
if (result == 0) {
return false;
}

SetWindowPos(
hwnd,
NULL,
0,
0,
0,
0,
SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED | SWP_NOSIZE | SWP_NOMOVE,
);

return true;
} catch (e) {
return false;
}
}

/// 最小化窗口
Future<bool> minimizeWindow(String windowTitle) async {
try {
final titlePtr = windowTitle.toNativeUtf16(allocator: ffi_alloc.calloc);
final hwnd = FindWindow(nullptr, titlePtr);
ffi_alloc.calloc.free(titlePtr);

if (hwnd == 0) {
return false;
}

// 发送 WM_SYSCOMMAND 消息，SC_MINIMIZE = 0xF020
PostMessage(hwnd, WM_SYSCOMMAND, SC_MINIMIZE, 0);
return true;
} catch (e) {
return false;
}
}

/// 关闭窗口
Future<bool> closeWindow(String windowTitle) async {
try {
final titlePtr = windowTitle.toNativeUtf16(allocator: ffi_alloc.calloc);
final hwnd = FindWindow(nullptr, titlePtr);
ffi_alloc.calloc.free(titlePtr);

if (hwnd == 0) {
return false;
}

// 发送 WM_CLOSE 消息关闭窗口
PostMessage(hwnd, WM_CLOSE, 0, 0);
return true;
} catch (e) {
return false;
}
}
}
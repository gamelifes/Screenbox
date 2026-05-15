# LihaPlayer - 研究发现与决策记录

**创建日期**: 2025-04-14  
**最后更新**: 2025-04-14

---

## 初始技术选型研究

### 状态管理方案对比

| 方案 | 优点 | 缺点 | 决定 |
|------|------|------|------|
| Provider | 简单、官方支持、社区大 | 复杂状态管理困难、测试不便、BuildContext 依赖 | ❌ 不推荐 |
| Riverpod | 编译时安全、无需 BuildContext、测试友好、代码简洁 | 学习曲线稍陡峭 | ✅ **已采用** |
| Bloc | 事件驱动、状态流清晰、适合大型应用 | 模板代码多、较复杂 | ✅ 备用方案 |
| GetX | 功能全面、简单易用 | 紧耦合、违反 Flutter 最佳实践 | ❌ 不推荐 |

**决策理由**: Riverpod 2.4+ 在现代 Flutter 生态中最适合中等规模桌面应用，提供最佳的开发体验和测试支持。

---

### 音频播放引擎选择

| 方案 | Windows 支持 | 功能 | 维护状态 | 决定 |
|------|-------------|------|---------|------|
| just_audio | ✅ DirectShow/Wasapi | 无缝播放、播放列表、流媒体、均衡器 | 活跃，社区推荐 | ✅ **已采用** |
| audioplayers | ✅ 多后端支持 | 基础播放、流媒体 | 活跃 | ✅ 备用 |
| audio_service | ✅ Windows 支持 | 后台音频、锁屏控制、通知栏 | 活跃 | ✅ **已采用** |

**决策理由**: just_audio 功能最全面，audio_service 专为后台音频设计，两者组合为最佳实践。

---

### 视频播放选择

| 方案 | 优势 | 劣势 | 决定 |
|------|------|------|------|
| video_player (官方) | 官方维护、轻量、稳定 | 功能基础 | ✅ **初期采用** |
| better_player | 更多格式、画中画、高级控制 | 包体积较大、复杂度高 | ⚠️ 未来扩展 |

**决策理由**: 初期使用官方 video_player 快速迭代，如有格式需求再评估迁移。

---

### 本地数据库选择

| 方案 | 类型 | 性能 | 功能 | 决定 |
|------|------|------|------|------|
| Hive | NoSQL (键值) | ⚡ 极快 | 简单查询、无关联 | ✅ **已采用** |
| Drift (Moor) | SQLite | 快 | 类型安全 SQL、migrations、复杂查询 | ✅ 备用 |
| sembast | NoSQL | 快 | 纯 Dart、简单 | ❌ 备选 |

**决策理由**: 媒体库数据结构相对简单，Hive 性能优异且无需原生依赖。如果未来需要复杂关联查询，可迁移至 Drift。

---

## Windows 平台特定问题

### 系统托盘实现方案

| 插件 | 维护状态 | API 质量 | 文档 | 决定 |
|------|---------|---------|------|------|
| system_tray | 活跃更新 | 良好 | 有文档 | ✅ **已采用** |
| tray_manager | 维护缓慢 | 一般 | 有限 | ❌ 不推荐 |

**验证要求**: Phase 5.1 需要测试系统托盘在 Windows 10/11 的稳定性。

---

### 全局快捷键实现

**问题**: Flutter 官方无全局热键支持，需要平台通道或第三方插件。

| 方案 | 可行性 | 备注 |
|------|--------|------|
| global_hotkeys 插件 | ⚠️ 需验证 Windows 支持 | 较早的插件，可能需维护 |
| 自定义平台通道 | ✅ 100% 可行 | 使用 Windows RegisterHotKey API |
| 第三方 win32 插件 | ✅ | `package:win32` 提供 WinAPI 封装 |

**决策**: 先用 `global_hotkeys` 验证，不可用则实现自定义平台通道。

---

### 文件关联实现

**方案**: 通过平台通道调用 Windows RegSetValueEx 写入注册表。

**注册表路径**:
```
HKEY_CLASSES_ROOT\.mp3
  (Default) = "LihaPlayer.AssocFile"

HKEY_CLASSES_ROOT\LihaPlayer.AssocFile\shell\open\command
  (Default) = "C:\Program Files\LihaPlayer\LihaPlayer.exe" "%1"
```

**安装器支持**: Inno Setup 脚本自动注册，卸载时清理。

---

### 任务栏集成

**技术**: Windows Taskbar API (ITaskbarList3, ITaskbarList4)

**方法**: 使用 `dart:ffi` 调用 `shell32.dll` 或 `dart:win32` 插件 (如果可用)

**功能**:
- 进度条: `ITaskbarList3::SetProgressValue()`
- 覆盖图标: `ITaskbarList3::SetOverlayIcon()`
- 缩略图工具栏: `ITaskbarList3::ThumbBarAddButtons()`

**风险**: 需要编写 C++/CLI 或 C 包装层，Complexity 中等。评估是否核心用户需求。

---

## 性能基准

### 启动时间目标
- **冷启动**: < 3 秒 (从点击到主界面可交互)
- **热启动**: < 1 秒

**优化手段**:
- 延迟加载非必要插件
- 预加载核心依赖
- 减少初始路由复杂度

---

### 内存占用目标
- **空闲**: < 100MB
- **播放音频**: < 150MB
- **播放视频**: < 200MB

**优化手段**:
- 缩略图缓存大小限制 (100MB max)
- 及时 dispose VideoPlayerController
- 避免内存泄漏 (监听器注销)

---

### 文件扫描性能
- **10,000 文件**: < 60 秒 (全量扫描)
- **增量扫描**: < 5 秒 (100 新文件)

**优化手段**:
- 使用 Isolate 并行扫描
- 批处理数据库插入
- 进度反馈避免假死

---

## 待验证技术问题

### ❗ 需要早期验证 (Phase 0-1)

**最后验证日期**: 2025-04-14  
**验证状态**: 部分完成，部分发现阻塞问题

| 依赖包 | 最新版本 | Windows 兼容性 | 验证结果 | 优先级 | 状态 |
|--------|---------|---------------|----------|--------|------|
| just_audio | 0.9.36 | ⚠️ 需验证 | 未验证 | P0 | ❓ 待验证 |
| audio_service | 0.18.12 | ⚠️ 需验证 | 未验证 | P0 | ❓ 待验证 |
| window_manager | 0.3.4 | ⚠️ 需验证 | 未验证 | P1 | ❓ 待验证 |
| system_tray | 2.0.3 | ⚠️ 需验证 | 未验证 | P1 | ❓ 待验证 |
| metadata_god | 1.0.0 | ❌ 未知 | 未验证 | P0 | ❓ 待验证 |
| global_hotkeys | 未知 | ❌ 未知 | 未验证 | P1 | ❓ 待验证 |
| file_picker | 5.3.3 | ✅ 支持 | 可信 (社区广泛使用) | P2 | ✅ 可信 |
| hive | 2.2.3 | ✅ 支持 | 可信 (社区广泛使用) | P2 | ✅ 可信 |

---

### ⚠️ 环境验证结果 (2025-04-14)

**Phase 0.1 实际验证**:

| 组件 | 预期状态 | 实际结果 | 是否可用 | 对开发的影响 |
|------|---------|---------|----------|-------------|
| Flutter SDK | 3.19+ | **3.24.5** (stable) | ✅ **超出预期** | 无影响，功能完整 |
| Windows 桌面支持 | 已启用 | Windows 设备可见 | ✅ **已就绪** | 可运行 Debug 模式 |
| Visual Studio C++ | 已安装 | **MSVC 缺失** (cl.exe not found) | ❌ **阻塞** | 无法构建 Release 包 |
| CMake | 已安装 | **缺失** | ❌ **阻塞** | 影响构建 |
| Git | 已可用 | 可用 (PortableGit) | ✅ | 版本控制正常 |

**关键发现**:
1. ✅ Flutter 版本达标：3.24.5 > 3.19，满足所有现代特性
2. ✅ Windows 桌面支持已正确启用：`flutter devices` 显示 `Windows (desktop)` 设备
3. ❌ **严重阻塞**: Visual Studio 安装了但 **C++ 工作负载未安装**
   - 原因分析: 可能只安装了 .NET 工作负载，未装 Desktop development with C++
   - 影响: `flutter build windows --release` 必失败
   - 临时方案: Debug 模式仍可运行 (`flutter run -d windows`)
4. ❌ CMake 缺失

**立即行动项** (用户必须执行):
```powershell
# 方案 A: Visual Studio Installer 修复 (推荐)
1. 启动 "Visual Studio Installer" (开始菜单搜索)
2. 选择 "Modify" (修改)
3. Workloads 标签页 → 勾选 "Desktop development with C++"
4. Individual components 标签页 → 确保包含:
   - MSVC v143 (或 v142) - VS 2022 C++ x64/x86 build tools
   - C++ CMake tools for Windows
   - Windows 10/11 SDK (最新版本)
5. 点击 "Modify" 等待安装完成 (约 15-30 分钟)

# 方案 B: 如果 VS Installer 不可用，重新安装 VS
# 下载: https://visualstudio.microsoft.com/downloads/
# 选择 "Community 2022" → 安装时选择 "Desktop development with C++"
```

**验证修复**:
```powershell
# 重启终端后执行
cl.exe  # 应显示编译器版本
cmake --version  # 应显示版本信息
flutter doctor -v  # Visual Studio 应显示 ✓
```

**决策**: Phase 0.1 标记为 **部分完成**，等待用户修复 C++ 工具链后再继续 Phase 0.2。

---

## 依赖项待确认列表 (原始)

### ADR-001: 采用 Feature-First + Clean Architecture 混合模式
**日期**: 2025-04-14  
**状态**: 已采纳

**决策**: 在 Feature-First 组织的基础上引入 Clean Architecture 分层 (domain, data, presentation)。

**理由**:
- Feature-First 便于功能代码聚合，易于维护
- Clean Architecture 提供清晰的分层和依赖方向
- 适合中等规模应用，兼顾开发效率和架构清晰度

**后果**:
- 目录层级加深，但逻辑清晰
- 需要更多模型转换代码 (entity ↔ model)
- Use Case 类提供明确的业务逻辑封装

---

### ADR-002: 使用 Riverpod 而非 Provider 进行状态管理
**日期**: 2025-04-14  
**状态**: 已采纳

**决策**: 采用 Riverpod 2.4+ 作为主要状态管理方案。

**理由**:
- 编译时安全，减少运行时错误
- 不依赖 BuildContext，适合桌面应用多窗口场景
- Provider 容器可全局访问，便于测试
- 社区支持好，文档完善

**后果**:
- 需要学习 Riverpod 语法 (但较简单)
- 需要生成代码 (riverpod_generator + build_runner)

---

### ADR-003: 使用 Hive 作为主数据库
**日期**: 2025-04-14  
**状态**: 已采纳

**决策**: Hive 2.2+ 作为本地持久化存储方案。

**理由**:
- 纯 Dart 实现，无原生依赖，简化 Windows 打包
- 性能优异，适合高频读写
- 简单 API，快速上手
- 媒体库数据结构相对简单，NoSQL 足够

**未来迁移**: 如需要复杂 SQL 查询，可迁移至 Drift。

---

### ADR-004: 分阶段开发，优先音频功能
**日期**: 2025-04-14  
**状态**: 已采纳

**决策**: Phase 1 聚焦音频播放 (music library)，Phase 4 再处理流媒体，视频播放贯穿 Phase 1-2。

**理由**:
- 音频是媒体播放器的核心功能，复杂度适中
- 视频播放可复用音频播放器的状态管理架构
- 降低初期复杂度，快速验证核心架构

**依赖关系**:
- Phase 1 (音频播放) → Phase 2 (媒体库) → Phase 3 (播放列表)
- Phase 4 (流媒体) → Phase 5 (Windows 集成) → Phase 6 (优化)

---

## 依赖项待确认列表

| 依赖包 | 最新版本 | Windows 兼容性 | 验证优先级 | 状态 |
|--------|---------|---------------|-----------|------|
| just_audio | 0.9.36 | ⚠️ 需验证 | P0 | ❓ 待验证 |
| audio_service | 0.18.12 | ⚠️ 需验证 | P0 | ❓ 待验证 |
| window_manager | 0.3.4 | ⚠️ 需验证 | P1 | ❓ 待验证 |
| system_tray | 2.0.3 | ⚠️ 需验证 | P1 | ❓ 待验证 |
| metadata_god | 1.0.0 | ❌ 未知 | P0 | ❓ 待验证 |
| global_hotkeys | 未知 | ❌ 未知 | P1 | ❓ 待验证 |
| file_picker | 5.3.3 | ✅ 支持 | P2 | ✅ 可信 |
| hive | 2.2.3 | ✅ 支持 | P2 | ✅ 可信 |

**验证计划**:
- **P0 (必须)**: Phase 0 期间完成基础测试
- **P1 (重要)**: Phase 1-2 期间完成
- **P2 (次要)**: 按需验证，可用即用

---

## 工具与脚本

### 构建脚本
待 Phase 7 创建 `build.bat`，封装以下命令:
```bat
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build windows --release
copy build\windows\x64\runner\Release\LihaPlayer.exe .
```

---

## 视频渲染技术研究 (2026-05-13)

### 问题

media_kit_video 的 Video widget 自带内置控制栏，无法禁用。需要实现无内置控件的视频播放器以支持自定义控制栏。

### 尝试方案

| 方案 | 思路 | 结果 | 原因 |
|------|------|------|------|
| **Texture 直接渲染** | `VideoController.textureId` + `Texture` widget | ❌ 失败 | media_kit_video 2.x 不暴露 `textureId` getter |
| **just_video 包** | 第三方包获取 textureId | ❌ 失败 | 包不存在于 pub 源 |
| **Video + NoVideoControls** | `Video(controls: NoVideoControls)` + overlay | ✅ 成功 | 工作但需额外处理控件拦截 |

### 最终方案

```dart
Stack(
  fit: StackFit.expand,
  children: [
    Video(
      controller: controller,
      controls: NoVideoControls,
    ),
    // 透明 overlay 拦截所有点击，防止原生控件显示
    Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
      ),
    ),
  ],
)
```

### 关键发现

1. **media_kit_video 2.x API 变化**: 不再暴露 `textureId`，Texture 方案不可行
2. **NoVideoControls**: 使用 `NoVideoControls` 可以禁用原生控件，但仍需 overlay 防止控件层显示
3. **GestureDetector overlay**: 透明拦截所有点击事件，确保原生控件不会响应用户交互

---

**END OF FINDINGS (持续更新中...)**

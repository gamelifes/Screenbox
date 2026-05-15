# LihaPlayer - 架构决策记录 (ADRs)

**项目**: LihaPlayer Windows 桌面播放器  
**技术栈**: Flutter + Riverpod + Hive  
**文档状态**: 活跃更新

---

## ADR-001: 采用 Feature-First + Clean Architecture 混合模式

### 日期
2025-04-14

### 状态
✅ 已采纳

### 上下文
我们需要组织一个 Flutter 桌面应用的代码结构。项目规模中等（预计 10,000+ 行代码），需要良好的可维护性和扩展性。

### 决策
采用 **Feature-First** (功能优先) 组织方式，结合 **Clean Architecture** 分层 (domain, data, presentation)。

**目录结构**:
```
lib/
├── features/
│   ├── player/      # 播放器功能 (独立模块)
│   ├── library/     # 媒体库功能
│   ├── playlist/    # 播放列表
│   ├── streaming/   # 流媒体
│   ├── settings/    # 设置
│   └── ui/          # 通用 UI
├── core/            # 跨功能核心层
└── shared/          # 共享资源
```

每个 feature 内部使用 Clean Architecture 三层：
```
feature/
├── domain/     # 业务逻辑 (entities, repositories, usecases)
├── data/       # 数据实现 (models, repositories, datasources)
└── presentation/ # UI 层 (providers, widgets, pages)
```

### 理由
- **Feature-First**: 按功能聚合代码，易于重构、删除、复用整个功能模块
- **Clean Architecture**: 清晰的依赖方向 (domain ← data ← presentation)，便于测试和替换实现
- **混合优势**: 既保持功能代码集中，又维持分层分离的关注点分离

### 后果
**正面**:
- 新功能添加路径清晰
- 单元测试边界明确
- 团队协作时减少代码冲突
- 未来迁移/重构更容易

**负面**:
- 目录层级较深 (3-4 层)
- 需要更多模型转换代码 (entity ↔ model)
- 初期需要更多模板文件

### 替代方案
| 方案 | 优点 | 缺点 |
|------|------|------|
| Layer-First (先按层再按功能) | 简单直观 | 功能代码分散，跨目录跳转频繁 |
| Monolith (不分层) | 快速启动 | 难以测试，紧耦合，后期维护成本高 |

---

## ADR-002: 使用 Riverpod 2.4+ 进行状态管理

### 日期
2025-04-14

### 状态
✅ 已采纳

### 上下文
Flutter 状态管理方案众多，需要选择适合桌面应用的方案。

### 决策
采用 **Riverpod 2.4+** 作为主要状态管理方案，配合 `riverpod_generator` + `build_runner` 实现编译时安全。

### 理由
| 标准 | Riverpod 表现 |
|------|---------------|
| 编译时安全 | ✅ Provider 不依赖 BuildContext，编译检查错误 |
| 测试友好 | ✅ Provider 可独立测试，无需 Widget 测试 |
| 代码简洁 | ✅ 不依赖 InheritedWidget，代码更清晰 |
| 多窗口支持 | ✅ Provider 全局访问，适合桌面多窗口场景 |
| 社区生态 | ✅ 活跃维护，丰富的插件和文档 |

**对比其他方案**:
- **Provider**: 需要 BuildContext，复杂状态管理困难 ❌
- **Bloc**: 模板代码多，学习曲线陡峭 ⚠️
- **GetX**: 紧耦合，违反 Flutter 最佳实践 ❌

### 后果
**正面**:
- 减少运行时错误
- 提升开发效率
- 简化测试代码
- 便于状态共享 (跨页面)

**负面**:
- 需要学习 Riverpod 语法
- 需要配置代码生成 (`build_runner`)
- 部分第三方包可能依赖 Provider (需适配)

### 实践约定
1. 使用 `riverpod_annotation` 注解生成 providers
2. 避免在 UI 层直接创建 Provider，优先级：global → parent → local
3. 复杂的业务逻辑封装在 Use Cases，Provider 只负责状态转换

---

## ADR-003: 使用 Hive 2.2+ 作为主数据库

### 日期
2025-04-14

### 状态
✅ 已采纳

### 上下文
需要选择本地持久化存储方案。媒体库数据包括歌曲、专辑、艺术家、播放列表等。

### 决策
使用 **Hive 2.2+** (纯 Dart NoSQL 数据库) 作为主要存储方案。

### 理由
| 评估项 | Hive | Drift (SQLite) | sembast |
|--------|------|----------------|---------|
| 性能 | ⚡ 极快 | 快 | 快 |
| 原生依赖 | ❌ 无 | ⚠️ 需要 | ❌ 无 |
| 查询能力 | ⚠️ 简单 | ✅ 复杂 SQL | ⚠️ 简单 |
| 类型安全 | ✅ (TypeAdapters) | ✅ (代码生成) | ⚠️ 手动 |
| 学习曲线 | 简单 | 中等 | 简单 |

**选择 Hive 的理由**:
1. **无原生依赖**: 简化 Windows 打包，避免平台兼容问题
2. **性能优异**: 键值存储对媒体库查询足够快
3. **简单易用**: API 简洁，快速上手
4. **纯 Dart**: 跨平台一致性高

**未来迁移**: 如果未来需要复杂关联查询（如统计、报表），可评估迁移到 Drift。

### 后果
**正面**:
- 快速开发迭代
- 打包简化 (无需处理 SQLite 原生库)
- 性能可接受 (< 10ms 查询)
- 减少依赖冲突风险

**负面**:
- 缺乏复杂查询能力 (JOIN, GROUP BY 等)
- 需要手动处理数据关系 (手动建立索引)
- Schema 迁移需要手动编写

### 实践约定
1. 设计数据结构时预判查询模式，建立合适的 Box 结构
2. 关键查询使用索引 (Box 的 `values.where()` 可能较慢)
3. 批量操作使用 `Hive.lazyPutAll()` 或 `writeTxn()` 包装
4. 所有实体类实现 `HiveObject` 以便 `save()`、`delete()`

---

## ADR-004: 分阶段开发，音频优先

### 日期
2025-04-14

### 状态
✅ 已采纳

### 上下文
项目功能范围较大：本地媒体库、播放器、流媒体、Windows 系统集成。需要在 12 周内交付可用版本。

### 决策
采用 **分阶段 (Phased) 开发策略**，优先实现 **音频播放** 核心功能。

**阶段规划**:
| Phase | 重点 | 周期 |
|-------|------|------|
| 0 | 环境与脚手架 | 5 天 |
| 1 | 音频播放核心 | 6 天 |
| 2 | 媒体库扫描与管理 | 9 天 |
| 3 | 播放列表 | 5 天 |
| 4 | 流媒体 | 6 天 |
| 5 | Windows 系统集成 | 7 天 |
| 6 | 优化与打磨 | 8 天 |
| 7 | 测试与发布 | 7 天 |

### 理由
1. **降低风险**: 早期验证核心技术栈 (Flutter + just_audio + Riverpod)
2. **快速迭代**: 尽快有可用 MVP (Phase 1 结束即可播放本地音乐)
3. **用户价值**: 音频是媒体播放器的主要使用场景
4. **复用性**: 视频播放可复用音频播放器的状态管理和 UI 架构

### 依赖关系
```
Phase 1 (播放器) → Phase 2 (媒体库) → Phase 3 (播放列表)
                             ↓
Phase 4 (流媒体) → Phase 5 (Windows 集成) → Phase 6 (优化) → Phase 7 (发布)
```

---

## ADR-005: 音频引擎选择 media_kit

### 日期
2025-04-14 (原 just_audio)
**更新**: 2026-04-17

### 状态
✅ 已采纳 (2026-04-17 变更为 media_kit)

### 上下文
需要选择 Flutter 音频播放引擎，支持本地文件和流媒体播放，以及后台音频服务。
原计划使用 `just_audio`，但发现其不支持 Windows Desktop。

### 决策
**主播放引擎**: `media_kit`
**视频渲染**: `media_kit_video` + `media_kit_libs_video`

### 理由
| 功能 | media_kit | just_audio |
|------|-----------|------------|
| Windows Desktop | ✅ 原生支持 | ❌ MissingPluginException |
| 音视频合一 | ✅ | ❌ 需另选视频 |
| 流媒体支持 | ✅ | ✅ |
| 包体积 | 较大 (~50MB) | 较小 |
| 维护活跃度 | 活跃 | 活跃 |

**media_kit 优势**:
- 原生支持 Windows 7+
- 同时支持音频和视频
- 完整的解码器捆绑

### 已验证
- ✅ Windows Desktop 播放正常
- ✅ 进度条实时更新
- ✅ Pause/Play/Stop 控制正常
- ✅ 媒体库扫描集成正常

### 替代方案
- 未来可考虑 `just_audio` 如果增加 iOS/Android 支持需要

---

## ADR-005b: 音频引擎变更记录

### 2026-04-17 变更为 media_kit
- **原因**: `just_audio` 在 Windows 上抛出 `MissingPluginException`
- **修改**: pubspec.yaml 依赖 + PlayerRepositoryImpl
- **验证**: 所有播放功能正常

---

## ADR-007: 使用 ViewCollection + RegularWindow 实现多窗口架构

### 日期
2026-04-28

### 状态
✅ 已采纳

### 上下文
需要实现独立的迷你播放器窗口功能：
1. 迷你播放器作为独立窗口显示（512×512）
2. 打开迷你播放器时主窗口隐藏（不在任务栏显示）
3. 关闭迷你播放器时主窗口恢复显示
4. 系统托盘能控制窗口显隐
5. 所有窗口共享同一 Riverpod 状态容器（单引擎架构）

### 决策
采用 Flutter 实验性窗口 API + window_manager 实现：
- **ViewCollection**: 在单一引擎中管理多个视图
- **View widget**: 将内容映射到特定 FlutterView（用于主窗口）
- **RegularWindow + RegularWindowController**: 创建新的原生窗口（用于迷你播放器）
- **window_manager 包**: 控制原生窗口的真正隐藏/显示（不只是最小化）
- **全局 providerContainer + UncontrolledProviderScope**: 实现跨窗口 Riverpod 状态共享

### 架构

```
MultiWindowApp
├── ViewCollection
│   ├── View (view: default FlutterView)  ← 主窗口
│   │   └── UncontrolledProviderScope (container: providerContainer)
│   │       └── _MainWindowContent
│   │           ├── MaterialApp → _MainPageWithMiniPlayer
│   │           │   ├── NavigationRail + 页面内容
│   │           │   └── MiniPlayer (底部播放栏，90px)
│   │           └── 系统托盘回调 → LihaWindowManager
│   └── RegularWindow (迷你播放器窗口)
│       └── UncontrolledProviderScope (container: providerContainer)
│           └── MaterialApp → Scaffold → MiniPlayerView (512×512)
└── LihaWindowManager (窗口状态管理)
    ├── _isHidden: bool
    ├── hideMainWindow(): 帧回调延迟后隐藏原生窗口
    └── showMainWindow(): 帧回调延迟后显示原生窗口
```

### 关键实现

1. **避免双重窗口**: 主窗口不使用 `RegularWindow` 包装，而是用 `View` widget 将内容直接映射到默认 `FlutterView`。`RegularWindow` 只用于需要创建新原生窗口的迷你播放器。

2. **真正的窗口隐藏**: 使用 `window_manager.hide()` 而非 `setMinimized()`，前者完全隐藏窗口（任务栏也消失），后者只是最小化到任务栏。

3. **帧回调延迟**: 所有窗口显隐操作（`hide()`/`show()`/`destroy()`）都通过 `WidgetsBinding.instance.addPostFrameCallback` 延迟到当前帧绘制完成后执行，避免打断鼠标跟踪器（MouseTracker）状态导致断言失败。

4. **Riverpod 状态共享**: 在 `main.dart` 中创建全局 `providerContainer`，每个视图用 `UncontrolledProviderScope(container: providerContainer)` 包装，确保单引擎内所有窗口共享同一状态容器。

5. **迷你窗口 Directionality**: `RegularWindow` 的子组件用 `MaterialApp + Scaffold` 包裹，提供 Directionality 和 Material 主题，避免 `No Directionality widget found` 错误。

### 验证结果

| 功能 | 状态 |
|------|------|
| 启动时只有单一窗口 | ✅ |
| 打开迷你播放器主窗口隐藏 | ✅ |
| 关闭迷你播放器主窗口恢复 | ✅ |
| 系统托盘显隐按钮工作 | ✅ |
| 迷你窗口显示播放状态 | ✅ |
| 底部播放栏正常显示 | ✅ |
| 状态在窗口间同步 | ✅ |

### 依赖

```yaml
dependencies:
  window_manager: ^0.3.9
  flutter_riverpod: ^2.6.1
```

### 后果
**正面**:
- 单引擎多窗口，资源共享效率高
- 主窗口隐藏真正做到从任务栏消失
- Riverpod 状态在所有窗口间共享
- 架构清晰，职责分离明确

**负面**:
- 使用 Flutter 实验性 API，未来可能有 breaking changes
- 需要处理窗口间 Focus 切换
- 帧回调延迟增加少量复杂度

---

---

## ADR-006: 使用 build_runner + code generation

### 日期
2025-04-14

### 状态
✅ 已采纳

### 上下文
项目中多个依赖需要代码生成：
- Riverpod providers (`riverpod_generator`)
- JSON 序列化 (`json_serializable`)
- Freezed 数据类 (`freezed`)
- Hive TypeAdapters (`hive_generator`)

### 决策
统一使用 **build_runner** 作为代码生成工具，配合各个插件的生成器。

### 配置
```yaml
dev_dependencies:
  build_runner: ^2.4.7
  riverpod_generator: ^2.3.9
  freezed: ^2.4.5
  json_serializable: ^6.7.1
  hive_generator: ^1.1.0
```

### 生成命令
```bash
# 一次性生成所有
flutter pub run build_runner build

# 监控模式 (开发时)
flutter pub run build_runner watch

# 清理并重建
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### 后果
**正面**:
- 减少样板代码
- 类型安全
- 一致的代码风格

**负面**:
- 增加构建复杂度
- 需要 team 成员学习生成器用法
- 生成代码冲突需要手动解决

---

## 📊 ADR 索引

| ADR | 标题 | 状态 | 最后更新 |
|-----|------|------|----------|
| [ADR-001](./adr-001.md) | Feature-First + Clean Architecture | ✅ | 2025-04-14 |
| [ADR-002](./adr-002.md) | Riverpod 状态管理 | ✅ | 2025-04-14 |
| [ADR-003](./adr-003.md) | Hive 数据库 | ✅ | 2025-04-14 |
| [ADR-004](./adr-004.md) | 分阶段开发策略 | ✅ | 2025-04-14 |
| [ADR-005](./adr-005.md) | 音频引擎选择 (media_kit) | ✅ | 2026-04-17 |
| [ADR-006](./adr-006.md) | 代码生成策略 | ✅ | 2025-04-14 |
| ADR-007 | ViewCollection + RegularWindow 多窗口架构 | ✅ | 2026-04-28 |

---

## 🆘 如何添加新 ADR

1. 复制本模板创建新文件 `docs/adr-NNN.md`
2. 填写日期、状态、上下文、决策、理由、后果
3. 在 `architecture.md` 索引中添加条目
4. 提交 PR，团队成员评审

**状态标记**:
- ✅ 已采纳 (Adopted)
- ⚠️ 待验证 (Proposed)
- ❌ 已否决 (Rejected)
- 🔄 已取代 (Superseded)

---

**架构决策是团队共识。任何重大技术决策必须记录为 ADR！** 📐

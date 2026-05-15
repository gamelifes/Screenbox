# LihaPlayer AGENTS.md

## 项目概述

LihaPlayer 是一个产品开发与知识管理项目。核心原则：把任何重复 3 遍的事 AI 化或自动化。

---

## 项目结构约定

```
D:\LihaPlayer\
├── AGENTS.md                    # 项目规范文档（本文档）
├── DEVELOPMENT_PLAN.md          # 开发计划总览
├── task_plan.md                 # 任务计划追踪
├── findings.md                  # 研究发现/调研记录
├── progress.md                  # 进度报告
├── docs/                        # 文档目录
│   └── *.md                     # 按主题组织的文档
└── [其他项目文件]                # 根目录不放散乱文件
```

**规则：**

- 根目录只放管理性文件（AGENTS.md 及以上列出的文件）
- 散乱文件收拢到 `docs/` 或按功能创建目录
- 代码文件（如有）放在 `src/` 或语言特定目录

---

## 目录命名规范

| 类型      | 规范                     | 示例                                |
| --------- | ------------------------ | ----------------------------------- |
| 文档目录  | `docs/`                  | `docs/api/`, `docs/design/`         |
| 代码目录  | `src/`                   | `src/components/`, `src/utils/`     |
| 测试目录  | `tests/` 或 `__tests__/` | `tests/unit/`, `tests/integration/` |
| 配置目录  | `config/` 或 `configs/`  | `config/dev/`, `configs/`           |
| 临时/缓存 | `tmp/` 或 `.cache/`      | 构建产物不放此处                    |

**通用规则：**

- 目录名用英文单数或约定俗成的复数（如 `docs` 而非 `doc`）
- 临时目录以 `_` 前缀或 `.` 前缀标识（如 `_tmp/`, `.cache/`）
- 不允许中文目录名

---

## 文件命名规范

| 类型     | 规范                                | 示例                             |
| -------- | ----------------------------------- | -------------------------------- |
| 文档     | `kebab-case.md`                     | `api-design.md`, `user-guide.md` |
| 配置文件 | `kebab-case.json`                   | `package-config.json`            |
| 测试文件 | `*.test.js` 或 `*.spec.js`          | `parser.test.js`                 |
| 组件     | `PascalCase.vue` / `PascalCase.tsx` | `VideoPlayer.vue`                |

**通用规则：**

- 用 `-` 分隔单词，不使用 camelCase 或 snake_case
- 文档类文件用 `.md` 扩展名
- 不允许中文文件名

---

## 工作流程规范

### 任务追踪流程

```
1. 需求/任务发现 → 记录到 task_plan.md
2. 调研 → 记录到 findings.md
3. 执行 → 更新 progress.md
4. 完成 → 标记 task_plan.md 中任务状态
```

### 文件更新规则

- `task_plan.md` - 新任务立即添加，完成后标记 `done`
- `findings.md` - 调研结论随时记录，避免信息散落
- `progress.md` - 阶段性进度更新
- `DEVELOPMENT_PLAN.md` - 重大决策和计划变更才更新

### 根目录文件清理规则

- 根目录出现非规范文件，24 小时内归位或删除
- 临时文件（`*.tmp`, `*~`）立即清理

---

## Commit Message 规范

### 格式

```
<type>: <简短描述>

[可选正文]

[可选 footer]
```

### Type 分类

| Type       | 含义               | 示例                                   |
| ---------- | ------------------ | -------------------------------------- |
| `feat`     | 新功能             | `feat: add video codec support`        |
| `fix`      | 修复bug            | `fix: resolve playback lag on seeking` |
| `docs`     | 文档更新           | `docs: update DEVELOPMENT_PLAN`        |
| `refactor` | 重构（非功能变更） | `refactor: extract player core module` |
| `test`     | 测试相关           | `test: add unit tests for parser`      |
| `chore`    | 杂项/构建/工具     | `chore: update dependencies`           |
| `perf`     | 性能优化           | `perf: optimize buffer strategy`       |

### 规则

- Subject（简短描述）不超过 50 字符
- Subject 用英文小写开头，不加句号
- Body 解释 **why**，不解释 **what**（代码已说明）
- Breaking changes 在 footer 写 `BREAKING CHANGE:`

### 示例

```
feat: add support for mkv container format

Implement matroska demuxer to handle mkv files.
Fixes #12
```

---

## 开发习惯

- **验证优先**：改完主动跑测试/lint/build，不只改不验
- **根因思维**：不让报错通过注释消失，找根本原因
- **安全意识**：密钥/token/密码不进代码，用环境变量
- **用户体验**：技术决策需说明「为什么」和对用户的影响
- **技能更新迭代**： 解释同一条规矩超过 3 次，把这条规矩写成OpenCode Skill或者完善现有OpenCode Skill

---

---

## 开发约定

- 不能自动执行flutter clean，需要询问用户是否能执行

---

## Git 与部署

- `commit message` 用英文，简洁描述变更意图
- `git push` 仅用于跨设备同步，不自动执行
- 部署走项目自己的命令，不依赖 git push

---

## 规范修订

修订规范时：**先改本文档，再改实践**。不允许反过来。

## 长期记忆

本项目使用 gbrain 作为长期记忆库。

开始重要工作前，必须先读取：

1. overview.md - 了解项目当前状态
2. decisions.md - 了解已确定的技术决策
3. errors.md - 了解踩过的坑，避免重复
4. todo.md - 了解下一步任务

## 行为要求

- 开始编码前，先输出你对当前项目状态的理解。
- 不要重做已完成的模块，除非被明确要求。
- 发现重复出现的 bug，追加到 errors.md。
- 做了架构选择，追加到 decisions.md。
- 完成一个模块，更新 todo.md。
- 每次会话结束后，写 session 摘要到 sessions/YYYY-MM-DD.md。

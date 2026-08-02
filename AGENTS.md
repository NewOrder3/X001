# X001 工程规则

本文件约束所有对本仓库的代码与内容修改。详细说明见 `Docs/游戏程序相关/架构/Architecture.md`、`Docs/游戏程序相关/架构/CodingStandard.md`、`Docs/游戏程序相关/架构/DataDesign.md`、`Docs/游戏程序相关/架构/DataLoading.md` 与 `Docs/游戏程序相关/架构/CommandAndEvents.md`。

## 技术基线

- 引擎：Godot 4.x；当前工程使用 Compatibility Renderer。
- 语言：只使用 Typed GDScript。所有变量、参数、返回值及容器应在可行时显式标注类型。
- 游戏类型：纯单机 2D；不预建联网、账号、服务器、云同步或 ECS 等复杂抽象。
- 先使用 Godot 原生能力；新增第三方插件或架构框架须先获批准。

## 架构边界

- Data 保存 Definition 与运行时 State / Instance；System 执行规则；View / UI 只处理输入和表现。
- UI 和 View 不得直接修改 `GameState` 或实例状态。它们创建 Command 或调用公开 System 接口；System 校验并修改 State，再以 Signal 通知表现层。
- 纯规则优先使用 `RefCounted`，不得依赖场景树、`Node`、具体 UI 节点或渲染帧率。
- `GameState` 只存状态，不承载建造、生产、背包、战斗等业务规则。
- Definition、Instance、View 必须分离：静态定义可共享，存档只保存运行时状态，绝不保存 Node。
- 所有 Definition、存档引用、事件与任务使用 `StringName` 稳定 ID；格式、前缀和校验规则见 `DataDesign.md`，不得以显示文本或资源路径作为 ID。
- 不新增 Autoload，除非任务明确授权。玩法 System 由 `GameSession`（F05）持有；禁止创建万能 `*Manager`。
- 跨模块交互使用明确接口、Command 或领域 Signal；禁止通过节点路径或跨模块直接读写内部状态耦合。

## 目录职责

| 路径 | 放置内容 |
| --- | --- |
| `Src/Core/` | Session、State、Command、事件、输入、模拟、随机和调试等跨玩法基础。 |
| `Src/Data/` | Definition、ID 校验、注册与静态数据加载。 |
| `Src/<Feature>/` | 单个玩法模块的 State、System、纯规则与 View。 |
| `Scenes/` | 场景与节点组合；不得隐藏核心规则。 |
| `Data/` | 可版本控制的静态配置，文件名和稳定 ID 使用 `snake_case`。 |
| `Tests/Unit/` | 不依赖场景树的逻辑测试。 |
| `Tests/Integration/` | 多模块、存档或场景流程测试。 |
| `Tests/Fixtures/` | 可复用的最小测试数据。 |
| `Docs/游戏程序相关/架构/` | 架构、编码与数据设计的规范文档。 |

## 开发与验证

1. 先明确数据归属、规则 System、View 更新方式、存档影响与测试边界。
2. 修改规则或数据模型时，同时新增或更新相应单元测试；随机逻辑必须可注入固定 Seed。
3. 不混入无关重构，不改变其他模块公开接口，除非任务要求。
4. 提交前运行 `git diff --check`，并运行适用的自动测试。
5. 快速验证使用 `./Tools/verify_project.ps1 -GodotPath <Godot可执行文件>`；完整验证追加 `-Full`。

自动测试与统一验证脚本已在 F19 / F20 引入；涉及 Gameplay / Core / Data / Save 的改动必须使用 `./Tools/verify_project.ps1 -GodotPath <Godot可执行文件> -Full` 完成完整测试。

## 禁止事项

- 禁止 `Control`、`Button`、`Sprite2D` 等 View 节点直接写状态或实现核心玩法规则。
- 禁止 Gameplay System 直接读取具体触摸事件、UI 节点或硬编码场景路径。
- 禁止在 Gameplay 中直接调用全局随机 API；必须经未来的 `RandomService`（F10）或可注入的随机源。
- 禁止无分类 `print()`、静默吞掉错误、存档 Node，或将本机保存数据提交到仓库。

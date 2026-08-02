# X001 架构规范

本文定义《沧海余生》Godot 工程的模块边界与依赖方向。编码细则见 [CodingStandard.md](CodingStandard.md)，框架工作项见 `Docs/游戏程序相关/02-开发前框架准备方案.md`。

## 核心模型

```text
Definition（静态配置）
  → Instance / State（运行时、可存档状态）
  → System（规则与校验）
  → Command / Signal（请求与状态通知）
  → View / UI（输入与表现）
```

- **Definition**：物品、建筑、伙伴等静态内容；使用稳定 ID，可由多个实例共享。
- **Instance / State**：玩家本局或读档后的运行时状态；可序列化，不引用 `Node`。
- **System**：唯一执行规则与状态修改的位置；返回明确的成功/失败结果。
- **Command / Signal**：Command 表达请求；Signal 表达已经发生的领域变化。Signal 的发出不应要求接收方同步修改状态。
- **View / UI**：根据 State 或 Signal 重建/更新显示，并把用户意图转换为 Command；不是数据源。

## 依赖方向

```text
View / UI  →  Command / System  →  State / Instance  →  Definition
     ↑                 │
     └──── Signal ─────┘
```

允许 View 读取只读查询结果以显示内容，但不得写入状态。System 不得依赖具体场景、节点路径、按钮、相机或触摸事件。跨玩法模块的调用通过公开 System 接口、Command 或 Signal 完成，不能直接操作另一模块的内部容器。

## 生命周期与全局服务

- `GameSession`（F05）代表一次新游戏或读档运行，持有玩法 State 与玩法 System；切换场景时由 SceneRouter（F12）管理其保留或销毁。
- Autoload 仅适用于真正跨存档、全生命周期的基础服务。新增 Autoload 需显式批准；不得把每个玩法模块做成单例。
- View 以实例 ID 绑定，重新进入场景时从 Session/State 重建；View 销毁不应改变实例状态。

## 数据与存档

- Definition 与显示文本分离；稳定 ID 使用 `StringName`，文件名与 ID 使用 `snake_case`。具体格式与前缀见 [DataDesign.md](DataDesign.md)。
- 第一批 Definition 使用 JSON，具体目录与字段见 [DataLoading.md](DataLoading.md)。Gameplay 不得自行扫描配置目录或硬编码资源路径。
- SaveService（F11）仅序列化 State 和 Instance，并包含 `save_version`；存档迁移由明确版本步骤处理。

## 设计约束

- 模拟时间由 SimulationClock（F09）推进，不能依赖表现帧率。
- 随机行为经 RandomService（F10）按用途分流并支持固定 Seed。
- 原则上每个玩法 System 都应能脱离场景树构造和测试。
- 当一个功能无法回答“数据在哪里、规则归谁、View 如何更新、怎样保存和测试”时，不应开始实现。

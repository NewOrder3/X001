# 调试、Sandbox 与资源约定

开发调试命令必须经 System 接口修改 State。Sandbox 用于隔离验证，不能成为正式游戏逻辑的唯一入口；资源加载和允许 Group 清单见 `ResourceAndGroup.md`。

每个 Sandbox 根节点都必须带有 `sandbox_status` 与 `sandbox_next_stage` 元数据，并由 `Tools/validate_sandbox_status.gd` 检查。状态含义如下：

| 场景 | 当前状态 | 后续阶段 | 说明 |
| --- | --- | --- | --- |
| `GridSandbox.tscn` | `placeholder` | S1 | 等待最小等距网格、坐标显示与放置预览。 |
| `BuildingSandbox.tscn` | `placeholder` | S1 | 等待 BuildingSystem 和最小建造闭环。 |
| `HexMapSandbox.tscn` | `placeholder` | S4 | 等待 RegionDefinition、探索与地图 View。 |
| `BattleSandbox.tscn` | `placeholder` | S6 | 等待 BattleSystem 与最小战斗状态表现。 |
| `UISandbox.tscn` | `runnable_shell` | S2 | 可独立实例化 UIRoot，但尚未包含正式 HUD 或窗口内容。 |
| `DebugPanel.tscn` | `runnable_shell` | S1 | 可独立显示调试面板壳；绑定会话后的玩法命令随对应 System 实现。 |

新增 Sandbox 前先补充本表、根节点元数据及状态校验。状态从 `placeholder` 更新为可运行示例时，必须同时提供预设数据、可观察行为和对应验证。

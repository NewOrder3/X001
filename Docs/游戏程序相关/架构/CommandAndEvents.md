# X001 Command 与 Signal 规范

Command 是“请求执行规则”的参数对象；Signal 是“规则已修改状态”的事实通知。两者都不是 View 或 UI 的数据源。

## 命令流程

```text
UI / 输入 / 教程 / 自动化测试
  → 创建 Command
  → 对应 System.execute(...)
  → 完整校验
  → 原子修改 State
  → 返回 CommandResult
  → 发出领域 Signal
  → View 查询最新状态并更新表现
```

- UI、教程和测试可以创建 Command，但不知道 State 的内部字段。
- 只有对应 System 可以处理 Command。处理前必须完成校验；失败返回 `CommandResult.failure(...)`，不得产生部分状态修改。
- 成功返回 `CommandResult.success(...)`，然后发出表示已完成事实的 Signal。
- Command 是 `RefCounted` 参数对象，不能包含 `Node`、UI 引用、View 引用或对可变 State 的直接引用。

## 结果与 Signal payload

`CommandResult` 包含 `succeeded`、`error_code` 和面向诊断的 `message`。调用方通过结果处理成功或失败；不得依靠 Signal 是否发出来判断失败。

Signal 使用过去式 `snake_case` 名称，并只携带接收方更新表现所需的明确、稳定数据：

| Signal | 推荐 payload |
| --- | --- |
| `inventory_changed` | `item_id: StringName`、`new_amount: int` |
| `building_placed` | `instance_id: StringName`、`building_id: StringName`、`origin: Vector2i` |
| `battle_started` | `battle_id: StringName` |
| `new_game_created` | `world_seed: int` |

不在 Signal payload 中传递 `Node`、`Control`、完整 `GameState`、可变 Dictionary 或隐式上下文。View 收到 Signal 后通过公开查询接口读取必要状态。

## 当前演示闭环

`CreateNewGameCommand`、`PlaceBuildingCommand`、`GatherResourcesCommand`、`UseFoodCommand` 与 `SetProductionEnabledCommand` 均由 `SessionCommandSystem` 处理。它调用 `GameSession` 的公开规则入口并返回原始 `CommandResult`；任一失败都会通过 `SessionEvents.command_rejected(command_type, error_code)` 通知表现层。`new_game_created(world_seed)` 仅在新会话创建成功后发出。

`SessionEvents` 由 `SessionCommandSystem` 持有或注入，不能注册为 Autoload。未来每个玩法 System 应拥有或接收自己所属的事件对象，避免万能全局事件总线。

验证命令：

```powershell
godot --headless --path . --script res://Tools/validate_command_flow.gd
```

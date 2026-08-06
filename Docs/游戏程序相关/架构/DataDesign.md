# X001 数据与稳定 ID 规范

本规范适用于 Definition、存档引用、事件、任务及跨模块运行时引用。它解决“显示名称可变、引用不变”的问题；接口实现见 `Src/Data/IdValidator.gd`。

## ID 格式

- ID 使用 `StringName`，格式为 `<prefix>_<name>`，至少两个段落。
- 仅允许小写 ASCII 字母、数字和单个下划线；每个段落必须以小写字母开头。
- 文件名与 ID 均使用 `snake_case`，但文件路径不是 ID，也不得从显示名称推导 ID。
- 创建后稳定 ID 不可随显示文案、翻译、资源位置或数值调整而改变。确需替换时，必须在 F11 存档迁移中明确处理旧 ID。

以下示例有效：`item_wood`、`building_rain_collector`、`survivor_lao_chen`、`boss_giant_squid`、`item_wood_01`。

以下示例无效：`Wood`、`item-wood`、`item__wood`、`item_01`、`weapon_spear`。

## 已注册前缀

| 前缀 | 用途 | 示例 |
| --- | --- | --- |
| `item` | 可堆叠物品与材料 | `item_wood` |
| `building` | 建筑 Definition | `building_rain_collector` |
| `recipe` | 制作配方 | `recipe_plank` |
| `survivor` | 伙伴/幸存者 Definition | `survivor_lao_chen` |
| `skill` | 技能 Definition | `skill_anchor_strike` |
| `boss` | Boss Definition | `boss_giant_squid` |
| `reward` | 战斗奖励 Definition | `reward_tutorial_cache` |
| `region` | 海域/区域 Definition | `region_shallow_sea` |
| `event` | 事件 Definition | `event_storm_warning` |
| `quest` | 任务 Definition | `quest_first_sail` |
| `unlock` | 解锁规则 ID（非 Definition） | `unlock_exploration` |
| `progression` | 解锁与进度节点 | `progression_building_tier_one` |
| `survival` | 生存规则配置 Definition | `survival_default` |
| `recipe` | 生产配方 Definition | `recipe_grill_fish` |

新增前缀必须同时修改本表和 `IdValidator.ALLOWED_PREFIXES`，并说明对应的 Definition / State 归属。

## Definition、实例与显示文本

- 每份 Definition 都有唯一稳定 `id`；不同类型也不得复用相同完整 ID。
- Instance / State 仅保存对 Definition 的 `id` 与自身运行时字段，不能复制显示名或持有 View。
- 面向用户的名称、描述、图标和本地化文本属于 Definition / View 数据，可自由调整，不参与存档主键或逻辑判断。

### 字段归属

| 归属 | 允许字段 | 不允许字段 |
| --- | --- | --- |
| Definition | 稳定 `id`、显示文本、图标路径、静态规格（例如建筑 footprint） | 玩家等级、放置位置、Node、场景内引用 |
| Instance / State | 实例 ID、Definition ID、位置、等级、分配等运行时且可存档字段 | `Node`、`Control`、`Sprite2D`、从 Definition 复制的显示文本 |
| View | 绑定的实例 ID、临时动画/选中/节点引用等可重建表现数据 | 权威运行时状态、存档数据、直接写入 State 的逻辑 |

`BuildingDefinition` 可以对应多个 `BuildingInstance`。View 的最低契约是接收实例 ID、通过 Session / System 查询状态并监听领域 Signal；重建或销毁 View 不得改变 Instance。具体 `BuildingView` 实现与解绑规则在 F17 完成。

## 校验与加载

`IdValidator` 提供：

```gdscript
IdValidator.is_valid_id(id: StringName) -> bool
IdValidator.get_validation_error(id: StringName) -> String
IdValidator.find_duplicate_ids(ids: Array[StringName]) -> Array[StringName]
```

F07 的 `DataRegistry.load_all()` 必须在注册每份 Definition 时调用这些校验：非法 ID 或重复 ID 必须让加载明确失败，并报告 ID 与来源；Gameplay System 只通过 Registry 查询 Definition，不能自行扫描文件路径。

在 Definition 格式确定前，可用命令行检查任意 ID 列表：

```powershell
godot --headless --path . --script res://Tools/validate_ids.gd -- item_wood building_rain_collector
```

退出码 `0` 表示全部有效且不重复；`1` 表示非法或重复 ID；`2` 表示未提供待检查 ID。

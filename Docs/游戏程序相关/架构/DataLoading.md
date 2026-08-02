# X001 Definition 数据加载规范

## 当前格式：JSON

F07 选择 JSON 作为第一批 Definition 格式。它便于版本审查、fixture 编写和后续内容编辑；静态 Definition 由 `DataRegistry` 统一加载，Gameplay System 不得读取文件或硬编码 `res://Data/...` 路径。

| Definition | 目录 | 最小字段 |
| --- | --- | --- |
| Item | `Data/Items/` | `id`、`display_name`、`description` |
| Building | `Data/Buildings/` | `id`、`display_name`、`description`、`footprint_width`、`footprint_height` |

每个文件是一个 JSON 对象，文件名使用 `snake_case`。ID 规则见 [DataDesign.md](DataDesign.md)。例如：

```json
{
  "id": "item_wood",
  "display_name": "Wood",
  "description": "A basic building material."
}
```

## 注册与查询

`DataRegistry` 是静态数据目录的唯一入口：

```gdscript
DataRegistry.load_all() -> bool
DataRegistry.get_item(id: StringName) -> ItemDefinition
DataRegistry.get_building(id: StringName) -> BuildingDefinition
DataRegistry.has_definition(id: StringName) -> bool
```

加载按稳定文件名排序，确保错误结果可复现。加载期间会验证 JSON 结构、必需字段、ID 格式和跨类型重复 ID；任一步失败都会返回 `false`，并可通过 `get_last_error()` 获得包含文件与字段的错误，且不会保留部分已注册的数据。未知的 `get_item` / `get_building` 查询会输出 `DATA` 分类错误并返回 `null`。

当前可用的最小加载检查：

```powershell
godot --headless --path . --script res://Tools/validate_data_registry.gd
```

F19 后将以 fixture 和自动化测试覆盖成功、未知 ID、重复 ID 和非法 JSON；F20 后由统一验证命令调用该检查。

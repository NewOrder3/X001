# X001 GDScript 编码规范

## 类型与接口

- 使用 Typed GDScript。局部变量、成员变量、函数参数、返回值和集合元素在可表达时必须标注类型。
- 公共方法必须声明返回类型，并为失败情况提供可判断的结果或错误信息；不得部分修改状态后再失败。
- `StringName` 用于稳定 ID；`String` 用于面向用户的文本或非稳定文本。
- 纯数据与规则类优先继承 `RefCounted`；只有需要生命周期、信号连接、输入或渲染时才继承 `Node`。

```gdscript
class_name InventorySystem
extends RefCounted

func can_add(item_id: StringName, amount: int) -> bool:
	return amount > 0 and item_id != &""
```

## 命名与文件

- 类、场景、脚本文件使用 `PascalCase` 或现有目录风格时须保持一致；当前场景/脚本按 `PascalCase` 命名。
- 方法、变量、信号、资源 ID 和数据文件使用 `snake_case`。
- 信号以已经发生的领域事件命名，例如 `inventory_changed`、`building_placed`；payload 使用明确类型或命名字段。
- 一个脚本只承担一个清晰职责。不要创建 `GameManager`、`DataManager` 等职责无限扩张的类。

## 状态修改与错误处理

- System 在写入 State 前先完成全部校验；失败时不留下部分修改。
- UI 仅创建 Command 或调用 System 的公开入口，禁止 `state.inventory[...] = ...` 这类直接写入。
- 开发期使用断言或将来 `GameLogger`（F18）输出带分类的错误；不要散落无分类 `print()`。
- 不吞掉数据加载、存档、非法 ID 或非法操作的错误。调用方必须能得到可诊断的失败原因。

## 测试

- 为新增或改变的规则、数据校验、坐标转换、随机和存档行为增加单元测试。
- 测试名称描述可观察行为，例如 `test_can_not_place_on_occupied_cell`。
- 测试固定输入、固定 Seed 和最小 fixture，不依赖运行顺序、真实时间或编辑器状态。
- UI 布局、动画、粒子与 Shader 不强制单元测试；其绑定逻辑和关键流程应有集成或手动验证记录。

## 最低验证

每次代码修改至少运行：

```powershell
git diff --check
godot --headless --path . --editor --quit
```

修改启动流程时追加运行：

```powershell
godot --headless --path . --quit
```

涉及 Gameplay / Core / Data / Save 的改动必须运行相关测试；以 `Tools/verify_project.ps1 -Full` 作为完整检查入口。测试由仓库内置的 `Tools/run_tests.gd` 运行，不依赖编辑器插件或本机缓存。

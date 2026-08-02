# X001 / OceanHome

Godot 4.x 单机 2D 游戏工程。

## 启动

1. 安装与 `project.godot` 兼容的 Godot 4.7（Compatibility / OpenGL）版本。
2. 在 Godot 项目管理器中导入本目录，或从仓库根目录运行：

   ```powershell
   godot --editor --path .
   ```

3. 运行项目。入口场景为 `Scenes/Bootstrap/Bootstrap.tscn`。

项目以 1920×1080 为设计分辨率，使用 `canvas_items` 与 `expand` 拉伸策略。最小输入动作：`confirm`（Enter）、`cancel`（Esc）、`open_debug`（F3）。

## 基础验证

在仓库根目录运行以下命令，确认项目可由无图形环境加载并正常退出：

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --quit
```

完整自动化验证命令将在 F20 阶段统一提供。

## Git 约定

- 不提交 `.godot/`、导出产物、用户存档或本机 IDE 设置；规则见 `.gitignore`。
- 一项独立变更使用一个目的明确的提交；提交信息使用简短祈使语气，例如 `Add bootstrap scene`。
- 新功能分支使用 `codex/<topic>` 前缀；直接在主分支工作的变更须先经过确认。
- 提交前至少运行基础验证，并使用 `git diff --check` 检查空白错误。

# 调试、Sandbox 与资源约定

开发调试命令必须经 System 接口修改 State。`GridSandbox.tscn` 与 `HexMapSandbox.tscn` 可独立启动，作为可视化验证入口而非正式逻辑唯一入口。资源加载和允许 Group 清单见 `ResourceAndGroup.md`。

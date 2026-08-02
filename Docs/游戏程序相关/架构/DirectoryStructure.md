# X001 项目目录结构

本文件定义工程目录的职责与放置规则。空目录中的 `.gitkeep` 仅用于 Git 追踪，首次加入实际内容后可删除。

```text
X001/
├── Assets/                 # 美术、音频、字体及其他原始资源
├── Data/                   # 可版本控制的静态 Definition JSON
│   ├── Items/ Buildings/ Recipes/ Survivors/ Skills/
│   └── Bosses/ Regions/ Events/ Progression/
├── Docs/
│   ├── 游戏程序相关/         # 技术方案与架构规范
│   └── 游戏设计相关/         # 立项、玩法与内容设计
├── Scenes/
│   ├── Bootstrap/           # 持久启动根与 SceneRouter
│   ├── Game/                # 主菜单与主游戏场景
│   ├── UI/                  # UIRoot 和可复用 UI 场景
│   ├── Dev/                 # DebugPanel 与各模块 Sandbox
│   └── Battle/              # 战斗场景
├── Src/
│   ├── Core/                # Session、State、Command、事件、输入、时间、随机、调试
│   ├── Data/                # Definition 类型、ID 校验、加载和 Registry
│   ├── Save/                # 存档、备份与迁移
│   ├── SceneFlow/           # 场景流程与转场
│   ├── UI/                  # UI 控制器、设置与响应式布局
│   ├── Raft/ WorldMap/      # 两套独立空间坐标与状态规则
│   ├── Building/ Inventory/ Survivor/ Battle/
│   │                         # 各玩法模块的 State、System、View
│   ├── Performance/         # 画质档位与性能指标
│   └── Shared/              # 明确跨模块复用的基础设施
├── Tests/
│   ├── Unit/                # 不依赖场景树的规则测试
│   ├── Integration/         # 多模块、存档、场景流程测试
│   └── Fixtures/            # 测试专用最小数据
└── Tools/                   # 可从命令行调用的验证与开发工具
```

## 使用规则

- `Data/` 只放静态 Definition；运行时实例和玩家状态放入 `Src/` 的 State / Instance 类，并由 SaveService 保存。
- `Scenes/` 只组织节点与表现，不隐藏玩法规则；规则应放进对应的 `Src/<模块>/` System 或纯逻辑类。
- `Assets/` 不作为静态玩法配置来源；Definition 使用稳定 ID 引用资源，而不是反向依赖场景节点。
- 新模块首先在 `Src/` 建立规则边界；仅在需要可视化验证时增加 `Scenes/Dev/` Sandbox 与对应测试。

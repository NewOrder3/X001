# View 生命周期约定

View 只保存绑定的实例 ID 与可重建表现状态。创建时通过 `bind_instance(instance_id)` 绑定，销毁前调用 `unbind()` 断开监听；删除 Instance 后 View 必须解除绑定。场景重建时由 Factory 创建 View，再从 Session 查询同一实例 ID。逻辑测试禁止依赖 View。

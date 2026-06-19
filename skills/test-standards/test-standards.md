---
description: 针对功能模块辅助编写测试验收标准，使用 Given/When/Then 格式系统化定义测试规范。
---

针对功能模块辅助编写测试验收标准。先分析需求，再系统化生成验收标准文档。

## 执行步骤

1. **理解功能需求** — 分析用户提供的功能描述、相关源代码或设计文档，明确：
   - 模块的核心职责和对外接口
   - 输入/输出的数据类型和约束
   - 与其他模块的依赖关系
   - 已知的约束条件或非功能性需求

2. **识别测试维度** — 按以下清单逐一评估，标记适用的维度：

   | 维度             | 说明                                        | 适用性判断                   |
   | ---------------- | ------------------------------------------- | ---------------------------- |
   | ✅ 正常流程      | 主路径（Happy Path）的预期行为              | **始终适用**                 |
   | ✅ 异常/错误处理 | 无效输入、超时、网络中断、依赖服务故障等    | **始终适用**                 |
   | ✅ 边界条件      | 空值、零值、极大/极小值、空数组、空字符串等 | **始终适用**                 |
   | ⬜ 状态转换      | 模块内部状态机的转换路径和非法转换          | 有状态管理时适用             |
   | ⬜ 并发/异步     | 竞态条件、Promise 并发、事件顺序依赖        | 有异步操作时适用             |
   | ⬜ 幂等性        | 重复调用是否产生相同结果                    | 有写操作或副作用时适用       |
   | ⬜ 类型安全      | TypeScript 类型约束在运行时的正确性         | 涉及复杂泛型或类型守卫时适用 |
   | ⬜ 集成点        | 与外部服务、数据库、文件系统的交互          | 有外部依赖时适用             |
   | ⬜ 配置/参数化   | 不同配置组合下的行为差异                    | 有可配置选项时适用           |
   | ⬜ 性能/资源     | 响应时间、内存占用、连接泄漏等              | 有性能需求时适用             |

3. **编写验收标准** — 对每个适用的测试维度，使用 Given/When/Then 格式编写验收标准：

   ```markdown
   ### [维度名称]: [场景简述]

   **Given** [前置条件 — 系统初始状态或上下文]
   **When** [触发动作 — 用户行为或系统事件]
   **Then** [预期结果 — 可验证的输出或状态变化]
   ```

   编写规则：
   - 每条标准只覆盖一个场景，不混合多个断言意图
   - 使用具体的示例值而非抽象描述（如 `userId: "user-123"` 而非"一个有效的用户 ID"）
   - 明确失败场景的预期行为（抛出特定错误？返回 null？触发回调？）
   - 对枚举型输入，穷举所有有效值

   **示例** — 以一个 `SessionManager` 模块为例，展示不同维度下验收标准的写法：

   ```markdown
   ### 1. 正常流程

   #### 1.1 创建会话

   **Given** 已实例化的 SessionManager，配置为 `{ maxSessions: 10 }`
   **When** 调用 `create({ userId: "user-123", timeout: 5000 })`
   **Then**

   - 返回 Session 对象，包含非空的 `sessionId`（格式为 UUID）
   - `session.status` 为 `"active"`
   - `session.userId` 为 `"user-123"`
   - `manager.activeSessions` 计数增加 1

   #### 1.2 销毁已有会话

   **Given** 已存在一个 `status: "active"` 的会话 `session-abc`
   **When** 调用 `destroy("session-abc")`
   **Then**

   - 返回 `true`
   - `manager.activeSessions` 计数减少 1
   - 再次调用 `get("session-abc")` 返回 `undefined`

   ---

   ### 2. 异常/错误处理

   #### 2.1 创建会话时缺少必填字段

   **Given** 已实例化的 SessionManager
   **When** 调用 `create({ timeout: 5000 })`（缺少 `userId`）
   **Then** 抛出 `ValidationError`，message 包含 `"userId is required"`

   #### 2.2 销毁不存在的会话

   **Given** 不存在 ID 为 `"non-existent"` 的会话
   **When** 调用 `destroy("non-existent")`
   **Then** 抛出 `SessionNotFoundError`，message 包含 `"non-existent"`

   ---

   ### 3. 边界条件

   #### 3.1 达到最大会话数限制

   **Given** 已实例化的 SessionManager，配置 `{ maxSessions: 2 }`，且已有 2 个活跃会话
   **When** 调用 `create({ userId: "user-999", timeout: 3000 })`
   **Then** 抛出 `CapacityError`，message 包含 `"max sessions reached"`

   #### 3.2 超时值为 0

   **Given** 已实例化的 SessionManager
   **When** 调用 `create({ userId: "user-123", timeout: 0 })`
   **Then** 创建的会话立即进入 `"expired"` 状态

   ---

   ### 4. 状态转换

   #### 4.1 会话从 active 到 suspended

   **Given** 一个 `status: "active"` 的会话 `session-abc`
   **When** 调用 `suspend("session-abc")`
   **Then**

   - `session.status` 变为 `"suspended"`
   - 触发 `onStatusChange` 回调，参数为 `{ from: "active", to: "suspended" }`

   #### 4.2 禁止从 expired 恢复

   **Given** 一个 `status: "expired"` 的会话 `session-abc`
   **When** 调用 `resume("session-abc")`
   **Then** 抛出 `InvalidTransitionError`，message 包含 `"cannot resume from expired"`

   ---

   ### 5. 并发/异步

   #### 5.1 并发创建不产生重复 ID

   **Given** 已实例化的 SessionManager
   **When** 同时并发调用 `create()` 10 次
   **Then** 所有返回的 `sessionId` 两两不相同，`activeSessions` 计数为 10
   ```

4. **补充实现提示** — 为每条验收标准附加简要的 Vitest 实现提示，帮助后续编写测试代码时快速定位：
   - 建议的 `describe` / `it` 描述文本
   - 可能需要的 mock 对象或测试工具（如 `vi.fn()`、`vi.useFakeTimers()` 等）
   - 需要关注的断言方式（如 `toThrow`、`resolves`、`toHaveBeenCalledWith` 等）

5. **确认输出** — 向用户展示验收标准文档，包含覆盖的测试维度总结和未覆盖维度的说明。等待用户确认或调整后再写入文件。

## 输出规范

### 验收标准文档

输出一份 Markdown 文档，结构如下：

```markdown
# [模块名] 测试验收标准

## 概述

- **被测模块**: [模块路径]
- **核心职责**: [一句话描述]
- **测试维度**: [已覆盖维度列表]

## 验收标准

### 1. 正常流程

#### 1.1 [场景名称]

**Given** ...
**When** ...
**Then** ...

### 2. 异常/错误处理

#### 2.1 [场景名称]

**Given** ...
**When** ...
**Then** ...

<!-- 按适用维度继续 -->
```

## 注意事项

- 验收标准优先关注行为和意图，而非实现细节
- 避免把实现细节写入 Given 条件（如"Given 调用了私有方法 \_init"是错误的）
- 如果用户提供了已有的测试文件，先分析已有覆盖范围，仅补充缺失的部分
- 实现提示只做方向性指引，不输出完整测试代码

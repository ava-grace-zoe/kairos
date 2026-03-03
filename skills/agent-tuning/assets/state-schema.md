# 调优状态 Schema

CodeAgent 在 `$TMPDIR/agent-tuning-<YYYYMMDD-HHMMSS>/state.json` 中维护此文件，每轮更新。

## Schema

```json
{
  "startedAt": "2026-03-03T10:00:00Z",
  "currentRound": 2,
  "maxRounds": 5,
  "failureBudget": 2,
  "failureBudgetUsed": 0,
  "promptChannel": "local",
  "traceChannel": "remote",
  "baselinePromptVersion": null,

  "probeResult": {
    "entryFile": "src/agent.ts",
    "entryExport": "weatherAgent",
    "invocation": "weatherAgent.generate({ prompt })",
    "orchestration": "ToolLoopAgent",
    "prompt": {
      "type": "variable_ref",
      "chain": ["src/agent.ts:19 → SYSTEM_PROMPT", "src/config.ts:1 → 定义"],
      "editTarget": "src/config.ts:1",
      "langfusePromptName": null
    },
    "tools": [
      { "name": "getWeather", "descriptionLocation": "src/agent.ts:21", "inline": true },
      { "name": "compareWeather", "descriptionLocation": "src/agent.ts:33", "inline": true }
    ],
    "fewShot": {
      "exists": false,
      "location": null,
      "form": null
    },
    "readiness": {
      "telemetry": true,
      "otelInit": true,
      "langfuseEnv": true,
      "testScript": true,
      "testJsonOutput": true
    }
  },

  "rounds": [
    {
      "round": 1,
      "traceIds": ["abc123..."],
      "localTraceFile": null,
      "tests": [
        { "name": "单城市查询应调用 getWeather", "pass": true, "reason": "正确调用工具并返回温度" },
        { "name": "多城市比较应调用 compareWeather", "pass": true, "reason": "正确使用 compareWeather 工具" },
        { "name": "不支持的城市应优雅处理", "pass": false, "reason": "未列出可查询的城市列表" }
      ],
      "defects": [
        {
          "description": "不支持的城市查询时未列出可用城市",
          "evidence": "轨迹中 getWeather 返回错误后，模型直接告知不可用但未提供替代方案",
          "traceLocation": "step 2, model response"
        }
      ],
      "introspection": {
        "input": "（填入 MetaAdvisor 的轨迹摘要 + 缺陷描述）",
        "output": "（MetaAdvisor 的回答）",
        "agreement": "same_target"
      },
      "modification": {
        "type": "system_prompt",
        "target": "config.ts → SYSTEM_PROMPT",
        "description": "在系统指令中增加一段：当查询城市不在数据库中时，应列出所有支持的城市",
        "promptVersion": null,
        "snapshotPath": "snapshots/round-01/"
      },
      "result": "partial_improvement"
    }
  ],

  "bestRound": 1,
  "terminationReason": null
}
```

## 字段说明

### 顶层字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `startedAt` | string | 调优开始时间（ISO 8601） |
| `currentRound` | number | 当前轮次（从 1 开始） |
| `maxRounds` | number | 最大轮次上限 |
| `failureBudget` | number | 初始失败预算 |
| `failureBudgetUsed` | number | 已消耗的失败预算次数 |
| `promptChannel` | `"remote"` \| `"local"` | Prompt 通道 |
| `traceChannel` | `"remote"` \| `"local"` | 轨迹通道 |
| `baselinePromptVersion` | number \| null | Remote Prompt 的初始 version 号（Local 时为 null） |
| `probeResult` | object | 项目探查报告（结构详见 `assets/project-probe.md` 的"输出探查报告"部分） |
| `bestRound` | number | 目前表现最好的轮次编号 |
| `terminationReason` | string \| null | 终止原因（未终止时为 null） |

### `rounds[].tests[]`

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | string | 测试用例名称 |
| `pass` | boolean | 是否通过 |
| `reason` | string | 通过/失败的原因 |

### `rounds[].introspection.agreement`

| 值 | 含义 |
|----|------|
| `same_target` | CodeAgent 和 MetaAdvisor 指向同一修改点 |
| `different_chose_code` | 指向不同点，选择了 CodeAgent 的分析 |
| `different_chose_meta` | 指向不同点，选择了 MetaAdvisor 的建议 |

### `rounds[].modification.type`

| 值 | 含义 |
|----|------|
| `system_prompt` | 修改系统提示词 |
| `tool_description` | 修改工具描述 |
| `few_shot` | 增删改 few-shot 示例 |
| `coupled_change` | 耦合修改包（逃逸机制） |

### `rounds[].result`

| 值 | 含义 |
|----|------|
| `improvement` | 有测试从 fail 变为 pass，无回归 |
| `partial_improvement` | 部分改善但仍有失败 |
| `no_change` | 测试结果无变化 |
| `regression` | 之前 pass 的测试变为 fail |

### `terminationReason`

| 值 | 含义 |
|----|------|
| `all_tests_passed` | 全部测试通过 |
| `max_rounds_reached` | 达到最大轮次 |
| `convergence_stall` | 收敛停滞（连续 2 轮 no_change） |
| `oscillation` | 震荡检测触发 |
| `budget_exhausted` | 失败预算耗尽 |

## 回归检测算法

```
对比 round N 和 round N-1 的 tests 数组：
  对每个测试用例 t：
    if t.pass(N-1) == true AND t.pass(N) == false:
      → 回归（regression）
```

## 震荡检测算法

```
对每个测试用例 t，检查最近 3 轮的 pass 序列：
  if 序列为 [true, false, true] 或 [false, true, false]:
    → 震荡（oscillation）
```

## 收敛停滞检测

```
对比 round N 和 round N-1 的 tests 数组：
  if 所有测试用例的 pass 值完全相同:
    stall_count += 1
  else:
    stall_count = 0
  if stall_count >= 2:
    → 收敛停滞（convergence_stall）
```

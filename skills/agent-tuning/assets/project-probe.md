# Agent 项目探查指南

CodeAgent 在初始化阶段使用本指南，系统化地探查目标 Agent 项目的结构，理解编排方式，定位所有可修改的配置点。

> 本指南适用于任意结构的 AI SDK 项目——无论 prompt 是否已分离、工具是否集中定义。

## 探查目标

探查完成后，你应该能回答以下问题：

1. **调用入口**：TargetAgent 的入口函数在哪个文件？怎么调用它？
2. **Prompt 位置**：系统提示词在哪里定义？是内联字符串、独立变量、外部文件，还是 Langfuse Remote？
3. **工具清单**：注册了哪些工具？每个工具的 description 和参数说明在哪里？
4. **Few-shot 位置**：有没有示例？在 prompt 内联还是独立数据结构？
5. **编排方式**：是单步 `generateText` 还是 `ToolLoopAgent`/自定义循环？有无多 Agent 编排？
6. **OTel 配置**：`experimental_telemetry` 是否已开启？`@langfuse/otel` 是否已初始化？
7. **测试入口**：有没有现成的测试脚本？怎么跑？输出格式是什么？

## 探查步骤

### Step 1: 定位模型调用入口

按优先级搜索，命中一个即可：

```
1. 用户明确指定的入口文件
2. 搜索 ToolLoopAgent / generateText / streamText 的 import 或调用
3. 搜索 @ai-sdk/ 相关 provider 的 import（openai / anthropic / google 等）
4. 搜索 "system" + "prompt" / "instructions" 关键词组合
```

产出：记录入口文件路径和导出的 agent 对象/函数名。

### Step 2: 追踪 Prompt 来源

从入口文件中的 `system` / `instructions` 参数出发，追踪其值的来源：

| 模式 | 特征 | 可修改点 |
|------|------|---------|
| **内联字符串** | `system: "你是一个..."` 直接写在调用处 | 调用处的字符串字面量 |
| **变量引用** | `system: SYSTEM_PROMPT` 引用本文件或 import 的变量 | 变量定义处 |
| **文件读取** | `readFileSync("prompts/system.md")` | 对应的外部文件 |
| **模板拼接** | `` system: `${BASE}${RULES}${EXAMPLES}` `` 多段拼接 | 各段的定义处（注意拼接顺序） |
| **Langfuse Remote** | `langfuse.prompt.get("name")` | Langfuse Prompt Management |
| **配置对象** | `config.agent.systemPrompt` 从配置对象读取 | 配置对象的定义/加载处 |

> 重点：不要只看第一层引用。如果 `SYSTEM_PROMPT` 是从另一个文件 import 的，追踪到最终的字面量定义处。

产出：记录 prompt 的完整来源链路，标注最终可修改的文件和行号。

### Step 3: 枚举工具定义

找到入口文件中的 `tools` 参数，枚举所有注册的工具：

```
对每个工具，记录：
- 工具名
- description 的位置（内联字符串 / 外部引用）
- inputSchema 中每个参数的 description（如有）
- execute 函数的位置
```

工具描述的常见模式：
- `description: "获取天气"` → 内联，直接可改
- `description: TOOL_DESCRIPTIONS.getWeather` → 追踪到定义处
- 工具从外部模块导入（`import { weatherTools } from "./tools"`）→ 进入该模块查看

产出：工具清单表，含每个工具的 description 位置。

### Step 4: 查找 Few-shot 示例

Few-shot 可能以多种形态存在：

| 形态 | 特征 |
|------|------|
| Prompt 内联 | 系统提示词中包含 `## 示例` / `Example:` / `<example>` 等标记 |
| 独立数组 | `const examples = [{ input: "...", output: "..." }]` |
| messages 预填充 | `messages: [{ role: "user", content: "..." }, { role: "assistant", content: "..." }, ...]` |
| 外部文件 | `examples.json` / `examples.yaml` |
| 无 few-shot | 以上均未找到 |

产出：记录 few-shot 的存在形态和位置。如果没有 few-shot，记录「无 few-shot，后续可新增」。

### Step 5: 理解编排方式

确定 TargetAgent 的编排复杂度：

| 编排类型 | 特征 | 对调优的影响 |
|---------|------|-------------|
| **单步调用** | 一个 `generateText()` / `streamText()` | 最简单，直接调优这一个调用的配置 |
| **ToolLoopAgent** | `new ToolLoopAgent({ ... })` | 等价于带自动循环的 generateText，调优 instructions 和 tools |
| **手动循环** | while/for 循环中反复调用 generateText | 需理解循环逻辑，确定每步的 prompt 组装方式 |
| **多 Agent** | 多个 agent 协作（router → specialist 等） | 需确认调优目标是哪个 agent，其他 agent 的配置是否固定 |
| **Pipeline** | 串行的多个 generateText，前一步输出作后一步输入 | 需确认调优目标是哪一步 |

产出：记录编排类型，以及对调优范围的影响。

### Step 6: 检查基础设施就绪度

逐项检查：

```
□ experimental_telemetry: { isEnabled: true } — 是否在模型调用中开启
□ @langfuse/otel LangfuseSpanProcessor — 是否已初始化
□ LANGFUSE_PUBLIC_KEY / LANGFUSE_SECRET_KEY — 环境变量是否存在
□ 测试脚本 — 是否存在可运行的测试入口
□ 测试输出 — 是否支持 --json 结构化输出（含 traceId）
```

未就绪项不阻塞探查，在探查报告中标注，后续由 CodeAgent 在初始化阶段补齐。

### Step 7: 输出探查报告

将以上发现整理为结构化报告，写入 `state.json` 的 `probeResult` 字段：

```json
{
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
  }
}
```

## 探查中的常见情况处理

### Prompt 内联在调用处

不需要预先分离。CodeAgent 可以直接修改内联字符串。但如果内联 prompt 超过 20 行，建议先提取到变量（同文件即可），降低修改时出错的风险。

### 工具描述过于简略

如 `description: "获取天气"`，这本身可能就是需要调优的配置点之一。在探查阶段只需记录位置，不做修改。

### 多 Agent 编排中的调优边界

如果项目包含多个 Agent，探查时需和用户确认调优目标。未被选为调优目标的 Agent 配置视为固定常量。

### 动态生成的 Prompt

如果 prompt 是运行时动态拼接的（如根据用户角色切换不同指令段），记录拼接逻辑和所有可能的模板片段，后续修改时需考虑所有分支。

### 项目使用了非 AI SDK 框架

agent-tuning 要求 AI SDK 项目。如果发现项目使用 LangChain / LlamaIndex / 自定义 HTTP 调用等，在探查报告中标注不兼容，终止流程。

## 探查后生成 Manifest（可选）

探查完成后，询问用户是否将探查结果持久化为 `.agent-tuning/manifest.md`。生成 manifest 后，下次调优同一项目时可跳过探查直接读取。

生成步骤：
1. 创建 `.agent-tuning/` 目录
2. 将 `probeResult` 按 `assets/manifest-template.md` 的 Markdown 格式写入 `manifest.md`
3. 如果 CodeAgent 构造了测试用例，可同时生成 `test-cases.md`

> manifest 是探查结果的快照。如果项目结构发生了重大变化（如新增/删除工具、prompt 位置迁移），用户应删除 manifest 让 CodeAgent 重新探查，或手动更新 manifest。

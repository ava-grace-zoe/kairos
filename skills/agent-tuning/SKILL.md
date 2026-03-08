---
name: agent-tuning
description: 基于 Langfuse 的引导式内省循环 Agent 配置调优。用户要求"调优 agent/优化 prompt/改进 agent 表现/agent-tuning"时触发，通过「调用 → 轨迹分析 → 内省 → 配置修改」循环迭代优化 TargetAgent 的系统提示词、工具描述和 few-shot 示例。
---

# agent-tuning 执行规范

目标：通过自动化循环，系统化优化 TargetAgent 的行为配置，替代人工反复试错。

设计文档：`docs/agent-tuning/design.md`

## 前置条件

### 必选

- **Langfuse 实例**：可用的 Langfuse 服务（自部署或 Cloud），项目环境变量中包含：
  ```
  LANGFUSE_PUBLIC_KEY=pk-lf-...
  LANGFUSE_SECRET_KEY=sk-lf-...
  LANGFUSE_BASEURL=https://your-langfuse.example.com  # 自部署时必填
  ```
- **AI SDK 项目**：TargetAgent 使用 Vercel AI SDK 构建，支持 `experimental_telemetry` 和 `onStepFinish`
- **OTel 采集配置**：项目已配置 `@langfuse/otel` 的 `LangfuseSpanProcessor`，确保轨迹自动上报

### 可选

- **Langfuse Prompt Management**：若 prompt 已在 Langfuse 管理（存在 prompt name），则 Prompt 通道自动选择 Remote
- **保留验证集**：用户额外提供的场景，用于终止阶段的泛化性回归测试

## 通道选择

agent-tuning 在两个维度上独立选择 remote/local 通道。Langfuse OTel 上报始终开启。

### Prompt 通道

| 通道 | 判断条件 | 行为 |
|------|---------|------|
| **Remote** | 用户指定了 Langfuse prompt name，或代码中使用 `langfuse.prompt.get()` | 读：`prompt.get(label)` 拉取；写：`prompt.create()` 推新版本 + 移动 label |
| **Local** | Prompt 在代码文件中管理（`config.ts` / `prompts.md` / 内联字符串） | 读：读取配置文件；写：编辑配置文件 + 文件快照 |

### 轨迹通道

| 通道 | 判断条件 | 行为 |
|------|---------|------|
| **Remote** | 默认。Langfuse 可用即可 | 用 `@langfuse/tracing` 的 `getActiveTraceId()` 获取 traceId → `langfuse.fetchTrace(traceId)` 拉取结构化轨迹 |
| **Local** | 用户要求本地轨迹，或需精细控制轨迹格式 | `onStepFinish` 回调收集 → `traces/round-NN.json` |

> 典型组合：**全 Remote**（成熟项目）或 **Local Prompt + Remote 轨迹**（Prompt 在代码仓库管理的项目）。

## 接入指南（伪代码）

以下伪代码帮助在新项目中快速搭建 agent-tuning 所需的基础设施。

### 1. 安装依赖

```bash
# AI SDK + Langfuse OTel
npm install ai @ai-sdk/openai @opentelemetry/sdk-node @opentelemetry/api @langfuse/otel @langfuse/tracing langfuse

# 或 bun
bun add ai @ai-sdk/openai @opentelemetry/sdk-node @opentelemetry/api @langfuse/otel @langfuse/tracing langfuse
```

### 2. OTel 初始化（必选，确保轨迹上报）

```typescript
// src/instrument.ts — 在 agent 代码最前面 import
import { NodeSDK } from "@opentelemetry/sdk-node";
import { LangfuseSpanProcessor } from "@langfuse/otel";

const sdk = new NodeSDK({
  spanProcessors: [new LangfuseSpanProcessor()],
});
sdk.start();
```

### 3. 统一模型调用接口

TargetAgent 和 MetaAdvisor 使用同一个模型实例。抽象为统一的调用接口，避免重复配置：

```typescript
// src/model.ts — 统一模型和调用接口
import { generateText } from "ai";
import { openai } from "@ai-sdk/openai";
import type { LanguageModelV1 } from "ai";

export const model: LanguageModelV1 = openai("gpt-4o");

export interface CallOptions {
  system?: string;
  prompt: string;
  tools?: Record<string, any>;
  maxSteps?: number;
}

export async function call(options: CallOptions) {
  return generateText({
    model,
    system: options.system,
    prompt: options.prompt,
    tools: options.tools,
    maxSteps: options.maxSteps ?? 10,
    experimental_telemetry: { isEnabled: true },
  });
}
```

### 4. Agent 配置分离

```typescript
// src/config.ts — Local Prompt 通道使用此文件
export const SYSTEM_PROMPT = `你是一个...`;
export const FEW_SHOT_EXAMPLES = [
  { input: "...", output: "..." },
];
```

```typescript
// src/agent.ts — TargetAgent 使用 model + config
import { ToolLoopAgent, tool } from "ai";
import { model } from "./model";
import { SYSTEM_PROMPT } from "./config";
// 或 Remote Prompt 通道：
// import { LangfuseClient } from "@langfuse/client";
// const langfuse = new LangfuseClient();
// const prompt = await langfuse.prompt.get("my-agent-prompt");

export const agent = new ToolLoopAgent({
  model,
  instructions: SYSTEM_PROMPT,
  // 或 Remote: instructions: prompt.compile(),
  tools: { /* ... */ },
});
```

### 5. MetaAdvisor 调用接口

MetaAdvisor 应当是 TargetAgent 的 **全配置镜像**。这意味着它必须使用相同的模型实例、相同的系统提示词、以及相同的工具集配置。通过将 Advisor 置于完全一致的运行时上下文中，使其能够从执行者的第一人称视角精准内省各配置维度的逻辑缺陷。

```typescript
// src/introspect.ts — MetaAdvisor 全配置镜像化
import { createAgent } from "./agent";

export interface IntrospectOptions {
  trace: string;      // 轨迹摘要
  defects: string;    // 缺陷列表
  promptTemplate: string; // introspection-prompt.md 的内容
}

export async function introspect(options: IntrospectOptions): Promise<string> {
  // 镜像化配置：复用 TargetAgent 的创建工厂，但通常不持久化
  const advisor = createAgent({
    instructions: options.systemPrompt, // 传入当前 TargetAgent 的提示词
    tools: options.tools,              // 传入当前 TargetAgent 的工具集
  });

  const prompt = options.promptTemplate
    .replace("{trace}", options.trace)
    .replace("{defects}", options.defects);

  // 内省是一次性的真相探索：直接对已配置好的 Agent 发起 generate 调用
  const result = await advisor.generate({ prompt });
  return result.text;
}
```

> **核心逻辑**：MetaAdvisor 虽然使用与 TargetAgent 相同的配置，但在执行内省任务时，其输入（Input）不再是用户的业务需求，而是封装了 `trace` 和 `defects` 的内省指令。这使其能够像“照镜子”一样，对照着自己的指令和工具描述来解释故障原因。

### 6. 测试脚本 traceId 输出（Remote 轨迹通道必选）

测试脚本需使用 `@langfuse/tracing` 的 `startActiveObservation` 包裹每个测试执行，以获取 traceId：

```typescript
import { startActiveObservation, getActiveTraceId } from "@langfuse/tracing";

async function runTest(prompt: string) {
  return startActiveObservation(`test-case`, async () => {
    const traceId = getActiveTraceId();
    const result = await agent.generate({
      prompt,
      experimental_telemetry: { isEnabled: true },
    });
    return { ...result, traceId };
  });
}
```

测试脚本应支持 `--json` 参数，输出结构化结果（含 traceId），供 CodeAgent 解析：

```json
{
  "passed": 2,
  "total": 3,
  "results": [
    { "name": "测试名", "pass": true, "reason": "...", "traceId": "abc123..." }
  ]
}
```

### 7. .env.example

```env
# 模型 API Key
OPENAI_API_KEY=sk-...

# Langfuse（必选）
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_BASEURL=https://your-langfuse.example.com
```

## 辅助资源

| 资源 | 路径 | 用途 |
|------|------|------|
| 项目探查指南 | `assets/project-probe.md` | 初始化阶段系统化探查目标项目结构、定位 prompt/工具/few-shot 的可修改点 |
| Manifest 模板 | `assets/manifest-template.md` | `.agent-tuning/manifest.md` 的格式规范，用户提前声明项目结构可跳过探查 |
| 内省 prompt 模板 | `assets/introspection-prompt.md` | 构造 MetaAdvisor 的输入 prompt |
| 轨迹摘要格式 | `assets/trace-format.md` | 将 Remote/Local 轨迹转换为统一文本格式，填入内省 prompt 的 `{trace}` 占位符 |
| 调优状态 schema | `assets/state-schema.md` | `state.json` 的字段定义、回归/震荡/停滞检测算法 |

## 三角色架构

| 角色 | 职责 | 上下文范围 |
|------|------|-----------|
| CodeAgent | 你自己。编排全流程：运行测试、获取轨迹、分析缺陷、修改配置 | 完整代码库 + 全部轨迹 |
| TargetAgent | 被调优对象。按当前配置执行任务 | 仅自身配置 |
| MetaAdvisor | 内省顾问。独立模型调用，隔离上下文 | 仅当前轮轨迹 + 缺陷描述 |

MetaAdvisor 与你使用同一模型但独立调用——它不知道你的修改计划，你不受它的上下文污染。

### MetaAdvisor 调用方式

MetaAdvisor 不是一个常驻进程。它复用项目中与 TargetAgent 相同的模型调用接口（`src/model.ts` 的 `call()`），每次内省时发起一次独立调用：

1. 读取 `assets/introspection-prompt.md` 模板
2. 将当前轮轨迹按 `assets/trace-format.md` 转换为摘要文本，填入 `{trace}` 占位符
3. 将缺陷列表填入 `{defects}` 占位符
4. 调用项目中的 `introspect()` 函数（底层即 `call({ prompt })`），将组装后的 prompt 作为输入
5. 解析返回的文本作为 MetaAdvisor 的建议

关键要求：
- **不传入你的上下文**：`introspect()` 只接收组装后的 prompt，不携带 CodeAgent 的分析、修改历史或计划
- **不传入历史轨迹**：只传当前轮的轨迹和缺陷
- **一次性调用**：每次内省是独立的模型调用，不是对话延续

```typescript
// CodeAgent 内省调用（使用项目中的 introspect 函数）
import { introspect } from "./src/introspect";

const advisorResponse = await introspect({
  trace: formatTrace(currentRoundTrace),
  defects: formatDefects(defectList),
  promptTemplate: readFile("assets/introspection-prompt.md"),
});
```

> 统一接口的好处：model 实例、OTel 配置、telemetry 设置只在 `model.ts` 中定义一次。TargetAgent 和 MetaAdvisor 的区别仅在于是否传入 system prompt 和 tools。

## 一、初始化

### 1.1 项目探查

**先检测约定目录 `.agent-tuning/`**：

1. 检查项目根目录是否存在 `.agent-tuning/manifest.md`
2. **存在** → 读取 manifest 并验证其内容（检查声明的文件是否真实存在、导出名是否可 import）。验证通过后直接将 manifest 内容转为 `probeResult` 写入 `state.json`，跳过后续探查步骤
3. **不存在** → 按 `assets/project-probe.md` 系统化探查目标项目，产出探查报告写入 `state.json.probeResult`

> manifest.md 的格式和字段说明见 `assets/manifest-template.md`。

如果 `.agent-tuning/test-cases.md` 也存在，可跳过 1.3 构造测试，直接使用声明的测试用例。

探查需回答的核心问题（无 manifest 时）：
- TargetAgent 的调用入口在哪？怎么调用它？
- 系统提示词定义在哪？（内联字符串 / 独立变量 / 外部文件 / Langfuse Remote）
- 注册了哪些工具？每个工具的 description 在哪里？
- 有没有 few-shot 示例？在哪里？
- 编排方式是什么？（单步 generateText / ToolLoopAgent / 手动循环 / 多 Agent）

> Prompt 不需要预先分离。CodeAgent 可以直接修改内联字符串、变量引用或外部文件——关键是定位到最终可修改的位置。如果内联 prompt 超过 20 行，建议先提取到变量以降低修改出错风险。

### 1.2 通道配置

根据探查结果确定通道：
- **Prompt 通道**：探查发现 `langfuse.prompt.get()` 或用户指定了 prompt name → Remote；否则 → Local
- **轨迹通道**：默认 Remote（Langfuse API 拉取）；若用户指定或项目已有 `onStepFinish` 回调 → Local
- 确认 OTel 上报已配置（`@langfuse/otel` 的 `LangfuseSpanProcessor`）
- 确认测试脚本支持 `--json` 输出和 traceId（Remote 轨迹通道需要）

探查报告中标为"未就绪"的基础设施项（OTel 未初始化、测试脚本缺失等），在此阶段补齐。

### 1.3 构造测试

根据用户的场景描述，构造可重复执行的 e2e 测试（断言脚本或人工判断标准）。

### 1.4 测试有效性校验

在当前配置下运行测试，确认测试**必须失败**且失败原因与用户描述一致。若已通过则与用户重新对齐。

### 1.5 创建工作目录并初始化状态

```
$TMPDIR/agent-tuning-<YYYYMMDD-HHMMSS>/
├── state.json            # 调优状态（schema 见 assets/state-schema.md，含 probeResult）
├── snapshots/round-00/   # 初始配置快照（Local Prompt 通道）
├── traces/               # 本地轨迹文件（Local 轨迹通道）
└── diffs/
```

- 初始化 `state.json`：写入探查报告（`probeResult`）、设置 `currentRound: 0`、通道配置、`failureBudget: 2`
- **Remote Prompt 通道**：记录当前 prompt version 号到 `state.json.baselinePromptVersion`
- **Local Prompt 通道**：保存初始配置快照到 `snapshots/round-00/`

### 1.6 保留场景（可选）

若用户提供额外场景，记录为保留验证集，终止时用于回归测试。

## 二、调优循环

每轮开始时，递增 `state.json.currentRound`。

### 2.1 运行 TargetAgent

执行测试脚本（`bun run test --json`），获取结构化测试结果。

轨迹获取方式取决于轨迹通道：

- **Remote 轨迹**：从测试结果的 `traceId` 字段，调用 `langfuse.fetchTrace(traceId)` 拉取结构化轨迹。包含完整的 prompt/response/tool call/latency/cost。
  > 注意 OTel 上报有延迟（通常 1-5 秒）。若 `fetchTrace` 返回空，等待几秒后重试。
- **Local 轨迹**：测试脚本已通过 `onStepFinish` 回调将数据写入 `traces/round-NN.json`。

将测试结果记录到 `state.json.rounds[N].tests`。

### 2.2 探索式分析

将轨迹按 `assets/trace-format.md` 转换为统一摘要格式，然后自主分析。不依赖预定义检查清单，根据任务性质推导关注维度。

产出：缺陷列表，每个缺陷附带轨迹中的具体证据位置。记录到 `state.json.rounds[N].defects`。

无缺陷 → 跳到 2.5 终止判断。

### 2.3 引导式内省

1. 读取 `assets/introspection-prompt.md` 模板
2. 将轨迹摘要填入 `{trace}`，缺陷列表填入 `{defects}`
3. 用 `generateText` 做一次独立模型调用（详见上方"MetaAdvisor 调用方式"）
4. 解析 MetaAdvisor 的回答

消费内省结果：
- 与你的缺陷分析**指向同一修改点** → 高置信度，直接执行。记录 `agreement: "same_target"`
- **指向不同修改点** → 评估两侧轨迹证据强度，选证据更充分的一方；无法判断时倾向 MetaAdvisor。记录 `agreement: "different_chose_code"` 或 `"different_chose_meta"`
- 记录内省结果到 `state.json.rounds[N].introspection`

### 2.4 修改配置

执行**单一最小化修改**：

变更单位：
- 系统提示词：一个语义完整的指令段落
- 工具描述：一个工具的 description 或一个 parameter 的说明
- few-shot 示例：一个完整示例条目

步骤：
1. 根据 `state.json.probeResult` 定位修改目标文件和行号
2. 执行修改：
   - **Remote Prompt 通道（系统提示词 / few-shot）**：`langfuse.prompt.create({ name, prompt, labels: ["round-NN"] })` 推新版本
   - **Local Prompt 通道（系统提示词 / few-shot）**：编辑探查报告中记录的 `prompt.editTarget` 文件（可能是 config.ts、内联字符串、外部 .md 文件等）
   - **工具描述**（与通道无关）：编辑探查报告中记录的工具 `descriptionLocation`
3. **验证配置可加载**：
   - 运行 `bun run -e "import '<entryFile>'"` 确认 agent 模块可加载（`<entryFile>` 来自探查报告的 `entryFile`）
   - Remote Prompt：调用 `langfuse.prompt.get(name)` 确认新版本可拉取
   - 失败则立即回滚
4. 保存快照：Remote Prompt → 记录 version 号到 `state.json`；Local Prompt → `snapshots/round-NN/`
5. 生成 diff 到 `diffs/round-NN.diff`
6. 记录修改详情到 `state.json.rounds[N].modification`

> 逃逸机制：单一修改连续 2 轮回滚时，可尝试「耦合修改包」——两个有因果依赖的修改捆绑为原子变更，在 diff 中标注依赖关系。记录 `modification.type: "coupled_change"`。

### 2.5 终止判断

读取 `state.json` 中的历史数据，按以下算法判断：

**回归检测**（每轮必查）：

```
对比 round N 和 round N-1 的 tests：
  若存在 test.pass(N-1) == true AND test.pass(N) == false:
    → 回归（regression）
    → 回滚到 round N-1 的配置
    → state.failureBudgetUsed += 1
    → 若 failureBudgetUsed >= failureBudget → 终止
    → 否则排除已失败方向，继续循环
```

**震荡检测**：

```
对每个测试用例，检查最近 3 轮的 pass 序列：
  若序列为 [true, false, true] 或 [false, true, false]:
    → 震荡（oscillation）
    → 终止，提示用户指令空间存在互斥冲突
```

**收敛停滞检测**：

```
对比 round N 和 round N-1 的 tests：
  若所有测试用例的 pass 值完全相同:
    → 连续 2 轮相同则终止
```

**其他终止条件**：

| 条件 | 处理 |
|------|------|
| 测试全部通过 | 终止，输出报告 |
| 循环上限（默认 5 轮） | 终止，输出当前最佳配置 |

记录 `state.json.terminationReason`。未终止 → 回到 2.1。

## 三、终止与产出

在对话中直接输出：

1. **调优结果摘要**：通过/未通过/部分改善
2. **配置对比**：初始快照 vs 最终配置的关键 diff
3. **每轮变更摘要**（从 `state.json.rounds` 提取）：缺陷 → 内省建议 → 修改操作 → 效果变化
4. **Langfuse 链接**：提供 Langfuse UI 中对应 traces / prompts 的链接，方便用户查看详细轨迹
5. **保留场景回归结果**（如有）
6. **配置精简建议**：检查最终配置的冗余和冲突，给出精简建议

> 工作目录 `$TMPDIR/agent-tuning-*/` 保留供用户后续查看，不自动清理。

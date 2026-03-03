# Agent Tuning Manifest 模板

用户在项目中创建 `.agent-tuning/manifest.md` 来声明项目结构，CodeAgent 读取后跳过探查步骤。

## 约定目录

```
<project-root>/
└── .agent-tuning/
    ├── manifest.md        # 项目结构声明（必选）
    └── test-cases.md      # 测试用例声明（可选，替代 CodeAgent 自己构造）
```

## manifest.md 模板

以下是用户应在项目中创建的 `.agent-tuning/manifest.md` 的完整模板。`<!-- -->` 注释为填写指引，用户填写后删除。

````markdown
# Agent Tuning Manifest

## 调用入口

- 文件：`src/agent.ts`
- 导出：`weatherAgent`
- 调用方式：`weatherAgent.generate({ prompt })`
- 编排类型：ToolLoopAgent
  <!-- 可选值：single_call / ToolLoopAgent / manual_loop / multi_agent / pipeline -->

## 系统提示词

- 来源类型：变量引用
  <!-- 可选值：内联字符串 / 变量引用 / 文件读取 / 模板拼接 / Langfuse Remote / 配置对象 -->
- 来源链路：
  1. `src/agent.ts:18` → `import { SYSTEM_PROMPT } from "./config"`
  2. `src/config.ts:1` → `SYSTEM_PROMPT` 定义（模板字符串）
- 编辑目标：`src/config.ts:1`
<!-- Langfuse Remote 时额外填写：
- Langfuse Prompt Name：my-agent-prompt
- Langfuse Label：production
-->

## 工具清单

| 工具名 | description 位置 | 内联 | 备注 |
|--------|-----------------|------|------|
| getWeather | `src/agent.ts:21` | 是 | |
| compareWeather | `src/agent.ts:33` | 是 | |

<!-- 如果工具的 description 引用了外部变量或文件，在"备注"中说明引用路径 -->

## Few-shot 示例

- 是否存在：否
- 预留位置：`src/config.ts:3`（`FEW_SHOT_EXAMPLES` 空数组）
<!-- 存在时填写：
- 形态：独立数组
  可选值：prompt 内联 / 独立数组 / messages 预填充 / 外部文件
- 位置：src/config.ts:3
-->

## 测试脚本

- 执行命令：`bun run test`
- 结构化输出：`--json`
- 支持 traceId：是

## 补充说明

<!-- 可选。写下 CodeAgent 需要知道的项目特殊情况，例如：
- prompt 中有动态拼接逻辑
- 某些工具的 execute 依赖外部服务
- 多 Agent 编排中只调优某个子 Agent
- 特定的环境变量要求
-->
````

## test-cases.md 模板（可选）

用户可在 `.agent-tuning/test-cases.md` 中声明测试用例，CodeAgent 据此构造测试脚本。

````markdown
# Agent Tuning 测试用例

## 测试场景

### 单城市查询应调用 getWeather

- 输入：`北京今天天气怎么样？`
- 期望工具调用：getWeather
- 期望输出包含：温度数值

### 多城市比较应调用 compareWeather

- 输入：`帮我比较一下北京和上海的天气`
- 期望工具调用：compareWeather

### 不支持的城市应优雅处理

- 输入：`纽约天气怎么样？`
- 期望工具调用：getWeather
- 期望输出包含（任一）：不支持 / 可查询 / 支持的城市

## 保留验证集

<!-- 可选。终止阶段回归测试用，调优过程中不参与循环 -->

### 正常城市不受影响

- 输入：`上海天气怎么样？`
- 期望工具调用：getWeather
- 期望输出包含：温度数值
````

## CodeAgent 读取规则

1. 读取 `.agent-tuning/manifest.md`，提取各节内容填入 `state.json.probeResult`

2. 字段映射：
   - "调用入口" → `entryFile` / `entryExport` / `invocation` / `orchestration`
   - "系统提示词" → `prompt.type` / `prompt.chain` / `prompt.editTarget`
   - "工具清单" 表格 → `tools[]`
   - "Few-shot 示例" → `fewShot`
   - "测试脚本" → `readiness.testScript` / `readiness.testJsonOutput`

3. 验证：读取后逐项验证声明的文件是否存在、导出名是否可 import。验证失败的条目标记警告，不阻塞流程但在探查报告中注明。

4. "补充说明"节的内容记录到 `probeResult.notes`，供后续阶段参考。

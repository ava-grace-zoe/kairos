# 轨迹摘要格式

CodeAgent 将原始轨迹数据转换为此格式后，填入 `introspection-prompt.md` 的 `{trace}` 占位符。无论轨迹来自 Remote（Langfuse API）还是 Local（onStepFinish JSON），都统一转换为此格式。

## 格式

```
## 输入
用户: {user_prompt}

## 执行步骤

### Step 1: 模型推理
思考: {model_reasoning_if_available}
决策: 调用工具 {tool_name}

### Step 2: 工具调用
工具: {tool_name}
参数: {tool_args_json}
返回: {tool_result_json}

### Step 3: 模型推理
思考: {model_reasoning_if_available}
决策: 调用工具 / 生成最终回答

...（重复直到最终回答）

### Step N: 最终回答
回答: {final_text}

## 元数据
总步数: {step_count}
工具调用次数: {tool_call_count}
工具调用列表: {tool_name_1}, {tool_name_2}, ...
```

## 转换规则

### 从 Remote 轨迹（Langfuse fetchTrace 结果）

```typescript
function formatRemoteTrace(trace: LangfuseTrace): string {
  const lines: string[] = [];
  lines.push(`## 输入`);
  lines.push(`用户: ${trace.input}`);
  lines.push(``);
  lines.push(`## 执行步骤`);

  let stepNum = 1;
  for (const obs of trace.observations) {
    if (obs.type === "GENERATION") {
      lines.push(`### Step ${stepNum++}: 模型推理`);
      if (obs.input) lines.push(`输入: ${JSON.stringify(obs.input).slice(0, 500)}`);
      if (obs.output) lines.push(`输出: ${JSON.stringify(obs.output).slice(0, 500)}`);
    } else if (obs.type === "SPAN" && obs.name?.includes("tool")) {
      lines.push(`### Step ${stepNum++}: 工具调用`);
      lines.push(`工具: ${obs.name}`);
      if (obs.input) lines.push(`参数: ${JSON.stringify(obs.input)}`);
      if (obs.output) lines.push(`返回: ${JSON.stringify(obs.output)}`);
    }
    lines.push(``);
  }

  lines.push(`## 元数据`);
  lines.push(`总步数: ${stepNum - 1}`);
  if (trace.output) lines.push(`最终回答: ${trace.output}`);

  return lines.join("\n");
}
```

### 从 Local 轨迹（onStepFinish JSON）

```typescript
function formatLocalTrace(data: {
  prompt: string;
  text: string;
  steps: any[];
  toolCalls: any[];
}): string {
  const lines: string[] = [];
  lines.push(`## 输入`);
  lines.push(`用户: ${data.prompt}`);
  lines.push(``);
  lines.push(`## 执行步骤`);

  let stepNum = 1;
  for (const step of data.steps) {
    if (step.toolCalls?.length) {
      for (const tc of step.toolCalls) {
        lines.push(`### Step ${stepNum++}: 工具调用`);
        lines.push(`工具: ${tc.toolName}`);
        lines.push(`参数: ${JSON.stringify(tc.args)}`);
        if (tc.result) lines.push(`返回: ${JSON.stringify(tc.result)}`);
        lines.push(``);
      }
    }
    if (step.text) {
      lines.push(`### Step ${stepNum++}: 模型回答`);
      lines.push(`回答: ${step.text}`);
      lines.push(``);
    }
  }

  lines.push(`### 最终回答`);
  lines.push(`回答: ${data.text}`);
  lines.push(``);
  lines.push(`## 元数据`);
  lines.push(`总步数: ${stepNum - 1}`);
  lines.push(`工具调用次数: ${data.toolCalls.length}`);
  lines.push(`工具调用列表: ${data.toolCalls.map(tc => tc.toolName).join(", ")}`);

  return lines.join("\n");
}
```

## 长度控制

- 单步的 input/output 超过 500 字符时截断并追加 `...（截断）`
- 总摘要超过 3000 字符时，保留首尾步骤，中间步骤压缩为 `...（省略 N 步）`
- 目标：摘要控制在 1000-3000 字符以内，确保 MetaAdvisor 有足够的上下文但不被无关细节干扰

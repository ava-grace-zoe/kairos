import "./instrument";
import { weatherAgent } from "./agent";
import { saveLocalTrace } from "./tracing";
import { getActiveTraceId, startActiveObservation } from "@langfuse/tracing";

interface TestCase {
  name: string;
  prompt: string;
  validate: (text: string, steps: any[]) => { pass: boolean; reason: string };
}

export interface TestResult {
  name: string;
  prompt: string;
  pass: boolean;
  reason: string;
  traceId: string | undefined;
  text: string;
  toolCalls: { toolName: string; args: any }[];
}

const testCases: TestCase[] = [
  {
    name: "单城市查询应调用 getWeather",
    prompt: "北京今天天气怎么样？",
    validate: (text, steps) => {
      const toolCalls = steps.flatMap((s: any) => s.toolCalls || []);
      const usedGetWeather = toolCalls.some((tc: any) => tc.toolName === "getWeather");
      if (!usedGetWeather) {
        return { pass: false, reason: "未调用 getWeather 工具" };
      }
      const hasTemp = text.includes("5") || text.includes("度");
      if (!hasTemp) {
        return { pass: false, reason: "回答中未包含温度信息" };
      }
      return { pass: true, reason: "正确调用工具并返回温度" };
    },
  },
  {
    name: "多城市比较应调用 compareWeather",
    prompt: "帮我比较一下北京和上海的天气",
    validate: (text, steps) => {
      const toolCalls = steps.flatMap((s: any) => s.toolCalls || []);
      const usedCompare = toolCalls.some((tc: any) => tc.toolName === "compareWeather");
      if (!usedCompare) {
        return { pass: false, reason: "未调用 compareWeather 工具，应该用 compareWeather 而非多次调用 getWeather" };
      }
      return { pass: true, reason: "正确使用 compareWeather 工具" };
    },
  },
  {
    name: "不支持的城市应优雅处理",
    prompt: "纽约天气怎么样？",
    validate: (text, steps) => {
      const toolCalls = steps.flatMap((s: any) => s.toolCalls || []);
      const usedGetWeather = toolCalls.some((tc: any) => tc.toolName === "getWeather");
      if (!usedGetWeather) {
        return { pass: false, reason: "应先尝试调用 getWeather" };
      }
      const mentionsUnavailable = text.includes("没有") || text.includes("不支持") || text.includes("暂无") || text.includes("无法");
      if (!mentionsUnavailable) {
        return { pass: false, reason: "未明确告知用户该城市不可用" };
      }
      const listsCities = text.includes("北京") || text.includes("上海") || text.includes("支持");
      if (!listsCities) {
        return { pass: false, reason: "未列出可查询的城市列表" };
      }
      return { pass: true, reason: "正确处理不支持的城市并提供替代建议" };
    },
  },
];

const SAVE_LOCAL_TRACES = process.argv.includes("--local-traces");
const OUTPUT_JSON = process.argv.includes("--json");

async function runSingleTest(tc: TestCase, index: number): Promise<TestResult> {
  return startActiveObservation(`test-${index}`, async () => {
    const traceId = getActiveTraceId();

    const result = await weatherAgent.generate({
      prompt: tc.prompt,
      experimental_telemetry: { isEnabled: true },
    });

    const toolCalls = result.steps.flatMap((s: any) => s.toolCalls || []);
    const validation = tc.validate(result.text, result.steps);

    if (SAVE_LOCAL_TRACES) {
      saveLocalTrace(index + 1, {
        prompt: tc.prompt,
        text: result.text,
        steps: result.steps,
        toolCalls,
      });
    }

    return {
      name: tc.name,
      prompt: tc.prompt,
      pass: validation.pass,
      reason: validation.reason,
      traceId,
      text: result.text,
      toolCalls: toolCalls.map((tc: any) => ({ toolName: tc.toolName, args: tc.args })),
    };
  });
}

async function runTests() {
  const results: TestResult[] = [];

  if (!OUTPUT_JSON) {
    console.log("🧪 agent-tuning 测试套件\n");
  }

  for (let i = 0; i < testCases.length; i++) {
    const tc = testCases[i];

    if (!OUTPUT_JSON) {
      console.log(`▶ ${tc.name}`);
      console.log(`  prompt: "${tc.prompt}"`);
    }

    try {
      const result = await runSingleTest(tc, i);
      results.push(result);

      if (!OUTPUT_JSON) {
        if (result.pass) {
          console.log(`  ✅ PASS: ${result.reason}`);
        } else {
          console.log(`  ❌ FAIL: ${result.reason}`);
          console.log(`  回答: ${result.text.slice(0, 200)}`);
          if (result.toolCalls.length) {
            console.log(`  工具调用: ${result.toolCalls.map(tc => `${tc.toolName}(${JSON.stringify(tc.args)})`).join(", ")}`);
          }
        }
        if (result.traceId) {
          console.log(`  traceId: ${result.traceId}`);
        }
        console.log();
      }
    } catch (err: any) {
      results.push({
        name: tc.name,
        prompt: tc.prompt,
        pass: false,
        reason: `ERROR: ${err.message}`,
        traceId: undefined,
        text: "",
        toolCalls: [],
      });
      if (!OUTPUT_JSON) {
        console.log(`  ❌ ERROR: ${err.message}\n`);
      }
    }
  }

  const passed = results.filter(r => r.pass).length;

  if (OUTPUT_JSON) {
    console.log(JSON.stringify({ passed, total: results.length, results }, null, 2));
  } else {
    console.log(`\n📊 结果: ${passed}/${results.length} 通过`);
  }

  process.exit(passed === results.length ? 0 : 1);
}

runTests();

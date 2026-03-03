import "./instrument";
import { weatherAgent } from "./agent";

async function main() {
  const prompt = process.argv[2] || "北京今天天气怎么样？";

  console.log(`\n📝 用户: ${prompt}\n`);

  const result = await weatherAgent.generate({
    prompt,
    experimental_telemetry: { isEnabled: true },
  });

  console.log(`🤖 助手: ${result.text}\n`);

  if (result.steps.length > 1) {
    console.log(`📊 执行步骤: ${result.steps.length}`);
    for (const step of result.steps) {
      if (step.toolCalls?.length) {
        for (const tc of step.toolCalls) {
          console.log(`  🔧 ${tc.toolName}(${JSON.stringify(tc.args)})`);
        }
      }
    }
  }
}

main().catch(console.error);

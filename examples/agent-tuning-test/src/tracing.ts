import { mkdirSync, writeFileSync, existsSync } from "fs";
import { join } from "path";

const TRACES_DIR = join(import.meta.dir, "..", "traces");

export function saveLocalTrace(roundNumber: number, data: {
  prompt: string;
  text: string;
  steps: any[];
  toolCalls: any[];
}) {
  if (!existsSync(TRACES_DIR)) {
    mkdirSync(TRACES_DIR, { recursive: true });
  }

  const filePath = join(TRACES_DIR, `round-${String(roundNumber).padStart(2, "0")}.json`);
  writeFileSync(filePath, JSON.stringify(data, null, 2), "utf-8");
  console.log(`  📁 轨迹已保存: ${filePath}`);
}

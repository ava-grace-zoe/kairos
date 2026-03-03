import "./instrument";
import { ToolLoopAgent, tool } from "ai";
import { z } from "zod";
import { model } from "./model";
import { SYSTEM_PROMPT } from "./config";

const weatherData: Record<string, { temp: number; condition: string; humidity: number; wind: string }> = {
  北京: { temp: 5, condition: "晴", humidity: 30, wind: "北风3级" },
  上海: { temp: 12, condition: "多云", humidity: 65, wind: "东风2级" },
  广州: { temp: 22, condition: "阴", humidity: 80, wind: "南风1级" },
  深圳: { temp: 23, condition: "多云转晴", humidity: 75, wind: "东南风2级" },
  成都: { temp: 10, condition: "小雨", humidity: 85, wind: "微风" },
  杭州: { temp: 11, condition: "阴", humidity: 70, wind: "东北风2级" },
};

export const weatherAgent = new ToolLoopAgent({
  model,
  instructions: SYSTEM_PROMPT,
  tools: {
    getWeather: tool({
      description: "获取天气",
      inputSchema: z.object({
        city: z.string(),
      }),
      execute: async ({ city }) => {
        const data = weatherData[city];
        if (!data) {
          return { error: `没有 ${city} 的天气数据` };
        }
        return data;
      },
    }),
    compareWeather: tool({
      description: "比较天气",
      inputSchema: z.object({
        cities: z.array(z.string()),
      }),
      execute: async ({ cities }) => {
        const results: Record<string, any> = {};
        for (const city of cities) {
          const data = weatherData[city];
          if (data) results[city] = data;
        }
        return results;
      },
    }),
  },
});

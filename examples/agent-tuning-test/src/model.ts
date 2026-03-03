import { generateText } from "ai";
import { createGoogleGenerativeAI } from "@ai-sdk/google";
import type { LanguageModelV1 } from "ai";

const google = createGoogleGenerativeAI({
  apiKey: process.env.GOOGLE_API_KEY,
});

export const model: LanguageModelV1 = google("gemini-2.5-flash");

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

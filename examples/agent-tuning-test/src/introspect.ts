import { call } from "./model";

export interface IntrospectOptions {
  trace: string;
  defects: string;
  promptTemplate: string;
}

export async function introspect(options: IntrospectOptions): Promise<string> {
  const prompt = options.promptTemplate
    .replace("{trace}", options.trace)
    .replace("{defects}", options.defects);

  const result = await call({ prompt });
  return result.text;
}

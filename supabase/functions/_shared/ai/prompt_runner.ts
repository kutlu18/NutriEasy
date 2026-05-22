import type { AiMeta, AiPromptDefinition, ConfidenceLabel } from "./types.ts";

type RunOptions<T> = {
  prompt: AiPromptDefinition;
  variables: Record<string, string>;
  parse: (value: unknown) => T;
  confidence?: ConfidenceLabel;
};

function renderTemplate(template: string, variables: Record<string, string>) {
  return Object.entries(variables).reduce(
    (output, [key, value]) => output.replaceAll(`{{${key}}}`, value),
    template,
  );
}

function extractOutputText(response: Record<string, unknown>) {
  if (typeof response.output_text === "string") return response.output_text;
  const output = Array.isArray(response.output) ? response.output : [];
  for (const item of output) {
    if (!item || typeof item !== "object") continue;
    const content = Array.isArray((item as Record<string, unknown>).content)
      ? (item as Record<string, unknown>).content as unknown[]
      : [];
    for (const contentItem of content) {
      if (!contentItem || typeof contentItem !== "object") continue;
      const record = contentItem as Record<string, unknown>;
      if (typeof record.text === "string") return record.text;
    }
  }
  return "";
}

function aiMeta(
  prompt: AiPromptDefinition,
  start: number,
  provider: AiMeta["provider"],
  confidence: ConfidenceLabel,
  fallbackUsed: boolean,
): AiMeta {
  return {
    model: prompt.model,
    prompt_id: prompt.id,
    prompt_version: prompt.version,
    provider,
    latency_ms: Date.now() - start,
    confidence,
    fallback_used: fallbackUsed,
  };
}

export function heuristicMeta(
  prompt: AiPromptDefinition,
  start: number,
  confidence: ConfidenceLabel,
  fallbackUsed = true,
) {
  return aiMeta(prompt, start, "heuristic", confidence, fallbackUsed);
}

export async function runStructuredPrompt<T>(
  options: RunOptions<T>,
): Promise<{ data: T | null; meta: AiMeta }> {
  const start = Date.now();
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  const confidence = options.confidence ?? "medium";

  if (!apiKey) {
    return {
      data: null,
      meta: heuristicMeta(options.prompt, start, confidence, true),
    };
  }

  const userPrompt = renderTemplate(options.prompt.userTemplate, options.variables);

  try {
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: options.prompt.model,
        input: [
          { role: "system", content: options.prompt.system },
          { role: "user", content: userPrompt },
        ],
        temperature: options.prompt.temperature,
        text: {
          format: {
            type: "json_schema",
            name: options.prompt.schemaName,
            strict: true,
            schema: options.prompt.schema,
          },
        },
      }),
    });

    if (!response.ok) {
      return {
        data: null,
        meta: heuristicMeta(options.prompt, start, confidence, true),
      };
    }

    const raw = await response.json() as Record<string, unknown>;
    const outputText = extractOutputText(raw);
    const parsedJson = JSON.parse(outputText);
    const data = options.parse(parsedJson);

    return {
      data,
      meta: aiMeta(options.prompt, start, "openai", confidence, false),
    };
  } catch {
    return {
      data: null,
      meta: heuristicMeta(options.prompt, start, confidence, true),
    };
  }
}

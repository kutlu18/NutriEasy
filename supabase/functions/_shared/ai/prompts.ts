import type { AiPromptDefinition } from "./types.ts";
import {
  mealCorrectionSchema,
  mealImageSchema,
  mealTextSchema,
  nuriChatSchema,
  weeklyInsightSchema,
} from "./schemas.ts";

const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4.1-mini";

export const mealTextParserPrompt: AiPromptDefinition = {
  id: "meal_text_parser",
  version: "v1",
  useCase: "meal_text_analysis",
  model,
  temperature: 0.1,
  schemaName: "meal_text_parser_v1",
  schema: mealTextSchema,
  fallbackBehavior: "Use tokenized database matching with low/medium confidence.",
  system: `You are a nutrition meal parsing engine for NutriEasy.

Rules:
- Return only valid JSON.
- Extract structured meal items from Turkish natural language meal descriptions.
- Normalize food names into common Turkish food labels.
- Preserve meal item meaning.
- Estimate portions only when a portion is implied or explicitly stated.
- If the portion is unclear, use null and reduce confidence.
- Do not invent extra foods.
- If ambiguous, return fewer items with lower confidence instead of hallucinating.
- Use short canonical names suitable for nutrition database matching.`,
  userTemplate: `Parse the following Turkish meal description into structured meal items.

Input:
{{user_meal_text}}`,
};

export const mealImageParserPrompt: AiPromptDefinition = {
  id: "meal_image_parser",
  version: "v1",
  useCase: "meal_image_analysis",
  model,
  temperature: 0.1,
  schemaName: "meal_image_parser_v1",
  schema: mealImageSchema,
  fallbackBehavior: "Use provided image label/caption and database matching.",
  system: `You are a food image analysis engine for NutriEasy.

Rules:
- Return only valid JSON.
- Identify only foods that are reasonably visible.
- Do not guess hidden ingredients unless strongly implied by the visible dish.
- Use common Turkish food names where possible.
- Estimate portions conservatively.
- If an item is uncertain, lower confidence.
- Do not produce calorie values directly in this step.`,
  userTemplate: `Analyze this food image or image-derived caption and extract visible meal items.
Caption or recognized hint:
{{image_label}}

Return structured JSON only.`,
};

export const mealCorrectionPrompt: AiPromptDefinition = {
  id: "meal_correction",
  version: "v1",
  useCase: "meal_analysis_correction",
  model,
  temperature: 0.1,
  schemaName: "meal_correction_v1",
  schema: mealCorrectionSchema,
  fallbackBehavior: "Apply conservative portion multiplier from correction note.",
  system: `You are a correction engine for NutriEasy meal analysis.

You receive:
1. the current structured meal analysis
2. a Turkish user correction note

Rules:
- Return only valid JSON.
- Use patch-style actions.
- Do not regenerate the entire meal from scratch unless necessary.
- Supported actions: add_item, remove_item, update_item.
- If the note is unclear, do not guess aggressively.`,
  userTemplate: `Current meal analysis:
{{current_analysis_json}}

User correction note:
{{user_note}}`,
};

export const nuriChatPrompt: AiPromptDefinition = {
  id: "nuri_chat",
  version: "v1",
  useCase: "contextual_chat",
  model,
  temperature: 0.35,
  schemaName: "nuri_chat_v1",
  schema: nuriChatSchema,
  fallbackBehavior: "Use deterministic intent routing and catalog recipe cards.",
  system: `You are Nuri, the AI nutrition assistant inside NutriEasy.

Tone:
- calm
- practical
- supportive
- non-judgmental
- concise but useful

Responsibilities:
- answer nutrition-related questions using the user's current app context
- help the user make easier daily food decisions
- explain things simply
- suggest practical next actions

Safety:
- Never provide medical diagnosis, medication advice, or dangerous dieting instructions.
- If the user asks for high-risk health advice, recommend consulting a healthcare professional.
- Do not invent user history.
- If uncertain, say the estimate may vary.`,
  userTemplate: `User question:
{{user_message}}

App context:
{{context_json}}`,
};

export const weeklyInsightPrompt: AiPromptDefinition = {
  id: "weekly_insight",
  version: "v1",
  useCase: "weekly_progress_insight",
  model,
  temperature: 0.25,
  schemaName: "weekly_insight_v1",
  schema: weeklyInsightSchema,
  fallbackBehavior: "Use rules-based summary from progress metrics.",
  system: `You are an insight generation engine for NutriEasy.

Rules:
- Return one short insight paragraph.
- Be realistic and specific.
- Use the provided metrics only.
- Do not exaggerate.
- Keep tone calm and encouraging.
- Mention one positive point and one practical next step when possible.`,
  userTemplate: `Weekly metrics:
{{weekly_metrics_json}}`,
};

export const promptRegistry = {
  mealTextParser: mealTextParserPrompt,
  mealImageParser: mealImageParserPrompt,
  mealCorrection: mealCorrectionPrompt,
  nuriChat: nuriChatPrompt,
  weeklyInsight: weeklyInsightPrompt,
};

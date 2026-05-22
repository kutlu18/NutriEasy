export type ConfidenceLabel = "low" | "medium" | "high";

export type AiPromptDefinition = {
  id: string;
  version: string;
  useCase: string;
  system: string;
  userTemplate: string;
  model: string;
  temperature: number;
  schemaName: string;
  schema: Record<string, unknown>;
  fallbackBehavior: string;
};

export type AiMeta = {
  model: string;
  prompt_id: string;
  prompt_version: string;
  provider: "openai" | "heuristic";
  latency_ms: number;
  confidence: ConfidenceLabel;
  fallback_used: boolean;
};

export type ParsedMealItem = {
  name: string;
  portion_text: string | null;
  portion_estimate: string | null;
  confidence: number;
};

export type ParsedMealText = {
  meal_items: ParsedMealItem[];
  overall_confidence: number;
  notes: string[];
};

export type ParsedMealImage = {
  detected_items: {
    name: string;
    portion_label: string | null;
    confidence: number;
  }[];
  overall_confidence: ConfidenceLabel;
  notes: string[];
};

export type CorrectionAction = {
  type: "add_item" | "remove_item" | "update_item";
  target: string | null;
  item?: {
    name: string;
    portion: string | null;
  } | null;
  new_portion?: string | null;
};

export type MealCorrectionPatch = {
  actions: CorrectionAction[];
};

export type NuriChatJson = {
  reply: string;
  suggested_actions: {
    type: "open_recipe" | "open_plan" | "start_photo_analysis" | "quick_add" | "none";
    label: string;
  }[];
  recipe_card: {
    title: string;
    estimated_calories: number;
    protein: number;
    carbs: number;
    id: string;
  } | null;
};

export type WeeklyInsightJson = {
  headline: string;
  insight: string;
};

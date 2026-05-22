import type {
  MealCorrectionPatch,
  NuriChatJson,
  ParsedMealImage,
  ParsedMealText,
  WeeklyInsightJson,
} from "./types.ts";

export const mealTextSchema = {
  type: "object",
  additionalProperties: false,
  required: ["meal_items", "overall_confidence", "notes"],
  properties: {
    meal_items: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "portion_text", "portion_estimate", "confidence"],
        properties: {
          name: { type: "string" },
          portion_text: { type: ["string", "null"] },
          portion_estimate: { type: ["string", "null"] },
          confidence: { type: "number", minimum: 0, maximum: 1 },
        },
      },
    },
    overall_confidence: { type: "number", minimum: 0, maximum: 1 },
    notes: { type: "array", items: { type: "string" } },
  },
};

export const mealImageSchema = {
  type: "object",
  additionalProperties: false,
  required: ["detected_items", "overall_confidence", "notes"],
  properties: {
    detected_items: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "portion_label", "confidence"],
        properties: {
          name: { type: "string" },
          portion_label: { type: ["string", "null"] },
          confidence: { type: "number", minimum: 0, maximum: 1 },
        },
      },
    },
    overall_confidence: { type: "string", enum: ["low", "medium", "high"] },
    notes: { type: "array", items: { type: "string" } },
  },
};

export const mealCorrectionSchema = {
  type: "object",
  additionalProperties: false,
  required: ["actions"],
  properties: {
    actions: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["type", "target", "item", "new_portion"],
        properties: {
          type: { type: "string", enum: ["add_item", "remove_item", "update_item"] },
          target: { type: ["string", "null"] },
          item: {
            type: ["object", "null"],
            additionalProperties: false,
            required: ["name", "portion"],
            properties: {
              name: { type: "string" },
              portion: { type: ["string", "null"] },
            },
          },
          new_portion: { type: ["string", "null"] },
        },
      },
    },
  },
};

export const nuriChatSchema = {
  type: "object",
  additionalProperties: false,
  required: ["reply", "suggested_actions", "recipe_card"],
  properties: {
    reply: { type: "string" },
    suggested_actions: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["type", "label"],
        properties: {
          type: {
            type: "string",
            enum: ["open_recipe", "open_plan", "start_photo_analysis", "quick_add", "none"],
          },
          label: { type: "string" },
        },
      },
    },
    recipe_card: {
      type: ["object", "null"],
      additionalProperties: false,
      required: ["title", "estimated_calories", "protein", "carbs", "id"],
      properties: {
        title: { type: "string" },
        estimated_calories: { type: "number" },
        protein: { type: "number" },
        carbs: { type: "number" },
        id: { type: "string" },
      },
    },
  },
};

export const weeklyInsightSchema = {
  type: "object",
  additionalProperties: false,
  required: ["headline", "insight"],
  properties: {
    headline: { type: "string" },
    insight: { type: "string" },
  },
};

function isObject(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

function num(value: unknown, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function parseMealTextJson(value: unknown): ParsedMealText {
  if (!isObject(value)) throw new Error("invalid_meal_text_json");
  const items = Array.isArray(value.meal_items) ? value.meal_items : [];
  return {
    meal_items: items
      .filter(isObject)
      .map((item) => ({
        name: String(item.name ?? "").trim(),
        portion_text: item.portion_text == null ? null : String(item.portion_text),
        portion_estimate: item.portion_estimate == null ? null : String(item.portion_estimate),
        confidence: Math.max(0, Math.min(1, num(item.confidence, 0.5))),
      }))
      .filter((item) => item.name.length > 0),
    overall_confidence: Math.max(0, Math.min(1, num(value.overall_confidence, 0.5))),
    notes: (Array.isArray(value.notes) ? value.notes : []).map(String),
  };
}

export function parseMealImageJson(value: unknown): ParsedMealImage {
  if (!isObject(value)) throw new Error("invalid_meal_image_json");
  const items = Array.isArray(value.detected_items) ? value.detected_items : [];
  const confidence = String(value.overall_confidence ?? "low");
  return {
    detected_items: items
      .filter(isObject)
      .map((item) => ({
        name: String(item.name ?? "").trim(),
        portion_label: item.portion_label == null ? null : String(item.portion_label),
        confidence: Math.max(0, Math.min(1, num(item.confidence, 0.5))),
      }))
      .filter((item) => item.name.length > 0),
    overall_confidence: confidence === "high" || confidence === "medium" ? confidence : "low",
    notes: (Array.isArray(value.notes) ? value.notes : []).map(String),
  };
}

export function parseCorrectionJson(value: unknown): MealCorrectionPatch {
  if (!isObject(value)) throw new Error("invalid_correction_json");
  const actions = Array.isArray(value.actions) ? value.actions : [];
  return {
    actions: actions.filter(isObject).map((action) => {
      const type = String(action.type);
      const item = isObject(action.item)
        ? {
            name: String(action.item.name ?? ""),
            portion: action.item.portion == null ? null : String(action.item.portion),
          }
        : null;
      return {
        type: type === "add_item" || type === "remove_item" || type === "update_item" ? type : "update_item",
        target: action.target == null ? null : String(action.target),
        item,
        new_portion: action.new_portion == null ? null : String(action.new_portion),
      };
    }),
  };
}

export function parseNuriChatJson(value: unknown): NuriChatJson {
  if (!isObject(value)) throw new Error("invalid_nuri_chat_json");
  const recipe = isObject(value.recipe_card) ? value.recipe_card : null;
  return {
    reply: String(value.reply ?? ""),
    suggested_actions: (Array.isArray(value.suggested_actions) ? value.suggested_actions : [])
      .filter(isObject)
      .map((item) => ({
        type: ["open_recipe", "open_plan", "start_photo_analysis", "quick_add"].includes(String(item.type))
          ? String(item.type) as NuriChatJson["suggested_actions"][number]["type"]
          : "none",
        label: String(item.label ?? ""),
      })),
    recipe_card: recipe
      ? {
          title: String(recipe.title ?? ""),
          estimated_calories: num(recipe.estimated_calories),
          protein: num(recipe.protein),
          carbs: num(recipe.carbs),
          id: String(recipe.id ?? ""),
        }
      : null,
  };
}

export function parseWeeklyInsightJson(value: unknown): WeeklyInsightJson {
  if (!isObject(value)) throw new Error("invalid_weekly_insight_json");
  return {
    headline: String(value.headline ?? ""),
    insight: String(value.insight ?? ""),
  };
}

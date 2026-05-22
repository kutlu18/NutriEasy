import { serviceClient } from "./auth.ts";
import { loadProgressSummary } from "./progress.ts";
import { loadFastingSummary } from "./fasting.ts";
import { createDailyPlan, getRecipeById, type CatalogRecipe } from "./plan_catalog.ts";
import { promptRegistry } from "./ai/prompts.ts";

type Goal = "weight_loss" | "gain_muscle" | "maintain" | "fasting";
type ActivityLevel = "sedentary" | "light" | "moderate" | "active";

type ProfileRow = {
  selected_goal: Goal | string | null;
  activity_level: ActivityLevel | string | null;
};

export type ChatRole = "user" | "assistant";

export type ChatSuggestionChip = {
  label: string;
  prompt: string;
  kind?: string;
};

export type ChatRecipeCard = {
  recipeId: string;
  title: string;
  subtitle: string;
  mealType: "breakfast" | "lunch" | "dinner" | "snack";
  description: string;
  calories: number;
  proteinGr: number;
  carbsGr: number;
  fatGr: number;
  prepMinutes: number;
  cookMinutes: number;
  servings: number;
  ingredients: { name: string; amount: string; unit: string; note?: string }[];
  steps: string[];
  tags: string[];
};

export type ChatMessage = {
  id: string;
  role: ChatRole;
  text: string;
  createdAt: string;
  suggestionChips?: ChatSuggestionChip[];
  recipeCards?: ChatRecipeCard[];
  quickActions?: string[];
  contextSummary?: string;
};

export type ChatThread = {
  id: string;
  title: string;
  createdAt: string;
  updatedAt: string;
  messages: ChatMessage[];
  suggestionChips: ChatSuggestionChip[];
  recipeCards: ChatRecipeCard[];
  quickActions: string[];
  contextSummary: string;
};

type MealRow = {
  id: string;
  title: string;
  meal_type: string;
  total_calories: number | string | null;
  protein_gr: number | string | null;
  carbs_gr: number | string | null;
  fat_gr: number | string | null;
  logged_at: string;
};

type ChatContext = {
  progress: Awaited<ReturnType<typeof loadProgressSummary>>;
  fasting: Awaited<ReturnType<typeof loadFastingSummary>>;
  recentMeals: MealRow[];
  profile: ProfileRow;
  clientContext?: Record<string, unknown>;
};

type ThreadMetadata = {
  chat?: {
    thread?: ChatThread;
  };
};

function num(value: unknown, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function mealTypeTitle(mealType: ChatRecipeCard["mealType"]) {
  switch (mealType) {
    case "breakfast":
      return "Kahvaltı";
    case "lunch":
      return "Öğle";
    case "dinner":
      return "Akşam";
    case "snack":
    default:
      return "Ara öğün";
  }
}

function asArray<T>(value: T | T[] | undefined): T[] {
  if (!value) return [];
  return Array.isArray(value) ? value : [value];
}

function mealTypeFromIntent(intent: string): ChatRecipeCard["mealType"] {
  switch (intent) {
    case "breakfast":
      return "breakfast";
    case "lunch":
      return "lunch";
    case "dinner":
    case "light_dinner":
      return "dinner";
    case "snack":
      return "snack";
    default:
      return "dinner";
  }
}

function toRecipeCard(recipe: CatalogRecipe): ChatRecipeCard {
  return {
    recipeId: recipe.id,
    title: recipe.title,
    subtitle: recipe.subtitle,
    mealType: recipe.meal_type,
    description: recipe.description,
    calories: recipe.calories,
    proteinGr: recipe.protein_gr,
    carbsGr: recipe.carbs_gr,
    fatGr: recipe.fat_gr,
    prepMinutes: recipe.prep_minutes,
    cookMinutes: recipe.cook_minutes,
    servings: recipe.servings,
    ingredients: recipe.ingredients,
    steps: recipe.steps,
    tags: recipe.tags,
  };
}

function defaultSuggestions(): ChatSuggestionChip[] {
  return [
    { label: "Bugün ne yemeliyim?", prompt: "Bugün ne yemeliyim?" },
    { label: "Bu öğün dengeli mi?", prompt: "Bu öğün dengeli mi?" },
    { label: "Proteinim yeterli mi?", prompt: "Proteinim yeterli mi?" },
    { label: "Hafif akşam öner", prompt: "Hafif akşam öner" },
    { label: "Bu yemek kaç kalori?", prompt: "Bu yemek kaç kalori?" },
  ];
}

function threadTitleForMessage(message: string) {
  const lower = message.toLowerCase();
  if (lower.includes("protein")) return "Protein kontrolü";
  if (lower.includes("akşam")) return "Akşam önerileri";
  if (lower.includes("kalori")) return "Kalori soruları";
  if (lower.includes("dengeli")) return "Öğün değerlendirme";
  return "Nuri sohbeti";
}

function latestMeal(recentMeals: MealRow[]) {
  return recentMeals[0] ?? null;
}

function buildContextSummary(context: ChatContext) {
  const { progress, fasting } = context;
  return `${progress.calorieTarget} kcal hedef • ${progress.consumedCalories} kcal tüketildi • ${fasting.statusLabel}`;
}

function nuriMeta() {
  const prompt = promptRegistry.nuriChat;
  return {
    model: prompt.model,
    prompt_id: prompt.id,
    prompt_version: prompt.version,
    provider: "heuristic",
    latency_ms: 0,
    confidence: "medium",
    fallback_used: true,
  };
}

function buildRecipeCardsForIntent(intent: string, context: ChatContext): ChatRecipeCard[] {
  const plan = createDailyPlan();
  const dinner = getRecipeById("recipe-light-dinner");
  const lunch = getRecipeById("recipe-balanced-lunch");
  const breakfast = getRecipeById("recipe-protein-breakfast");
  const snack = getRecipeById("recipe-simple-snack");

  switch (intent) {
    case "protein":
      return [breakfast, lunch].filter(Boolean).map((item) => toRecipeCard(item!));
    case "light_dinner":
    case "dinner":
      return [dinner, snack].filter(Boolean).map((item) => toRecipeCard(item!));
    case "today":
      return plan.items.slice(0, 3).map(toRecipeCard);
    case "calories":
      return [snack].filter(Boolean).map((item) => toRecipeCard(item!));
    default:
      return plan.items.slice(0, 2).map(toRecipeCard);
  }
}

function detectIntent(message: string): string {
  const lower = message.toLowerCase();
  if (lower.includes("protein")) return "protein";
  if (lower.includes("hafif akşam") || lower.includes("hafif aksam")) return "light_dinner";
  if (lower.includes("akşam") || lower.includes("aksam")) return "dinner";
  if (lower.includes("bugün ne yemeliyim") || lower.includes("bugun ne yemeliyim")) return "today";
  if (lower.includes("kaç kalori") || lower.includes("kac kalori") || lower.includes("kalori")) return "calories";
  if (lower.includes("dengeli")) return "balance";
  if (lower.includes("kahvaltı")) return "breakfast";
  if (lower.includes("öğle")) return "lunch";
  if (lower.includes("ara öğün")) return "snack";
  return "general";
}

function evaluateMealBalance(context: ChatContext) {
  const meal = latestMeal(context.recentMeals);
  if (!meal) {
    return {
      text: "Henüz kaydedilmiş bir öğün görmüyorum. İstersen yazıyla ya da fotoğrafla ilk öğünü birlikte değerlendirelim.",
      recipeCards: buildRecipeCardsForIntent("today", context),
    };
  }

  const progress = context.progress;
  const calories = num(meal.total_calories);
  const protein = num(meal.protein_gr);
  const carbs = num(meal.carbs_gr);
  const fat = num(meal.fat_gr);
  const balanceText =
    calories <= Math.max(650, progress.calorieTarget * 0.35)
      ? "Kalori tarafı makul görünüyor."
      : "Kalori biraz yüksek tarafa kaymış olabilir.";
  const proteinText = protein >= 25 ? "Protein desteği fena değil." : "Protein biraz düşük kalmış olabilir.";
  const macroText = carbs >= fat ? "Karbonhidrat tarafı dengeli." : "Yağ oranı biraz baskın olabilir.";

  return {
    text: `Son öğününü tarttığımda: ${balanceText} ${proteinText} ${macroText} İstersen porsiyonu birlikte ayarlayalım.`,
    recipeCards: buildRecipeCardsForIntent("protein", context),
  };
}

function replyForIntent(intent: string, message: string, context: ChatContext) {
  const progress = context.progress;
  const fasting = context.fasting;
  const meal = latestMeal(context.recentMeals);

  switch (intent) {
    case "protein": {
      const proteinLeft = Math.max(0, progress.macroTargets.proteinGr - progress.consumedMacros.proteinGr);
      return {
        text:
          proteinLeft <= 0
            ? "Bugün protein hedefini doldurmuş görünüyorsun. Akşamı hafif tutup dengeyi korumak mantıklı."
            : `Şu an yaklaşık ${proteinLeft} g protein eksiğin var. Tavuk, yoğurt, yumurta veya baklagil iyi tamamlar.`,
        recipeCards: buildRecipeCardsForIntent("protein", context),
      };
    }
    case "calories":
      return {
        text:
          meal != null
            ? `Bugün hedefin ${progress.calorieTarget} kcal, tüketimin ${progress.consumedCalories} kcal. Son öğünün "${meal.title}" ve yaklaşık ${num(meal.total_calories)} kcal.`
            : `Bugün hedefin ${progress.calorieTarget} kcal, şu ana kadar ${progress.consumedCalories} kcal aldın. İstersen son öğünü de hesaplayalım.`,
        recipeCards: buildRecipeCardsForIntent("calories", context),
      };
    case "light_dinner":
    case "dinner":
      return {
        text:
          fasting.currentState === "active"
            ? "Fasting planın aktif, bu yüzden akşamı hafif ve protein odaklı tutmak iyi olur. Aşağıya güvenli seçenekler bıraktım."
            : "Akşam için hafif, dengeli ve yormayan birkaç seçenek hazırladım.",
        recipeCards: buildRecipeCardsForIntent("light_dinner", context),
      };
    case "today":
      return {
        text: `Bugün için hedefe en yakın yaklaşım, ${progress.calorieBalance > 0 ? "kalori dengesini koruyup" : ""} protein ağırlıklı ve sade öğünlerle ilerlemek. ${fasting.statusLabel} durumuna göre pencereni de dikkate alacağım.`,
        recipeCards: buildRecipeCardsForIntent("today", context),
      };
    case "balance":
      return evaluateMealBalance(context);
    default:
      return {
        text: fasting.currentState === "active"
          ? "Aktif fasting ile ilerliyorsun. İstersen öğününü değerlendirip, planına uygun bir alternatif de çıkarabilirim."
          : "Bugün hangi öğünün üzerine konuşmak istersen onu birlikte netleştirebiliriz. Dilersen mevcut öğününü gönder, dengesiyle birlikte yorumlayayım.",
        recipeCards: buildRecipeCardsForIntent("general", context),
      };
  }
}

function buildAssistantMessage(text: string, context: ChatContext, recipeCards: ChatRecipeCard[]) {
  return {
    id: crypto.randomUUID(),
    role: "assistant" as const,
    text,
    createdAt: new Date().toISOString(),
    suggestionChips: defaultSuggestions(),
    recipeCards,
    quickActions: ["camera", "voice", "food-search"],
    contextSummary: buildContextSummary(context),
  };
}

function buildUserMessage(message: string) {
  return {
    id: crypto.randomUUID(),
    role: "user" as const,
    text: message,
    createdAt: new Date().toISOString(),
  };
}

function normalizeThread(data: Record<string, unknown> | null | undefined): ChatThread | null {
  if (!data) return null;
  const messages = asArray(data.messages as ChatMessage[] | undefined).map((message) => ({
    id: message.id ?? crypto.randomUUID(),
    role: message.role,
    text: message.text,
    createdAt: message.createdAt ?? new Date().toISOString(),
    suggestionChips: asArray(message.suggestionChips),
    recipeCards: asArray(message.recipeCards),
    quickActions: asArray(message.quickActions),
    contextSummary: message.contextSummary,
  }));

  return {
    id: String(data.id ?? crypto.randomUUID()),
    title: String(data.title ?? "Nuri sohbeti"),
    messages,
    suggestionChips: asArray(data.suggestionChips as ChatSuggestionChip[] | undefined),
    recipeCards: asArray(data.recipeCards as ChatRecipeCard[] | undefined),
    quickActions: asArray(data.quickActions as string[] | undefined),
    contextSummary: String(data.contextSummary ?? ""),
    createdAt: String(data.createdAt ?? new Date().toISOString()),
    updatedAt: String(data.updatedAt ?? new Date().toISOString()),
  };
}

async function getFreshUser(userId: string) {
  const supabase = serviceClient();
  const { data, error } = await supabase.auth.admin.getUserById(userId);
  if (error) throw error;
  if (!data.user) throw new Error("user_not_found");
  return data.user as { id: string; app_metadata?: Record<string, unknown> | null; email?: string | null };
}

async function getProfile(userId: string) {
  const supabase = serviceClient();
  const { data, error } = await supabase
    .from("user_profiles")
    .select("selected_goal,activity_level")
    .eq("id", userId)
    .maybeSingle();
  if (error) throw error;
  return data ?? { selected_goal: "weight_loss", activity_level: "light" };
}

async function getRecentMeals(userId: string) {
  const supabase = serviceClient();
  const { data, error } = await supabase
    .from("meals")
    .select("id,title,meal_type,total_calories,protein_gr,carbs_gr,fat_gr,logged_at")
    .eq("user_id", userId)
    .order("logged_at", { ascending: false })
    .limit(10);
  if (error) throw error;
  return (data ?? []) as MealRow[];
}

function getThreadFromMetadata(metadata: Record<string, unknown> | null | undefined) {
  const chat = (metadata?.chat as { thread?: Record<string, unknown> } | undefined)?.thread ?? null;
  return normalizeThread(chat);
}

async function persistThread(userId: string, thread: ChatThread) {
  const supabase = serviceClient();
  const { data, error: loadError } = await supabase.auth.admin.getUserById(userId);
  if (loadError) throw loadError;
  const currentMetadata = data.user?.app_metadata ?? {};

  const { error } = await supabase.auth.admin.updateUserById(userId, {
    app_metadata: {
      ...currentMetadata,
      chat: {
        thread,
      },
    },
  });

  if (error) throw error;
}

async function buildContext(userId: string, user: { id: string; app_metadata?: Record<string, unknown> | null; email?: string | null }, clientContext?: Record<string, unknown>): Promise<ChatContext> {
  const profile = await getProfile(userId);
  const [progress, fasting, recentMeals] = await Promise.all([
    loadProgressSummary(userId),
    loadFastingSummary({ ...user, app_metadata: user.app_metadata ?? undefined }, profile),
    getRecentMeals(userId),
  ]);

  return {
    progress,
    fasting,
    recentMeals,
    profile,
    clientContext,
  };
}

export async function loadChatThread(userId: string, clientContext?: Record<string, unknown>) {
  const freshUser = await getFreshUser(userId);
  const metadata = freshUser.app_metadata ?? {};
  const thread = getThreadFromMetadata(metadata);
  const context = await buildContext(userId, freshUser, clientContext);

  if (thread) {
    return {
      thread: {
        ...thread,
        suggestionChips: thread.suggestionChips.length > 0 ? thread.suggestionChips : defaultSuggestions(),
        recipeCards: thread.recipeCards.length > 0 ? thread.recipeCards : buildRecipeCardsForIntent("general", context),
        quickActions: thread.quickActions.length > 0 ? thread.quickActions : ["camera", "voice", "food-search"],
        contextSummary: thread.contextSummary || buildContextSummary(context),
      },
      context,
    };
  }

  const starterMessage = buildAssistantMessage(
    "Merhaba, ben Nuri. Bugün ne yemeliyim, proteinim yeterli mi ya da hafif akşam öner gibi sorularla yardımcı olabilirim.",
    context,
    buildRecipeCardsForIntent("today", context),
  );

  const starterThread: ChatThread = {
    id: crypto.randomUUID(),
    title: "Nuri sohbeti",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    messages: [starterMessage],
    suggestionChips: defaultSuggestions(),
    recipeCards: starterMessage.recipeCards ?? [],
    quickActions: ["camera", "voice", "food-search"],
    contextSummary: buildContextSummary(context),
  };

  await persistThread(userId, starterThread);
  return { thread: starterThread, context, meta: nuriMeta() };
}

export async function sendChatMessage(userId: string, message: string, clientContext?: Record<string, unknown>) {
  const freshUser = await getFreshUser(userId);
  const context = await buildContext(userId, freshUser, clientContext);
  const { thread } = await loadChatThread(userId, clientContext);

  const userMessage = buildUserMessage(message);
  const intent = detectIntent(message);
  const response = replyForIntent(intent, message, context);
  const assistantMessage = buildAssistantMessage(response.text, context, response.recipeCards);
  const threadTitle = thread.messages.length <= 1 ? threadTitleForMessage(message) : thread.title;

  const updatedThread: ChatThread = {
    ...thread,
    title: threadTitle,
    messages: [...thread.messages, userMessage, assistantMessage].slice(-20),
    suggestionChips: response.recipeCards.length > 0 ? defaultSuggestions() : thread.suggestionChips,
    recipeCards: response.recipeCards,
    quickActions: assistantMessage.quickActions ?? ["camera", "voice", "food-search"],
    contextSummary: buildContextSummary(context),
    updatedAt: new Date().toISOString(),
  };

  await persistThread(userId, updatedThread);
  return { thread: updatedThread, context, meta: nuriMeta() };
}

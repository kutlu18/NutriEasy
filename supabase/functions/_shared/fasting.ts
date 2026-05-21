import { serviceClient } from "./auth.ts";

type Goal = "weight_loss" | "gain_muscle" | "maintain" | "fasting";
type ActivityLevel = "sedentary" | "light" | "moderate" | "active";
type FastingState = "idle" | "ready" | "active" | "broken" | "completed";
type FastingPhase = "fed" | "early_fast" | "fat_burning" | "deep_fast" | "recovery";
type FastingSessionStatus = "planned" | "active" | "completed" | "cancelled";

export type FastingPlan = {
  enabled: boolean;
  targetHours: number;
  windowStart: string;
  windowEnd: string;
  label: string;
  notes?: string;
};

export type FastingSession = {
  id: string;
  status: FastingSessionStatus;
  targetHours: number;
  plannedStartAt: string;
  plannedEndAt: string;
  startedAt?: string;
  endedAt?: string;
  actualDurationMinutes?: number;
  metabolicPhase: FastingPhase;
  fastingWindowStart: string;
  fastingWindowEnd: string;
  lastMealAt?: string;
  lastMealTitle?: string;
  lastMealCalories?: number;
  breakReason?: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
};

export type FastingSummary = {
  plan: FastingPlan;
  currentSession?: FastingSession;
  history: FastingSession[];
  currentState: FastingState;
  statusLabel: string;
  statusDetail: string;
  metabolicPhase: FastingPhase;
  metabolicPhaseLabel: string;
  metabolicPhaseDetail: string;
  timerLabel: string;
  progress: number;
  fastedMinutes: number;
  remainingMinutes: number;
  mealSinceStartCount: number;
  weeklyInsight: string;
  achievements: string[];
  isEmpty: boolean;
};

type MealRow = {
  id: string;
  title: string;
  total_calories: number | string | null;
  logged_at: string;
};

type ProfileRow = {
  selected_goal: Goal | string | null;
  activity_level: ActivityLevel | string | null;
};

type FastingMetadata = {
  plan?: Partial<FastingPlan>;
  sessions?: Partial<FastingSession>[];
};

const DEFAULT_PLAN: FastingPlan = {
  enabled: false,
  targetHours: 16,
  windowStart: "20:00",
  windowEnd: "12:00",
  label: "16:8",
};

function asNumber(value: unknown, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}

function minutesBetween(startIso?: string, endIso?: string) {
  if (!startIso || !endIso) return 0;
  const start = new Date(startIso).getTime();
  const end = new Date(endIso).getTime();
  if (!Number.isFinite(start) || !Number.isFinite(end)) return 0;
  return Math.max(0, Math.round((end - start) / 60000));
}

function currentLabel(now = new Date()) {
  return now.toISOString();
}

function computePlan(profile: ProfileRow, metadata?: Partial<FastingPlan>): FastingPlan {
  const goal = (profile.selected_goal ?? "weight_loss") as Goal;
  const activityLevel = (profile.activity_level ?? "light") as ActivityLevel;
  const active = activityLevel === "active";

  const inferred = switchGoal(goal, active);
  return {
    enabled: metadata?.enabled ?? inferred.enabled,
    targetHours: clamp(asNumber(metadata?.targetHours, inferred.targetHours), 12, 24),
    windowStart: metadata?.windowStart ?? inferred.windowStart,
    windowEnd: metadata?.windowEnd ?? inferred.windowEnd,
    label: metadata?.label ?? inferred.label,
    notes: metadata?.notes,
  };
}

function switchGoal(goal: Goal, active: boolean): FastingPlan {
  switch (goal) {
    case "gain_muscle":
      return {
        enabled: true,
        targetHours: active ? 14 : 16,
        windowStart: "21:00",
        windowEnd: "11:00",
        label: active ? "14:10" : "16:8",
      };
    case "maintain":
      return {
        enabled: true,
        targetHours: active ? 15 : 16,
        windowStart: "20:30",
        windowEnd: "12:30",
        label: active ? "15:9" : "16:8",
      };
    case "fasting":
      return {
        enabled: true,
        targetHours: active ? 16 : 18,
        windowStart: "20:00",
        windowEnd: "12:00",
        label: active ? "16:8" : "18:6",
      };
    case "weight_loss":
    default:
      return {
        enabled: true,
        targetHours: active ? 16 : 18,
        windowStart: "20:00",
        windowEnd: "12:00",
        label: active ? "16:8" : "18:6",
      };
  }
}

function normalizeSession(data: Record<string, unknown>): FastingSession {
  const startedAt = data["startedAt"] ?? data["started_at"];
  const endedAt = data["endedAt"] ?? data["ended_at"];

  return {
    id: String(data["id"] ?? crypto.randomUUID()),
    status: (data["status"] as FastingSessionStatus) ?? "planned",
    targetHours: clamp(asNumber(data["targetHours"] ?? data["target_hours"], 16), 12, 24),
    plannedStartAt: String(data["plannedStartAt"] ?? data["planned_start_at"] ?? currentLabel()),
    plannedEndAt: String(data["plannedEndAt"] ?? data["planned_end_at"] ?? currentLabel()),
    startedAt: startedAt ? String(startedAt) : undefined,
    endedAt: endedAt ? String(endedAt) : undefined,
    actualDurationMinutes: (data["actualDurationMinutes"] as number | undefined) ?? (data["actual_duration_minutes"] as number | undefined),
    metabolicPhase: (data["metabolicPhase"] ?? data["metabolic_phase"] ?? "fed") as FastingPhase,
    fastingWindowStart: String(data["fastingWindowStart"] ?? data["fasting_window_start"] ?? "20:00"),
    fastingWindowEnd: String(data["fastingWindowEnd"] ?? data["fasting_window_end"] ?? "12:00"),
    lastMealAt: (data["lastMealAt"] as string | undefined) ?? (data["last_meal_at"] as string | undefined),
    lastMealTitle: (data["lastMealTitle"] as string | undefined) ?? (data["last_meal_title"] as string | undefined),
    lastMealCalories: (data["lastMealCalories"] as number | undefined) ?? (data["last_meal_calories"] as number | undefined),
    breakReason: (data["breakReason"] as string | undefined) ?? (data["break_reason"] as string | undefined),
    notes: data["notes"] as string | undefined,
    createdAt: String(data["createdAt"] ?? data["created_at"] ?? currentLabel()),
    updatedAt: String(data["updatedAt"] ?? data["updated_at"] ?? currentLabel()),
  };
}

function normalizeMetadata(metadata: Record<string, unknown> | null | undefined) {
  const fasting = (metadata?.fasting as FastingMetadata | undefined) ?? {};
  return {
    plan: fasting.plan ?? {},
    sessions: Array.isArray(fasting.sessions) ? fasting.sessions : [],
  };
}

function calculatePhase(minutes: number): FastingPhase {
  if (minutes < 0) return "fed";
  if (minutes < 240) return "early_fast";
  if (minutes < 720) return "fat_burning";
  if (minutes < 1080) return "deep_fast";
  return "recovery";
}

function phaseTitle(phase: FastingPhase) {
  switch (phase) {
    case "early_fast":
      return "Erken açlık";
    case "fat_burning":
      return "Yağ kullanımına geçiş";
    case "deep_fast":
      return "Derin oruç";
    case "recovery":
      return "Yeniden beslenme";
    case "fed":
    default:
      return "Beslenme penceresi";
  }
}

function phaseDetail(phase: FastingPhase) {
  switch (phase) {
    case "early_fast":
      return "Son öğünden sonra vücut önce glikozu kullanıyor, sonra daha sakin bir açlık moduna geçiyor.";
    case "fat_burning":
      return "Enerji dengesi artık yağ kullanımına daha çok yaslanıyor, iştah da daha stabil hissedilebilir.";
    case "deep_fast":
      return "Oruç derinleşiyor; su, elektrolit ve net hedef takibi önemli.";
    case "recovery":
      return "Oruç kapandıktan sonra kontrollü yeniden beslenme daha dengeli hissettirir.";
    case "fed":
    default:
      return "Henüz oruç başlamadı ya da beslenme penceresi açık.";
  }
}

function insightForSummary(params: {
  currentState: FastingState;
  plan: FastingPlan;
  currentSession?: FastingSession;
  history: FastingSession[];
  mealSinceStartCount: number;
  fastedMinutes: number;
}) {
  const { currentState, plan, currentSession, history, mealSinceStartCount, fastedMinutes } = params;
  const streak = history.filter((item) => item.status === "completed").length;
  const hours = Math.floor(fastedMinutes / 60);
  const minutes = fastedMinutes % 60;

  if (!plan.enabled) {
    return "Fasting planin kapali. Istersen bir zaman penceresi tanimlayip baslatabiliriz.";
  }

  if (currentState === "active" && currentSession) {
    const mealText =
      mealSinceStartCount > 0
        ? "Oruç başlangıcından sonra öğün kaydı var; istersen oturumu kapatıp yeni planla yeniden başlayabiliriz."
        : "Henüz orucu bozan bir öğün görünmüyor.";

    return `Aktif oruç ${hours} saat ${minutes} dakika sürdü. ${mealText}`;
  }

  if (currentState === "broken" && currentSession) {
    return `Oruç ${hours} saat ${minutes} dakikada durmuş görünüyor. Son oturumda kaydedilen öğün, yeniden başlama için iyi bir işaret olabilir.`;
  }

  if (streak > 0) {
    return `${streak} tamamlanmış oturum var. Düzenli açlık penceresi, haftalık kalori dengesini daha okunur hale getiriyor.`;
  }

  return `Plan hazır: ${plan.label}. Ilk oturum başladığında faz ve süre birlikte izlenecek.`;
}

function buildAchievements(currentState: FastingState, history: FastingSession[]) {
  const completed = history.filter((item) => item.status === "completed");
  const achievements: string[] = [];

  if (completed.length >= 3) {
    achievements.push(`${completed.length} tamamlanmış fasting oturumu`);
  }

  if (currentState === "active") {
    achievements.push("Aktif oruç takibi açık");
  }

  if (achievements.length === 0) {
    achievements.push("İlk fasting oturumu için hazır");
  }

  return achievements;
}

async function saveMetadata(userId: string, fasting: FastingMetadata) {
  const supabase = serviceClient();
  const { data, error: loadError } = await supabase.auth.admin.getUserById(userId);
  if (loadError) throw loadError;
  const currentMetadata = data.user?.app_metadata ?? {};
  const { error } = await supabase.auth.admin.updateUserById(userId, {
    app_metadata: {
      ...currentMetadata,
      fasting,
    },
  });
  if (error) throw error;
}

async function getFreshUser(userId: string) {
  const supabase = serviceClient();
  const { data, error } = await supabase.auth.admin.getUserById(userId);
  if (error) throw error;
  if (!data.user) {
    throw new Error("user_not_found");
  }
  return data.user as { id: string; app_metadata?: Record<string, unknown> | null };
}

async function loadMealRows(userId: string, sinceIso?: string) {
  const supabase = serviceClient();
  let query = supabase
    .from("meals")
    .select("id,title,total_calories,logged_at")
    .eq("user_id", userId)
    .order("logged_at", { ascending: false });

  if (sinceIso) {
    query = query.gte("logged_at", sinceIso);
  }

  const { data, error } = await query;
  if (error) throw error;
  return (data ?? []) as MealRow[];
}

export async function loadFastingSummary(user: { id: string; app_metadata?: Record<string, unknown>; user_metadata?: Record<string, unknown>; }, profile: ProfileRow) {
  const freshUser = await getFreshUser(user.id);
  const metadata = normalizeMetadata(freshUser.app_metadata);
  const plan = computePlan(profile, metadata.plan);
  const sessions = (metadata.sessions ?? []).map(normalizeSession).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  const currentSession = sessions.find((session) => session.status === "active");

  let mealsSinceStart = [] as MealRow[];
  let fastedMinutes = 0;
  let remainingMinutes = 0;
  let currentState: FastingState = plan.enabled ? "ready" : "idle";
  let metabolicPhase: FastingPhase = "fed";
  let timerLabel = "00s 00dk";
  let mealSinceStartCount = 0;
  let statusLabel = plan.enabled ? "Başlamaya hazır" : "Plan kapalı";
  let statusDetail = plan.enabled
    ? `Plan ${plan.label} olarak ayarlı. ${plan.windowStart} - ${plan.windowEnd} penceresi hazır.`
    : "Fasting planı kapalı; istersen buradan açabiliriz.";
  let metabolicPhaseLabel = phaseTitle("fed");
  let metabolicPhaseDetail = phaseDetail("fed");

  if (currentSession?.startedAt) {
    mealsSinceStart = await loadMealRows(user.id, currentSession.startedAt);
    mealSinceStartCount = mealsSinceStart.length;
    const startedAt = new Date(currentSession.startedAt).getTime();
    const reference = currentSession.endedAt ? new Date(currentSession.endedAt).getTime() : Date.now();
    fastedMinutes = Math.max(0, Math.round((reference - startedAt) / 60000));
    remainingMinutes = currentSession.endedAt
      ? 0
      : Math.max(0, Math.round((new Date(currentSession.plannedEndAt).getTime() - Date.now()) / 60000));
    metabolicPhase = calculatePhase(fastedMinutes);
    timerLabel = `${Math.floor(fastedMinutes / 60)}s ${fastedMinutes % 60}dk`;

    if (currentSession.status === "active" && mealSinceStartCount > 0) {
      currentState = "broken";
      statusLabel = "Oruç bozuldu";
      statusDetail = `Başlangıçtan sonra ${mealSinceStartCount} öğün görünuyor. İstersen oturumu kapatıp yeniden başlayabiliriz.`;
    } else if (currentSession.status === "active") {
      currentState = "active";
      statusLabel = "Aktif oruç";
      statusDetail = remainingMinutes > 0
        ? `${Math.floor(remainingMinutes / 60)}s ${remainingMinutes % 60}dk kaldı.`
        : "Planlı oruç süresi tamamlandı; istersen bitirebiliriz.";
    } else if (currentSession.status === "completed") {
      currentState = "completed";
      statusLabel = "Son oturum tamamlandı";
      statusDetail = `Toplam ${Math.floor(fastedMinutes / 60)}s ${fastedMinutes % 60}dk sürdü.`;
    }

    metabolicPhaseLabel = phaseTitle(currentState === "broken" ? "recovery" : metabolicPhase);
    metabolicPhaseDetail = phaseDetail(currentState === "broken" ? "recovery" : metabolicPhase);
  }

  const progress = currentSession?.startedAt && currentSession?.plannedEndAt
    ? clamp(fastedMinutes / Math.max(1, plan.targetHours * 60), 0, 1)
    : 0;

  const history = sessions.filter((session) => session.status !== "active").slice(0, 10);

  return {
    plan,
    currentSession,
    history,
    currentState,
    statusLabel,
    statusDetail,
    metabolicPhase,
    metabolicPhaseLabel,
    metabolicPhaseDetail,
    timerLabel,
    progress,
    fastedMinutes,
    remainingMinutes,
    mealSinceStartCount,
    weeklyInsight: insightForSummary({
      currentState,
      plan,
      currentSession,
      history,
      mealSinceStartCount,
      fastedMinutes,
    }),
    achievements: buildAchievements(currentState, history),
    isEmpty: !plan.enabled && history.length === 0 && !currentSession,
  };
}

export async function updateFastingPlan(user: { id: string; app_metadata?: Record<string, unknown>; user_metadata?: Record<string, unknown>; }, planPatch: Partial<FastingPlan>) {
  const metadata = normalizeMetadata(user.app_metadata ?? user.user_metadata);
  const mergedPlan: FastingPlan = {
    enabled: planPatch.enabled ?? metadata.plan?.enabled ?? DEFAULT_PLAN.enabled,
    targetHours: clamp(asNumber(planPatch.targetHours ?? metadata.plan?.targetHours ?? DEFAULT_PLAN.targetHours, DEFAULT_PLAN.targetHours), 12, 24),
    windowStart: planPatch.windowStart ?? metadata.plan?.windowStart ?? DEFAULT_PLAN.windowStart,
    windowEnd: planPatch.windowEnd ?? metadata.plan?.windowEnd ?? DEFAULT_PLAN.windowEnd,
    label: planPatch.label ?? metadata.plan?.label ?? `${clamp(asNumber(planPatch.targetHours ?? metadata.plan?.targetHours ?? DEFAULT_PLAN.targetHours, DEFAULT_PLAN.targetHours), 12, 24)}:${Math.max(0, 24 - clamp(asNumber(planPatch.targetHours ?? metadata.plan?.targetHours ?? DEFAULT_PLAN.targetHours, DEFAULT_PLAN.targetHours), 12, 24))}`,
    notes: planPatch.notes ?? metadata.plan?.notes,
  };

  await saveMetadata(user.id, {
    ...metadata,
    plan: mergedPlan,
  });

  return mergedPlan;
}

export async function startFastingSession(user: { id: string; app_metadata?: Record<string, unknown>; user_metadata?: Record<string, unknown>; }, profile: ProfileRow) {
  const metadata = normalizeMetadata(user.app_metadata ?? user.user_metadata);
  const plan = computePlan(profile, metadata.plan);
  const sessions = (metadata.sessions ?? []).map(normalizeSession);
  const existingActive = sessions.find((session) => session.status === "active");
  if (existingActive) {
    return existingActive;
  }

  const now = new Date();
  const plannedEndAt = new Date(now.getTime() + plan.targetHours * 60 * 60 * 1000);
  const session: FastingSession = {
    id: crypto.randomUUID(),
    status: "active",
    targetHours: plan.targetHours,
    plannedStartAt: now.toISOString(),
    plannedEndAt: plannedEndAt.toISOString(),
    startedAt: now.toISOString(),
    metabolicPhase: "early_fast",
    fastingWindowStart: plan.windowStart,
    fastingWindowEnd: plan.windowEnd,
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
  };

  const updatedSessions = [session, ...sessions].slice(0, 20);
  await saveMetadata(user.id, {
    plan,
    sessions: updatedSessions,
  });

  return session;
}

export async function endFastingSession(user: { id: string; app_metadata?: Record<string, unknown>; user_metadata?: Record<string, unknown>; }, profile: ProfileRow, breakReason?: string) {
  const metadata = normalizeMetadata(user.app_metadata ?? user.user_metadata);
  const plan = computePlan(profile, metadata.plan);
  const sessions = (metadata.sessions ?? []).map(normalizeSession);
  const activeIndex = sessions.findIndex((session) => session.status === "active");

  if (activeIndex === -1) {
    return null;
  }

  const active = sessions[activeIndex];
  const now = new Date();
  const updated: FastingSession = {
    ...active,
    status: breakReason ? "cancelled" : "completed",
    endedAt: now.toISOString(),
    actualDurationMinutes: minutesBetween(active.startedAt, now.toISOString()),
    metabolicPhase: breakReason ? "recovery" : calculatePhase(minutesBetween(active.startedAt, now.toISOString())),
    breakReason,
    updatedAt: now.toISOString(),
  };

  sessions[activeIndex] = updated;
  await saveMetadata(user.id, {
    plan,
    sessions: sessions.slice(0, 20),
  });

  return updated;
}

export async function loadFastingHistory(user: { id: string; app_metadata?: Record<string, unknown>; user_metadata?: Record<string, unknown>; }, profile: ProfileRow) {
  const freshUser = await getFreshUser(user.id);
  const metadata = normalizeMetadata(freshUser.app_metadata);
  const plan = computePlan(profile, metadata.plan);
  const sessions = (metadata.sessions ?? []).map(normalizeSession).filter((session) => session.status !== "active");
  const summary = await loadFastingSummary(user, profile);
  return {
    plan,
    history: sessions.slice(0, 20),
    summary,
  };
}

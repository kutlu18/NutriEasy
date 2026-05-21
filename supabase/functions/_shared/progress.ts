import { serviceClient } from "./auth.ts";

type Goal = "weight_loss" | "gain_muscle" | "maintain" | "fasting";
type ActivityLevel = "sedentary" | "light" | "moderate" | "active";

type MealRow = {
  id: string;
  meal_type: string;
  total_calories: number | string | null;
  protein_gr: number | string | null;
  carbs_gr: number | string | null;
  fat_gr: number | string | null;
  logged_at: string;
};

type ProfileRow = {
  id: string;
  weight_kg: number | string | null;
  target_weight_kg: number | string | null;
  selected_goal: Goal | string | null;
  activity_level: ActivityLevel | string | null;
};

type ProgressTrendPoint = {
  date: string;
  weightKg: number;
  caloriesConsumed: number;
  calorieTarget: number;
};

type ProgressSummary = {
  weekStart: string;
  weekEnd: string;
  calorieTarget: number;
  consumedCalories: number;
  calorieBalance: number;
  macroTargets: { proteinGr: number; carbsGr: number; fatGr: number };
  consumedMacros: { proteinGr: number; carbsGr: number; fatGr: number };
  currentWeightKg: number;
  targetWeightKg: number;
  estimatedWeightDeltaKg: number;
  streakDays: number;
  hydrationCurrent: number;
  hydrationTarget: number;
  stepsCurrent: number;
  stepsTarget: number;
  mealCount: number;
  weightTrend: ProgressTrendPoint[];
  achievements: string[];
  weeklyInsight: string;
  isEmpty: boolean;
  source: string;
};

function startOfDay(date: Date) {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function addDays(date: Date, days: number) {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

function toDayKey(date: Date) {
  return date.toISOString().slice(0, 10);
}

function num(value: unknown, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function profileTargets(goal: Goal, activityLevel: ActivityLevel) {
  const active = activityLevel === "active";

  switch (goal) {
    case "gain_muscle":
      return {
        calorieTarget: active ? 2450 : 2250,
        macroTargets: { proteinGr: 160 * 7, carbsGr: 220 * 7, fatGr: 70 * 7 },
      };
    case "maintain":
      return {
        calorieTarget: active ? 2200 : 2000,
        macroTargets: { proteinGr: 125 * 7, carbsGr: 190 * 7, fatGr: 65 * 7 },
      };
    case "fasting":
      return {
        calorieTarget: 1700,
        macroTargets: { proteinGr: 120 * 7, carbsGr: 140 * 7, fatGr: 60 * 7 },
      };
    case "weight_loss":
    default:
      return {
        calorieTarget: active ? 1900 : 1750,
        macroTargets: { proteinGr: 130 * 7, carbsGr: 150 * 7, fatGr: 55 * 7 },
      };
  }
}

function estimateHydration(mealCount: number, streakDays: number) {
  return Math.max(3, Math.min(8, 3 + mealCount + Math.floor(streakDays / 2)));
}

function stepsTargetForActivity(activityLevel: ActivityLevel) {
  switch (activityLevel) {
    case "sedentary":
      return 6000;
    case "light":
      return 7500;
    case "moderate":
      return 9000;
    case "active":
    default:
      return 10500;
  }
}

function estimateSteps(activityLevel: ActivityLevel, mealCount: number, streakDays: number, calorieAverage: number) {
  const baseline = {
    sedentary: 4200,
    light: 5600,
    moderate: 6800,
    active: 8200,
  }[activityLevel];
  const value = baseline + mealCount * 350 + streakDays * 120 + Math.round(calorieAverage / 2);
  return Math.max(3000, value);
}

function buildAchievements(
  streakDays: number,
  consumedMacros: { proteinGr: number; carbsGr: number; fatGr: number },
  macroTargets: { proteinGr: number; carbsGr: number; fatGr: number },
  calorieBalance: number,
) {
  const achievements: string[] = [];

  if (streakDays >= 3) {
    achievements.push(`${streakDays} gunluk kayit serisi`);
  }

  const proteinRatio = macroTargets.proteinGr === 0 ? 0 : consumedMacros.proteinGr / macroTargets.proteinGr;
  if (proteinRatio >= 0.8) {
    achievements.push("Protein hedefinin %80+ seviyesine ulastin");
  }

  if (Math.abs(calorieBalance) <= 250) {
    achievements.push("Kalori dengesi hedefe yakin");
  }

  if (achievements.length === 0) {
    achievements.push("Bu hafta duzenli takip icin iyi bir baslangic var");
  }

  return achievements;
}

function buildWeeklyInsight(
  weeklyConsumed: number,
  weeklyTarget: number,
  consumedMacros: { proteinGr: number; carbsGr: number; fatGr: number },
  macroTargets: { proteinGr: number; carbsGr: number; fatGr: number },
  streakDays: number,
  estimatedDeltaKg: number,
) {
  const caloriesGap = weeklyTarget - weeklyConsumed;
  const proteinRatio = macroTargets.proteinGr === 0 ? 0 : consumedMacros.proteinGr / macroTargets.proteinGr;
  const calorieLine =
    caloriesGap >= 0
      ? `Bu hafta kalori dengesi hedefe yakin; gunluk ortalama ${Math.max(0, Math.round(caloriesGap / 7))} kcal acik var.`
      : `Bu hafta hedefin uzerine cikilmis; gunluk ortalama ${Math.abs(Math.round(caloriesGap / 7))} kcal fazla gorunuyor.`;
  const proteinLine =
    proteinRatio >= 0.8
      ? "Protein tarafi guclu ilerliyor."
      : "Protein miktarini biraz artirmak hedefe daha hizli yaklastirir.";
  const streakLine =
    streakDays >= 3
      ? "Serin tutarlı gidiyor."
      : "Bir kac gunluk duzenli kayit, trendi daha net hale getirir.";
  const weightLine =
    estimatedDeltaKg >= 0
      ? `Mevcut gidişat tahmini olarak ${estimatedDeltaKg.toFixed(1)} kg kayip potansiyeli gosteriyor.`
      : `Mevcut gidişat tahmini olarak ${Math.abs(estimatedDeltaKg).toFixed(1)} kg artis tarafinda.`;

  return `${calorieLine} ${proteinLine} ${streakLine} ${weightLine}`;
}

function calculateStreakDays(daysWithMeals: Set<string>) {
  const today = startOfDay(new Date());
  let streak = 0;

  for (let offset = 0; offset < 30; offset += 1) {
    const day = toDayKey(addDays(today, -offset));
    if (!daysWithMeals.has(day)) break;
    streak += 1;
  }

  return streak;
}

function buildProgressSummary(profile: ProfileRow, meals: MealRow[]): ProgressSummary {
  const now = new Date();
  const weekEnd = startOfDay(now);
  const weekStart = addDays(weekEnd, -6);

  const targetGoal = (profile.selected_goal ?? "weight_loss") as Goal;
  const activityLevel = (profile.activity_level ?? "light") as ActivityLevel;
  const { calorieTarget, macroTargets } = profileTargets(targetGoal, activityLevel);

  const weeklyMeals = meals.filter((meal) => {
    const logged = startOfDay(new Date(meal.logged_at));
    return logged >= weekStart && logged <= weekEnd;
  });

  const caloriesByDay = new Map<string, number>();
  const macrosByDay = new Map<string, { proteinGr: number; carbsGr: number; fatGr: number }>();
  const daysWithMeals = new Set<string>();

  for (const meal of weeklyMeals) {
    const day = toDayKey(startOfDay(new Date(meal.logged_at)));
    daysWithMeals.add(day);
    caloriesByDay.set(day, (caloriesByDay.get(day) ?? 0) + num(meal.total_calories));

    const current = macrosByDay.get(day) ?? { proteinGr: 0, carbsGr: 0, fatGr: 0 };
    macrosByDay.set(day, {
      proteinGr: current.proteinGr + num(meal.protein_gr),
      carbsGr: current.carbsGr + num(meal.carbs_gr),
      fatGr: current.fatGr + num(meal.fat_gr),
    });
  }

  const weeklyConsumed = [...caloriesByDay.values()].reduce((sum, value) => sum + value, 0);
  const weeklyTarget = calorieTarget * 7;
  const weeklyBalance = weeklyTarget - weeklyConsumed;

  const consumedMacros = [...macrosByDay.values()].reduce(
    (sum, value) => ({
      proteinGr: sum.proteinGr + value.proteinGr,
      carbsGr: sum.carbsGr + value.carbsGr,
      fatGr: sum.fatGr + value.fatGr,
    }),
    { proteinGr: 0, carbsGr: 0, fatGr: 0 },
  );

  const currentWeightKg = num(profile.weight_kg, 78);
  const targetWeightKg = num(profile.target_weight_kg, currentWeightKg);
  const estimatedWeightDeltaKg = weeklyBalance / 7700;
  const startingWeight = currentWeightKg - estimatedWeightDeltaKg;

  const weightTrend = Array.from({ length: 7 }, (_, index) => {
    const day = addDays(weekStart, index);
    const dailyConsumed = caloriesByDay.get(toDayKey(day)) ?? 0;
    const balanceToDay = Array.from(caloriesByDay.entries())
      .filter(([key]) => key <= toDayKey(day))
      .reduce((sum, [, value]) => sum + (calorieTarget - value), 0);

    return {
      date: day.toISOString(),
      weightKg: startingWeight + balanceToDay / 7700,
      caloriesConsumed: dailyConsumed,
      calorieTarget,
    };
  });

  const streakDays = calculateStreakDays(daysWithMeals);
  const mealCount = weeklyMeals.length;
  const hydrationTarget = 8;
  const hydrationCurrent = estimateHydration(mealCount, streakDays);
  const stepsTarget = stepsTargetForActivity(activityLevel);
  const stepsCurrent = estimateSteps(activityLevel, mealCount, streakDays, weeklyConsumed / 7);

  return {
    weekStart: weekStart.toISOString(),
    weekEnd: weekEnd.toISOString(),
    calorieTarget: weeklyTarget,
    consumedCalories: weeklyConsumed,
    calorieBalance: weeklyBalance,
    macroTargets,
    consumedMacros,
    currentWeightKg,
    targetWeightKg,
    estimatedWeightDeltaKg,
    streakDays,
    hydrationCurrent,
    hydrationTarget,
    stepsCurrent,
    stepsTarget,
    mealCount,
    weightTrend,
    achievements: buildAchievements(streakDays, consumedMacros, macroTargets, weeklyBalance),
    weeklyInsight: buildWeeklyInsight(weeklyConsumed, weeklyTarget, consumedMacros, macroTargets, streakDays, estimatedWeightDeltaKg),
    isEmpty: weeklyMeals.length === 0,
    source: "backend-calculated",
  };
}

export async function loadProgressSummary(userId: string) {
  const supabase = serviceClient();

  const [{ data: profileData }, { data: mealData }] = await Promise.all([
    supabase
      .from("user_profiles")
      .select("id,weight_kg,target_weight_kg,selected_goal,activity_level")
      .eq("id", userId)
      .maybeSingle(),
    supabase
      .from("meals")
      .select("id,meal_type,total_calories,protein_gr,carbs_gr,fat_gr,logged_at")
      .eq("user_id", userId)
      .order("logged_at", { ascending: true }),
  ]);

  const profile = profileData ?? {
    id: userId,
    weight_kg: 78,
    target_weight_kg: 72,
    selected_goal: "weight_loss",
    activity_level: "light",
  };

  return buildProgressSummary(profile, (mealData ?? []) as MealRow[]);
}

export function selectProgressMetric(summary: ProgressSummary, metric: string) {
  switch (metric) {
    case "calories":
    case "calorie_balance":
      return {
        key: "calorie_balance",
        label: "Kalori dengesi",
        current: summary.consumedCalories,
        target: summary.calorieTarget,
        change: summary.calorieBalance,
        unit: "kcal",
        progress: summary.calorieTarget === 0 ? 0 : Math.min(1, summary.consumedCalories / summary.calorieTarget),
        estimated: false,
      };
    case "protein":
      return {
        key: "protein",
        label: "Protein",
        current: summary.consumedMacros.proteinGr,
        target: summary.macroTargets.proteinGr,
        change: summary.macroTargets.proteinGr - summary.consumedMacros.proteinGr,
        unit: "g",
        progress: summary.macroTargets.proteinGr === 0 ? 0 : Math.min(1, summary.consumedMacros.proteinGr / summary.macroTargets.proteinGr),
        estimated: false,
      };
    case "carbs":
      return {
        key: "carbs",
        label: "Karbonhidrat",
        current: summary.consumedMacros.carbsGr,
        target: summary.macroTargets.carbsGr,
        change: summary.macroTargets.carbsGr - summary.consumedMacros.carbsGr,
        unit: "g",
        progress: summary.macroTargets.carbsGr === 0 ? 0 : Math.min(1, summary.consumedMacros.carbsGr / summary.macroTargets.carbsGr),
        estimated: false,
      };
    case "fat":
      return {
        key: "fat",
        label: "Yag",
        current: summary.consumedMacros.fatGr,
        target: summary.macroTargets.fatGr,
        change: summary.macroTargets.fatGr - summary.consumedMacros.fatGr,
        unit: "g",
        progress: summary.macroTargets.fatGr === 0 ? 0 : Math.min(1, summary.consumedMacros.fatGr / summary.macroTargets.fatGr),
        estimated: false,
      };
    case "weight":
      return {
        key: "weight",
        label: "Kilo trendi",
        current: summary.currentWeightKg,
        target: summary.targetWeightKg,
        change: summary.estimatedWeightDeltaKg,
        unit: "kg",
        progress: 0,
        estimated: true,
      };
    case "hydration":
      return {
        key: "hydration",
        label: "Su",
        current: summary.hydrationCurrent,
        target: summary.hydrationTarget,
        change: summary.hydrationTarget - summary.hydrationCurrent,
        unit: "bardak",
        progress: summary.hydrationTarget === 0 ? 0 : Math.min(1, summary.hydrationCurrent / summary.hydrationTarget),
        estimated: true,
      };
    case "steps":
      return {
        key: "steps",
        label: "Adim",
        current: summary.stepsCurrent,
        target: summary.stepsTarget,
        change: summary.stepsTarget - summary.stepsCurrent,
        unit: "adim",
        progress: summary.stepsTarget === 0 ? 0 : Math.min(1, summary.stepsCurrent / summary.stepsTarget),
        estimated: true,
      };
    case "streak":
    default:
      return {
        key: "streak",
        label: "Seri",
        current: summary.streakDays,
        target: 7,
        change: 7 - summary.streakDays,
        unit: "gun",
        progress: Math.min(1, summary.streakDays / 7),
        estimated: false,
      };
  }
}


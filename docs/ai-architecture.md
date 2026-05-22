# NutriEasy AI Architecture

This document adapts the AI integration plan to the current NutriEasy stack:

- Flutter mobile client
- Supabase Auth
- Supabase Edge Functions
- Supabase PostgreSQL food database
- Optional OpenAI-compatible structured-output provider behind Edge Functions

The mobile app must never call a model provider directly. All AI work goes through Supabase Edge Functions.

## Backend Flow

```text
Flutter app
  -> Supabase Edge Function
  -> AI prompt registry / provider router
  -> structured JSON validation
  -> nutrition database matcher
  -> domain response for Flutter
```

## Implemented Foundation

The shared AI layer lives in `supabase/functions/_shared/ai`:

- `prompts.ts`: prompt registry with ids, versions, schemas, model, temperature and fallback notes.
- `schemas.ts`: JSON schemas plus runtime parsers/normalizers.
- `prompt_runner.ts`: optional structured model call through `OPENAI_API_KEY`, with graceful heuristic fallback.
- `nutrition_matcher.ts`: maps parsed labels to local `foods` and `food_servings`.
- `types.ts`: shared prompt, confidence and response types.

## Active AI Endpoints

### `analyze-text`

Input:

```json
{
  "text": "yarim tabak pilav + kuru fasulye + cacik",
  "mealType": "lunch",
  "profile": {}
}
```

Flow:

1. `meal_text_parser@v1`
2. structured JSON parse
3. local food DB match
4. kcal/macro calculation
5. app-compatible meal analysis response

### `analyze-image`

Input:

```json
{
  "imageLabel": "tavuk pilav salata",
  "mealType": "lunch",
  "profile": {}
}
```

Current MVP flow uses `imageLabel`/caption as a bridge until real image upload is enabled.

### `meal-analysis-correct`

Input:

```json
{
  "analysis": {},
  "note": "pilav daha azdi, yaninda ayran vardi"
}
```

Flow:

1. `meal_correction@v1`
2. patch-style action parse
3. conservative item/portion update
4. recalculated totals

## Response Meta

AI endpoints keep the old Flutter response shape and add:

```json
{
  "meta": {
    "model": "gpt-4.1-mini",
    "prompt_id": "meal_text_parser",
    "prompt_version": "v1",
    "provider": "openai",
    "latency_ms": 1234,
    "confidence": "medium",
    "fallback_used": false
  }
}
```

If `OPENAI_API_KEY` is not set, `provider` becomes `heuristic` and `fallback_used` is `true`.

## Required Secrets

Set these in Supabase Edge Function secrets when enabling real model calls:

```text
OPENAI_API_KEY=...
OPENAI_MODEL=gpt-4.1-mini
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are provided by Supabase Edge Functions by default.

## Next Implementation Steps

1. Enable real image upload to Supabase Storage.
2. Send public/signed image URL to `analyze-image`.
3. Add model quality logging table when DDL is writable.
4. Add weekly insight generation through `weekly_insight@v1`.
5. Gradually route Nuri replies through `nuri_chat@v1`, keeping deterministic fallback.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

type SummaryRequest = {
  text?: string;
  locale?: string;
};

type GeminiResult = {
  text?: string;
  status?: number;
  detail?: string;
  model?: string;
};

const MAX_ATTEMPTS_PER_MODEL = 3;

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function extractText(payload: any): string {
  const candidates = payload?.candidates;
  if (!Array.isArray(candidates) || candidates.length == 0) {
    return "";
  }
  const parts = candidates[0]?.content?.parts;
  if (!Array.isArray(parts)) {
    return "";
  }
  return parts
    .map((part: any) => (typeof part?.text === "string" ? part.text : ""))
    .join("")
    .trim();
}

function buildGeminiUrl(model: string, apiKey: string): string {
  return `https://generativelanguage.googleapis.com/v1beta/models/${
    encodeURIComponent(model)
  }:generateContent?key=${encodeURIComponent(apiKey)}`;
}

async function callGemini({
  apiKey,
  model,
  prompt,
}: {
  apiKey: string;
  model: string;
  prompt: string;
}): Promise<GeminiResult> {
  const response = await fetch(buildGeminiUrl(model, apiKey), {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.2 },
    }),
  });

  if (!response.ok) {
    return {
      status: response.status,
      detail: await response.text(),
      model,
    };
  }

  const payload = await response.json();
  const text = extractText(payload);
  if (text.length === 0) {
    return {
      status: 502,
      detail: "empty-summary",
      model,
    };
  }

  return { text, model };
}

async function generateWithRetryAndFallback({
  apiKey,
  prompt,
  primaryModel,
  fallbackModel,
}: {
  apiKey: string;
  prompt: string;
  primaryModel: string;
  fallbackModel: string;
}): Promise<GeminiResult> {
  const models: string[] = [primaryModel];
  if (
    fallbackModel.length > 0 &&
    !models.includes(fallbackModel)
  ) {
    models.push(fallbackModel);
  }

  let lastResult: GeminiResult = {
    status: 503,
    detail: "gemini-unavailable",
  };

  for (const model of models) {
    for (let attempt = 1; attempt <= MAX_ATTEMPTS_PER_MODEL; attempt += 1) {
      const result = await callGemini({ apiKey, model, prompt });
      if (result.text && result.text.length > 0) {
        return result;
      }

      lastResult = result;
      const retryable = result.status === 429 || result.status === 503;
      if (retryable && attempt < MAX_ATTEMPTS_PER_MODEL) {
        await sleep(400 * attempt);
        continue;
      }
      break;
    }
  }

  return lastResult;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "method-not-allowed" }, 405);
  }

  let body: SummaryRequest;
  try {
    body = await req.json();
  } catch (_) {
    return jsonResponse({ error: "invalid-json" }, 400);
  }

  const text = body.text?.trim() ?? "";
  const locale = body.locale?.trim() ?? "ko";
  if (text.length === 0) {
    return jsonResponse({ error: "missing-text" }, 400);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY")?.trim() ?? "";
  const model = Deno.env.get("GEMINI_MODEL")?.trim() || "gemini-2.5-flash-lite";
  const fallbackModel = Deno.env.get("GEMINI_FALLBACK_MODEL")?.trim() ?? "";
  if (apiKey.length === 0) {
    return jsonResponse({ error: "missing-api-key" }, 500);
  }

  const prompt = [
    "아래 OCR 텍스트를 시니어가 바로 이해할 수 있게 3줄 이내로 요약해줘.",
    `언어: ${locale}`,
    "",
    text,
  ].join("\n");

  const result = await generateWithRetryAndFallback({
    apiKey,
    prompt,
    primaryModel: model,
    fallbackModel,
  });
  if (!result.text || result.text.length === 0) {
    return jsonResponse(
      {
        error: "gemini-error",
        detail: result.detail ?? "unknown",
        model: result.model ?? model,
        status: result.status ?? 503,
      },
      result.status === 429 ? 429 : 503,
    );
  }

  return jsonResponse({ summary: result.text, model: result.model ?? model });
});

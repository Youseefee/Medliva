import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, x-client-info, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
  "Content-Type": "application/json; charset=utf-8",
  "X-Content-Type-Options": "nosniff",
};

const maxImageBytes = 5 * 1024 * 1024;
const visionPrompt = [
  "You extract medication data from a photo of a prescription or medicine box.",
  "Return ONLY a JSON array. Each item must have: drug_trade_name (string),",
  "dosage_mg (number or null), frequency_per_day (integer), meal_relation",
  '(one of "after_meal", "before_meal", "with_meal", "independent"),',
  'times (array of "HH:MM" strings), inventory_pills (integer), and',
  "active_ingredient (string or null). Return an empty array if no medicine is",
  "legible. Do not infer missing medicines or dosage; use null or empty values.",
].join(" ");

const fallbackCatalog = [
  { trade_name: "Glucophage 500mg", active_ingredient: "Metformin", strength: "500mg", form: "قرص" },
  { trade_name: "Glucophage 1000mg", active_ingredient: "Metformin", strength: "1000mg", form: "قرص" },
  { trade_name: "Concor 5mg", active_ingredient: "Bisoprolol", strength: "5mg", form: "قرص" },
  { trade_name: "Concor 2.5mg", active_ingredient: "Bisoprolol", strength: "2.5mg", form: "قرص" },
  { trade_name: "Augmentin 1g", active_ingredient: "Amoxicillin / Clavulanate", strength: "1000mg", form: "قرص" },
  { trade_name: "Panadol Extra", active_ingredient: "Paracetamol / Caffeine", strength: "500mg", form: "قرص" },
  { trade_name: "Aspirin Protect 100mg", active_ingredient: "Acetylsalicylic acid", strength: "100mg", form: "قرص" },
  { trade_name: "Plavix 75mg", active_ingredient: "Clopidogrel", strength: "75mg", form: "قرص" },
  { trade_name: "Lipitor 20mg", active_ingredient: "Atorvastatin", strength: "20mg", form: "قرص" },
  { trade_name: "Januvia 100mg", active_ingredient: "Sitagliptin", strength: "100mg", form: "قرص" },
];

type Drug = {
  trade_name: string;
  active_ingredient?: string | null;
  strength?: string | null;
  form?: string | null;
};

type ExtractedDrug = Record<string, unknown>;

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

function normalize(value: string): string[] {
  return value
    .normalize("NFKC")
    .toLocaleLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .sort();
}

function editDistance(left: string, right: string): number {
  const previous = Array.from({ length: right.length + 1 }, (_, i) => i);
  for (let i = 1; i <= left.length; i++) {
    let diagonal = previous[0];
    previous[0] = i;
    for (let j = 1; j <= right.length; j++) {
      const above = previous[j];
      previous[j] = Math.min(
        previous[j] + 1,
        previous[j - 1] + 1,
        diagonal + (left[i - 1] === right[j - 1] ? 0 : 1),
      );
      diagonal = above;
    }
  }
  return previous[right.length];
}

function tokenSortScore(left: string, right: string): number {
  const sortedLeft = normalize(left).join(" ");
  const sortedRight = normalize(right).join(" ");
  const longest = Math.max(sortedLeft.length, sortedRight.length);
  if (!longest) return 0;
  return 100 * (1 - editDistance(sortedLeft, sortedRight) / longest);
}

function bestMatch(rawName: string, catalog: Drug[]): { drug: Drug | null; score: number } {
  let best: Drug | null = null;
  let score = 0;
  for (const candidate of catalog) {
    const candidateScore = tokenSortScore(rawName, candidate.trade_name);
    if (candidateScore > score) {
      best = candidate;
      score = candidateScore;
    }
  }
  return score >= 60 ? { drug: best, score: score / 100 } : { drug: null, score: 0 };
}

function parseArray(raw: string): ExtractedDrug[] {
  const cleaned = raw.trim().replace(/^```[a-zA-Z]*\s*/, "").replace(/\s*```$/, "");
  const firstArray = cleaned.indexOf("[");
  const lastArray = cleaned.lastIndexOf("]");
  if (firstArray >= 0 && lastArray > firstArray) {
    try {
      const parsed: unknown = JSON.parse(cleaned.slice(firstArray, lastArray + 1));
      return Array.isArray(parsed)
        ? parsed.filter((value): value is ExtractedDrug => !!value && typeof value === "object" && !Array.isArray(value))
        : [];
    } catch {
      return [];
    }
  }
  const firstObject = cleaned.indexOf("{");
  const lastObject = cleaned.lastIndexOf("}");
  if (firstObject >= 0 && lastObject > firstObject) {
    try {
      const parsed: unknown = JSON.parse(cleaned.slice(firstObject, lastObject + 1));
      return parsed && typeof parsed === "object" && !Array.isArray(parsed) &&
          "drug_trade_name" in parsed
        ? [parsed as ExtractedDrug]
        : [];
    } catch {
      return [];
    }
  }
  return [];
}

function parseNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value !== "string") return null;
  const match = value.match(/\d+(?:\.\d+)?/);
  return match ? Number(match[0]) : null;
}

function parseImageType(bytes: Uint8Array): string | null {
  if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) return "image/jpeg";
  if ([137, 80, 78, 71, 13, 10, 26, 10].every((byte, i) => bytes[i] === byte)) return "image/png";
  if (String.fromCharCode(...bytes.slice(0, 4)) === "GIF8") return "image/gif";
  if (String.fromCharCode(...bytes.slice(0, 4)) === "RIFF" &&
    String.fromCharCode(...bytes.slice(8, 12)) === "WEBP") return "image/webp";
  return null;
}

async function readVision(image: Uint8Array, mimeType: string, apiKey: string): Promise<ExtractedDrug[] | null> {
  try {
    let binary = "";
    for (let i = 0; i < image.length; i += 0x8000) {
      binary += String.fromCharCode(...image.subarray(i, Math.min(i + 0x8000, image.length)));
    }
    const response = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        signal: AbortSignal.timeout(25_000),
        body: JSON.stringify({
          contents: [{ parts: [
            { text: visionPrompt },
            { inline_data: { mime_type: mimeType, data: btoa(binary) } },
          ] }],
          generationConfig: { responseMimeType: "application/json" },
        }),
      },
    );
    if (!response.ok) return null;
    const result = await response.json();
    const text = result?.candidates?.[0]?.content?.parts?.find(
      (part: { text?: unknown }) => typeof part.text === "string",
    )?.text;
    return typeof text === "string" ? parseArray(text) : null;
  } catch {
    return null;
  }
}

function textFallback(fileName: string, catalog: Drug[]): ExtractedDrug[] {
  const hint = fileName.replace(/[_-]+/g, " ").replace(/\.[a-z0-9]+$/i, "").trim();
  if (!hint) return [];
  const match = bestMatch(hint, catalog);
  if (!match.drug) return [];
  return [{ drug_trade_name: match.drug.trade_name, confidence_score: match.score }];
}

function buildResponse(items: ExtractedDrug[], source: "gemini_vision" | "text", catalog: Drug[]) {
  const medications = items.flatMap((item) => {
    const rawName = typeof item.drug_trade_name === "string"
      ? item.drug_trade_name.trim().slice(0, 150)
      : "";
    if (!rawName) return [];

    const { drug, score } = bestMatch(rawName, catalog);
    const dosage = parseNumber(item.dosage_mg);
    const frequency = Number.parseInt(String(item.frequency_per_day ?? 1), 10);
    const inventory = Number.parseInt(String(item.inventory_pills ?? 30), 10);
    const rawTimes = Array.isArray(item.times) ? item.times : [];
    const times = rawTimes
      .filter((time): time is string => typeof time === "string" && /^([01]\d|2[0-3]):[0-5]\d$/.test(time))
      .slice(0, 8);
    const relations = new Set(["after_meal", "before_meal", "with_meal", "independent"]);
    const modelConfidence = parseNumber(item.confidence_score);

    return [{
      drug_trade_name: drug?.trade_name ?? rawName,
      dosage_mg: dosage !== null && dosage > 0 && dosage <= 100_000 ? dosage : null,
      frequency_per_day: Number.isFinite(frequency) ? Math.max(1, Math.min(8, frequency)) : 1,
      meal_relation: typeof item.meal_relation === "string" && relations.has(item.meal_relation)
        ? item.meal_relation
        : "after_meal",
      times,
      inventory_pills: Number.isFinite(inventory) ? Math.max(0, Math.min(10_000, inventory)) : 30,
      confidence_score: score > 0.5 ? score : Math.max(0, Math.min(1, modelConfidence ?? (source === "gemini_vision" ? 0.9 : 0.5))),
      active_ingredient: drug?.active_ingredient ?? (typeof item.active_ingredient === "string" ? item.active_ingredient.slice(0, 150) : null),
    }];
  });
  const confidence = medications.length
    ? medications.reduce((total, medication) => total + medication.confidence_score, 0) / medications.length
    : 0;
  return { medications, confidence: Math.round(confidence * 100) / 100, source };
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

  const authorization = request.headers.get("Authorization");
  const token = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!token) return jsonResponse({ error: "Authentication required" }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publishableKeys = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  let publishableKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (publishableKeys) {
    try {
      publishableKey = JSON.parse(publishableKeys)?.default ?? publishableKey;
    } catch {
      // Fall back to the legacy anon key where it is still configured.
    }
  }
  if (!supabaseUrl || !publishableKey) return jsonResponse({ error: "Scan service unavailable" }, 503);

  let body: { patient_id?: unknown; image_path?: unknown; file_name?: unknown };
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ error: "Invalid request body" }, 400);
  }
  const patientId = typeof body.patient_id === "string" ? body.patient_id : "";
  const imagePath = typeof body.image_path === "string" ? body.image_path : "";
  const fileName = typeof body.file_name === "string" ? body.file_name.slice(0, 160) : "";
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(patientId) ||
    !new RegExp(`^${patientId}/[0-9a-f]{32}$`, "i").test(imagePath)) {
    return jsonResponse({ error: "Invalid prescription image reference" }, 400);
  }

  const supabase = createClient(supabaseUrl, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: userData, error: authError } = await supabase.auth.getUser(token);
  if (authError || !userData.user) return jsonResponse({ error: "Authentication required" }, 401);

  // This user-scoped download applies the private bucket's RLS policy. The
  // caller must own the patient folder or have an active caregiver link.
  const { data: imageBlob, error: storageError } = await supabase.storage
    .from("prescriptions")
    .download(imagePath);
  if (storageError || !imageBlob) return jsonResponse({ error: "Prescription image not found" }, 404);
  if (imageBlob.size > maxImageBytes) return jsonResponse({ error: "Prescription image is too large" }, 413);

  const image = new Uint8Array(await imageBlob.arrayBuffer());
  const mimeType = parseImageType(image);
  const { data: catalogRows, error: catalogError } = await supabase
    .from("drug_catalog")
    .select("trade_name, active_ingredient, strength, form")
    .limit(500);
  const catalog: Drug[] = !catalogError && catalogRows?.length
    ? catalogRows as Drug[]
    : fallbackCatalog;

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  const visionItems = mimeType && apiKey
    ? await readVision(image, mimeType, apiKey)
    : null;
  if (visionItems?.length) return jsonResponse(buildResponse(visionItems, "gemini_vision", catalog));

  // If Gemini is unavailable or cannot read the photo, only a catalog match
  // from the picker filename is returned. An unreadable image stays empty.
  return jsonResponse(buildResponse(textFallback(fileName, catalog), "text", catalog));
});

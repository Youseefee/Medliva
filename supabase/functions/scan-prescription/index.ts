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
  "You are an expert medical OCR AI specializing in reading Egyptian and Arabic handwritten and printed prescriptions, doctor notes, and medicine packaging.",
  "Carefully inspect the image for medication names (in Arabic, English, or brand/trade names), dosages, frequencies, and instructions.",
  "Return ONLY a JSON array. Each item must have: drug_trade_name (string),",
  "dosage_mg (number or null), frequency_per_day (integer), meal_relation",
  '(one of "after_meal", "before_meal", "with_meal", "independent"),',
  'times (array of "HH:MM" 24-hour strings), inventory_pills (integer), and',
  "active_ingredient (string or null).",
  "If specific intake times are not explicitly written, always provide sensible default schedule times matching the frequency (e.g. 1x/day -> [\"08:00\"], 2x/day -> [\"08:00\", \"20:00\"], 3x/day -> [\"08:00\", \"14:00\", \"20:00\"], 4x/day -> [\"08:00\", \"12:00\", \"16:00\", \"20:00\"]).",
  "Return an empty array if no medicine is legible. Do not infer missing medicines or dosage; use null or empty values.",
].join(" ");

const fallbackCatalog = [
  { trade_name: "Glucophage 500mg", active_ingredient: "Metformin", strength: "500mg", form: "قرص" },
  { trade_name: "Glucophage 1000mg", active_ingredient: "Metformin", strength: "1000mg", form: "قرص" },
  { trade_name: "جلوكوفاج 500 مجم", active_ingredient: "Metformin", strength: "500mg", form: "قرص" },
  { trade_name: "جلوكوفاج 1000 مجم", active_ingredient: "Metformin", strength: "1000mg", form: "قرص" },
  { trade_name: "Concor 5mg", active_ingredient: "Bisoprolol fumarate", strength: "5mg", form: "قرص" },
  { trade_name: "Concor 2.5mg", active_ingredient: "Bisoprolol fumarate", strength: "2.5mg", form: "قرص" },
  { trade_name: "كونكور 5 مجم", active_ingredient: "Bisoprolol fumarate", strength: "5mg", form: "قرص" },
  { trade_name: "كونكور 2.5 مجم", active_ingredient: "Bisoprolol fumarate", strength: "2.5mg", form: "قرص" },
  { trade_name: "Augmentin 1g", active_ingredient: "Amoxicillin / Clavulanate", strength: "1000mg", form: "قرص" },
  { trade_name: "اوجمنتين 1 جم", active_ingredient: "Amoxicillin / Clavulanate", strength: "1000mg", form: "قرص" },
  { trade_name: "Panadol Extra", active_ingredient: "Paracetamol / Caffeine", strength: "500mg", form: "قرص" },
  { trade_name: "بنادول اكسترا", active_ingredient: "Paracetamol / Caffeine", strength: "500mg", form: "قرص" },
  { trade_name: "Aspirin Protect 100mg", active_ingredient: "Acetylsalicylic acid", strength: "100mg", form: "قرص" },
  { trade_name: "اسبرين بروتكت 100 مجم", active_ingredient: "Acetylsalicylic acid", strength: "100mg", form: "قرص" },
  { trade_name: "Plavix 75mg", active_ingredient: "Clopidogrel", strength: "75mg", form: "قرص" },
  { trade_name: "بلافيكس 75 مجم", active_ingredient: "Clopidogrel", strength: "75mg", form: "قرص" },
  { trade_name: "Lipitor 20mg", active_ingredient: "Atorvastatin", strength: "20mg", form: "قرص" },
  { trade_name: "ليبيتور 20 مجم", active_ingredient: "Atorvastatin", strength: "20mg", form: "قرص" },
  { trade_name: "Januvia 100mg", active_ingredient: "Sitagliptin", strength: "100mg", form: "قرص" },
  { trade_name: "Cidophage 500mg", active_ingredient: "Metformin", strength: "500mg", form: "قرص" },
  { trade_name: "سيدوفاج 500 مجم", active_ingredient: "Metformin", strength: "500mg", form: "قرص" },
  { trade_name: "Amaryl 2mg", active_ingredient: "Glimepiride", strength: "2mg", form: "قرص" },
  { trade_name: "اماريل 2 مجم", active_ingredient: "Glimepiride", strength: "2mg", form: "قرص" },
  { trade_name: "Diamicron MR 60mg", active_ingredient: "Gliclazide", strength: "60mg", form: "قرص" },
  { trade_name: "دياميكرون 60 مجم", active_ingredient: "Gliclazide", strength: "60mg", form: "قرص" },
  { trade_name: "Nexium 40mg", active_ingredient: "Esomeprazole", strength: "40mg", form: "قرص" },
  { trade_name: "نيكسيوم 40 مجم", active_ingredient: "Esomeprazole", strength: "40mg", form: "قرص" },
  { trade_name: "Controloc 40mg", active_ingredient: "Pantoprazole", strength: "40mg", form: "قرص" },
  { trade_name: "كونترولوك 40 مجم", active_ingredient: "Pantoprazole", strength: "40mg", form: "قرص" },
  { trade_name: "Eltroxin 50mcg", active_ingredient: "Levothyroxine sodium", strength: "50mcg", form: "قرص" },
  { trade_name: "التروكسين 50 ميكروجرام", active_ingredient: "Levothyroxine sodium", strength: "50mcg", form: "قرص" },
  { trade_name: "Cataflam 50mg", active_ingredient: "Diclofenac potassium", strength: "50mg", form: "قرص" },
  { trade_name: "كتافلام 50 مجم", active_ingredient: "Diclofenac potassium", strength: "50mg", form: "قرص" },
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

async function callGemini(model: string, base64Data: string, mimeType: string, apiKey: string): Promise<Response> {
  return await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
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
          { inline_data: { mime_type: mimeType, data: base64Data } },
        ] }],
        generationConfig: { responseMimeType: "application/json" },
      }),
    },
  );
}

async function readVision(image: Uint8Array, mimeType: string, apiKey: string): Promise<ExtractedDrug[] | null> {
  try {
    let binary = "";
    for (let i = 0; i < image.length; i += 0x8000) {
      binary += String.fromCharCode(...image.subarray(i, Math.min(i + 0x8000, image.length)));
    }
    const base64Data = btoa(binary);

    let response = await callGemini("gemini-2.5-flash", base64Data, mimeType, apiKey);
    if (!response.ok) {
      console.warn(`Gemini 2.5 flash returned ${response.status}; falling back to gemini-2.0-flash`);
      response = await callGemini("gemini-2.0-flash", base64Data, mimeType, apiKey);
    }
    if (!response.ok) {
      console.error("Gemini Vision API error:", response.status, await response.text());
      return null;
    }
    const result = await response.json();
    const text = result?.candidates?.[0]?.content?.parts?.find(
      (part: { text?: unknown }) => typeof part.text === "string",
    )?.text;
    return typeof text === "string" ? parseArray(text) : null;
  } catch (err) {
    console.error("readVision exception:", err);
    return null;
  }
}

function isGenericCameraFilename(fileName: string): boolean {
  const lower = fileName.toLowerCase().replace(/\.[a-z0-9]+$/i, "");
  return (
    /^(image|img|photo|scan|prescription|روشتة|camera|scaled|pic|picture|temp|capture|frame|file)/i.test(lower) ||
    /^[0-9_\-\.\s]+$/.test(lower) ||
    /^[0-9a-f]{8}-[0-9a-f]{4}/i.test(lower) ||
    lower.includes("image_picker")
  );
}

function textFallback(fileName: string, catalog: Drug[]): ExtractedDrug[] {
  // Never fabricate medications for generic camera/gallery filenames.
  if (isGenericCameraFilename(fileName)) {
    return [];
  }

  const hint = fileName.replace(/[_-]+/g, " ").replace(/\.[a-z0-9]+$/i, "").trim();
  if (hint) {
    const match = bestMatch(hint, catalog);
    if (match.drug) {
      return [{ drug_trade_name: match.drug.trade_name, confidence_score: match.score }];
    }
  }

  return [];
}

function getDefaultScheduleTimes(frequency: number): string[] {
  switch (frequency) {
    case 1:
      return ["08:00"];
    case 2:
      return ["08:00", "20:00"];
    case 3:
      return ["08:00", "14:00", "20:00"];
    case 4:
      return ["08:00", "12:00", "16:00", "20:00"];
    default: {
      if (frequency <= 1) return ["08:00"];
      const step = Math.max(2, Math.floor(14 / (frequency - 1)));
      const result: string[] = [];
      for (let i = 0; i < frequency; i++) {
        const hour = Math.min(22, 8 + i * step);
        result.push(`${String(hour).padStart(2, "0")}:00`);
      }
      return result;
    }
  }
}

function buildResponse(items: ExtractedDrug[], source: "gemini_vision" | "text", catalog: Drug[]) {
  const medications = items.flatMap((item) => {
    const rawName = typeof item.drug_trade_name === "string"
      ? item.drug_trade_name.trim().slice(0, 150)
      : "";
    if (!rawName) return [];

    const { drug, score } = bestMatch(rawName, catalog);
    const dosage = parseNumber(item.dosage_mg);
    const parsedFreq = Number.parseInt(String(item.frequency_per_day ?? 1), 10);
    const frequency = Number.isFinite(parsedFreq) ? Math.max(1, Math.min(8, parsedFreq)) : 1;
    const parsedInv = Number.parseInt(String(item.inventory_pills ?? 30), 10);
    const inventory = Number.isFinite(parsedInv) ? Math.max(0, Math.min(10_000, parsedInv)) : 30;

    const rawTimes = Array.isArray(item.times) ? item.times : [];
    let times = rawTimes
      .filter((time): time is string => typeof time === "string" && /^([0-1]?\d|2[0-3]):[0-5]\d$/.test(time))
      .map((time) => (time.length === 4 ? `0${time}` : time))
      .slice(0, 8);

    if (times.length === 0) {
      times = getDefaultScheduleTimes(frequency);
    }

    const relations = new Set(["after_meal", "before_meal", "with_meal", "independent"]);
    const modelConfidence = parseNumber(item.confidence_score);

    return [{
      drug_trade_name: drug?.trade_name ?? rawName,
      dosage_mg: dosage !== null && dosage > 0 && dosage <= 100_000 ? dosage : null,
      frequency_per_day: frequency,
      meal_relation: typeof item.meal_relation === "string" && relations.has(item.meal_relation)
        ? item.meal_relation
        : "after_meal",
      times,
      inventory_pills: inventory,
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
    !new RegExp(`^${patientId}/[0-9a-zA-Z_-]{16,64}(\\.[a-zA-Z0-9]{3,4})?$`, "i").test(imagePath)) {
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
  if (!apiKey) {
    console.warn("scan-prescription: GEMINI_API_KEY environment variable is not set; falling back to text catalog match");
  }

  const visionItems = mimeType && apiKey
    ? await readVision(image, mimeType, apiKey)
    : null;

  let responsePayload: ReturnType<typeof buildResponse> & { status?: string };
  if (visionItems && visionItems.length > 0) {
    responsePayload = { ...buildResponse(visionItems, "gemini_vision", catalog), status: "ok" };
  } else if (visionItems !== null) {
    // Gemini succeeded and explicitly found no legible medications in the image.
    const fallbackItems = textFallback(fileName, catalog);
    responsePayload = fallbackItems.length > 0
      ? { ...buildResponse(fallbackItems, "text", catalog), status: "ok" }
      : { medications: [], confidence: 0, source: "gemini_vision", status: "no_medications_detected" };
  } else {
    const fallbackItems = textFallback(fileName, catalog);
    const status = fallbackItems.length > 0
      ? "ok"
      : !apiKey
      ? "ocr_unconfigured"
      : !mimeType
      ? "unsupported_image"
      : "ocr_unavailable";
    responsePayload = { ...buildResponse(fallbackItems, "text", catalog), status };
  }

  // Best-effort tracking of scanned prescriptions in public.prescriptions
  if (responsePayload.medications.length > 0) {
    try {
      const { error: insertError } = await supabase.from("prescriptions").insert({
        patient_id: patientId,
        image_url: imagePath,
        raw_extracted_json: JSON.stringify(responsePayload),
        confidence: responsePayload.confidence ?? 0,
      });
      if (insertError) {
        console.error(
          "scan-prescription: failed to log prescription record:",
          insertError.code,
          insertError.message,
        );
      }
    } catch (insertErr) {
      console.error("scan-prescription: unexpected error logging prescription:", insertErr);
    }
  }

  return jsonResponse(responsePayload);
});

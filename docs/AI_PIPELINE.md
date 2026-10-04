# طبقة الذكاء الاصطناعي

## 1. مسح الروشتة
| الخطوة | التنفيذ |
|---|---|
| تحسين الصورة | على الجهاز: قص + تدوير + ضغط (≤ 1.5MB) |
| الاستخراج | Gemini Flash Vision + `response_schema` (JSON Schema) |
| المطابقة | `rapidfuzz` على `drug_catalog` (عتبة 85) |
| الثقة | `min(llm_confidence, match_score)` لكل حقل |
| التأكيد | Human-in-the-loop إلزامي |
| Fallback | Google Cloud Vision OCR → LLM نصي |

**Prompt (مختصر):** "استخرج الأدوية من الروشتة المصرية. أرجع JSON فقط حسب الـ schema. لو حقل غير واضح ضعه null وقلل الثقة. لا تخمّن أدوية غير مكتوبة."

## 2. القياسات الصوتية
1. STT: `faster-whisper` (large-v3, language=ar) أو Gemini Audio.
2. Normalization: تحويل الأرقام العامية ("مية وخمسة وتلاتين" → 135، "على/فوق" → فاصل الضغط، "صايم/فاطر").
3. Regex + قواعد → `{type, v1, v2, meal_context}`؛ LLM Fallback لو فشل.
4. Triage: **Rule Engine حتمي** (لا AI) — `services/triage.py`.

```python
def triage_bp(sys: int, dia: int) -> str:
    if sys >= 180 or sys <= 90 or dia >= 120: return "critical"
    if sys >= 130 or dia >= 80: return "borderline"
    return "normal"

def triage_glucose_fasting(v: int) -> str:
    if v < 70 or v > 250: return "critical"
    if v > 110: return "borderline"
    return "normal"
```

## 3. التقييم (Evaluation)
- Dataset: 100+ روشتة حقيقية (بعد إخفاء البيانات) + 200 تسجيل صوتي من أشخاص مختلفين.
- المقاييس: Field-level Accuracy، Precision/Recall لأسماء الأدوية، WER للصوت، زمن الاستجابة.
- الأهداف: OCR ≥ 85%، Vitals ≥ 95%، زمن < 4 ث.

## 4. التكلفة والخصوصية
- Caching للنتائج بـ hash الصورة، حدود يومية لكل مستخدم.
- عدم إرسال اسم المريض للـ LLM؛ حذف الصور الخام بعد 90 يوم (قابل للتعديل).

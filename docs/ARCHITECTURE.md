# المعمارية (Architecture)

## النظرة العامة
```mermaid
flowchart LR
  subgraph Mobile["Flutter App"]
    UI["Patient / Caregiver UI"]
    DB[("Drift SQLite")]
    AL["Native Alarm Engine (Kotlin)"]
    SQ["Sync Queue"]
  end
  subgraph Backend["Backend Services"]
    API["FastAPI REST + WebSocket"]
    WK["Celery Worker"]
    BT["Celery Beat"]
  end
  subgraph Cloud["Cloud Infrastructure (Free Tier)"]
    PG[("PostgreSQL (Supabase)")]
    RD[("Redis (Upstash)")]
    S3[("Object Storage (Supabase)")]
  end
  UI --> DB --> AL
  DB --> SQ --> API
  API --> PG
  API --> RD
  API --> S3
  API --> AI["Gemini / Whisper"]
  BT --> WK --> FCM["FCM"]
  WK --> TW["Twilio"]
  PORTAL["Doctor Portal (Next.js)"] --> API
```

## طبقات تطبيق Flutter (Clean Architecture)
- `presentation/` Widgets + Riverpod Notifiers
- `domain/` Entities + UseCases + Repository interfaces
- `data/` Drift DAOs + Dio remote sources + Repository impl

## Offline-First
1. كل كتابة تروح SQLite بحالة `pending` + `client_uuid`.
2. الـ Sync Queue يبعت `POST /sync/batch` عند توفر الإنترنت (WorkManager كل 15 د + عند فتح التطبيق).
3. السيرفر Idempotent على `client_uuid`.
4. التعارض: السيرفر مرجع للأدوية/المواعيد، والجهاز مرجع لسجلات الجرعات.
5. المنبهات تتجدول محلياً من SQLite فقط — لا تعتمد على السيرفر.

## المنبه الصارم (Android)
- صلاحيات: `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `POST_NOTIFICATIONS`.
- `AlarmManager.setExactAndAllowWhileIdle()` + Full-Screen Intent.
- `BootReceiver` يعيد جدولة كل المنبهات من SQLite.
- إرشاد المستخدم لإيقاف Battery Optimization (خصوصاً Xiaomi/Oppo/Huawei).

## Sequence: الجرعة والتصعيد
```mermaid
sequenceDiagram
  participant A as Alarm (Device)
  participant P as Patient
  participant API
  participant B as Celery Beat
  participant C as Caregiver
  A->>P: Full-screen alarm + TTS
  alt Taken
    P->>API: POST /adherence/log (taken)
    API-->>C: WebSocket update
  else No response
    B->>API: scan unacknowledged doses (every 60s)
    B->>C: +30m Tier-1 FCM
    B->>C: +60m Tier-2 FCM + call button
  end
```

## Sequence: مسح الروشتة
```mermaid
sequenceDiagram
  participant U as User
  participant App
  participant API
  participant G as Gemini Vision
  U->>App: Capture image
  App->>API: POST /ai/scan-prescription
  API->>G: image + JSON schema
  G-->>API: structured meds
  API->>API: fuzzy match drug DB
  API-->>App: meds + confidence
  U->>App: confirm / edit
  App->>API: POST /medications (bulk)
```

## Sequence: القياس الصوتي
```mermaid
sequenceDiagram
  participant P as Patient
  participant App
  participant API
  participant W as Whisper
  P->>App: Speak reading
  App->>API: POST /ai/parse-voice-vitals (audio)
  API->>W: transcribe
  W-->>API: text
  API->>API: parse numbers + triage rules
  API-->>App: value + band
  App->>P: TTS confirmation
  opt Critical
    API->>API: push alert to caregiver
  end
```

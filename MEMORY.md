# 🧠 Ambient Shield — Memory Box (Context Cache & Knowledge Base)

> **LIVING AGENT MEMORY:** This document is the single source of truth for the present state, architecture, conventions, and operational workflows of the **Ambient Shield** codebase. 
> 
> **AGENT DIRECTIVE:** Any future agent modifying this codebase **MUST read this file first** to minimize token consumption and **MUST update this file** whenever architecture, endpoints, components, or features are modified.

---

## ⚡ Agent Quickstart (Read This First)

* **Repository:** `ambient-Shield` (Chrome Extension MV3 + Next.js 14 Static Export)
* **Primary Language:** TypeScript / JavaScript / Tailwind CSS
* **Core Function:** Real-time digital safety suite (misinformation, deepfake images, predatory privacy policies, adult content firewall, and parental whitelist) operating at the browser edge with minimal cloud dependencies.
* **Master Agent Prompt:** See [`MASTER_PROMPT.md`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/MASTER_PROMPT.md) for the copy-pasteable prompt to guide any new agent.
* **Dual Runtime:**
  1. **Extension Mode (Primary):** Chrome MV3. UI talks to Service Worker (`extension/background.js`) via `chrome.runtime.sendMessage`.
  2. **Web Mode (Fallback):** Next.js static site running in a browser. Uses [`lib/extension-api.ts`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/lib/extension-api.ts) which falls back to direct client-side Gemini fetch via `localStorage.getItem("geminiKey")`.

---

## 🛠️ Command Cheat Sheet

| Command | Action | Output / Target |
|---|---|---|
| `npm run dev` | Launch Next.js dev server | `http://localhost:3000` |
| `npm run build` | Next.js static export | Builds static files to `dist/` |
| `npm run build:ext` | Full extension builder | Runs `build-extension.ps1` $\rightarrow$ compiles, transforms, and copies to `extension/` |
| `npm run lint` | ESLint verification | Validates code standards |

---

## 📁 Repository & Symbol Map

```
ambient-Shield/
├── app/                           # Next.js 14 App Router (Static Export)
│   ├── globals.css                # CSS variables, dark palette (#070b12), neon accents
│   ├── layout.tsx                 # Root layout with Inter font and Toaster
│   ├── page.tsx                   # Public marketing landing page
│   ├── analyze/page.tsx           # Main analyzer page embedding AnalyzeTabs
│   ├── settings/page.tsx          # Settings page embedding SettingsForm
│   ├── settings/SettingsForm.tsx  # API key configuration form
│   └── api/                       # Deprecated stubs (GET-only) retained for static export build
│       ├── health/route.ts
│       ├── scan/factcheck/route.ts
│       └── scan/policy/route.ts
├── components/
│   ├── analyze/
│   │   ├── AnalyzeTabs.tsx        # Central tab coordinator (Framer Motion animations)
│   │   ├── FactChecker.tsx        # Fact-checking UI with CredibilityRing & citations
│   │   ├── PolicyAnalyzer.tsx     # Legal policy UI with RiskMeter & tag breakdowns
│   │   ├── ImageAnalyzer.tsx      # Image & deepfake dropzone with 3-phase badge
│   │   ├── HistoryPanel.tsx       # Session history sidebar (last 20 scans)
│   │   └── UrlParamInit.tsx       # Deep-link intent consumer (?type=, ?url=, ?text=)
│   ├── layout/
│   │   ├── Navbar.tsx             # Main navigation bar
│   │   └── Footer.tsx             # Footer links & copyright
│   ├── shared/
│   │   ├── CredibilityRing.tsx    # Animated SVG credibility gauge (0-100)
│   │   ├── EmptyState.tsx         # Reusable placeholder UI for analyzers
│   │   ├── RateLimitBar.tsx       # Visual progress bar for API quotas
│   │   ├── ResultCard.tsx         # Privacy policy breakdown card
│   │   ├── RiskBadge.tsx          # Safe / Caution / Danger badge
│   │   └── RiskMeter.tsx          # 1-10 visual risk progress bar
│   └── ui/                        # Radix UI primitives (Button, Input, Textarea, Card, Badge, Tabs)
├── extension/                     # Chrome Extension (Manifest V3) — Target of build-extension.ps1
│   ├── manifest.json              # MV3 configuration, permissions, web_accessible_resources
│   ├── background.js              # Central service worker: ALL Gemini calls, caches, search bots
│   ├── content.js                 # Trust Aura DOM observer, feed scanner, adult image blur
│   ├── content-firewall.js        # Wall 2 DOM blocker (runs at document_start), query blocker
│   ├── content-firewall.css       # Fullscreen shield styling
│   ├── content.css                # Trust Aura glowing overlays & badges styling
│   ├── dashboard.html             # Standalone extension dashboard page
│   ├── dashboard.js               # Dashboard controller (vanilla JS, zero framework)
│   ├── popup.html                 # Extension action popup
│   ├── popup.js                   # Quick actions, toggle switches, parental modal, API key
│   ├── blocked.html               # Parental mode block landing page
│   ├── block-rules.json           # declarativeNetRequest Wall 1 network rules
│   ├── route-fix.js               # Next.js client-side router patch for chrome-extension://
│   └── next_assets/               # Compiled Next.js bundle (renamed from _next for MV3)
├── hooks/
│   ├── useLocalStorage.ts         # Persistent browser storage hook
│   └── useSessionHistory.ts       # 24-hour TTL history manager (max 20 items)
├── lib/
│   ├── ai.ts                      # Direct Google Gemini SDK client (callGemini, callGeminiMultimodal)
│   ├── api-client.ts              # Legacy fetch wrapper for HTTP endpoints
│   ├── cache.ts                   # In-memory LRU cache (500 entries, 24h TTL, SHA-256)
│   ├── extension-api.ts           # Universal IPC bridge (chrome.runtime.sendMessage + web fallback)
│   ├── hash.ts                    # String hash utility
│   ├── rate-limit.ts              # Multi-tier sliding window rate limiter
│   ├── types.ts                   # Core TypeScript domain models (PolicyResult, FactCheckResult, etc.)
│   └── utils.ts                   # shadcn cn() class combiner
├── types/
│   └── extension.ts               # Shared ScanResponse interface
├── build-extension.ps1            # Windows PowerShell MV3 packaging pipeline
├── build-extension.sh             # Bash MV3 packaging pipeline
├── agent.md                       # Comprehensive technical specification
├── MASTER_PROMPT.md               # Standard agent directive & execution protocol
└── MEMORY.md                      # THIS FILE — Living Agent Memory & Usage Ledger
```

---

## 🔍 Core Subsystems & How They Work

### 1. Trust Aura Social Feed Scanner
* **Files:** [`extension/content.js`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/content.js), [`extension/background.js`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/background.js)
* **Mechanics:**
  - `MutationObserver` monitors dynamic post additions on Twitter/X, LinkedIn, Facebook, Instagram, Reddit, YouTube, TikTok.
  - Concurrency limit: `MAX_CONCURRENT = 2`.
  - Fast Regex Pre-filter catches clickbait, spam, miracle cures, and heavy ALL-CAPS text immediately.
  - Passes text to `background.js` via `action: "TRUST_AURA"`.
  - Injects absolute child div `.ambient-aura-overlay` inside post container with glowing colored halos (Green = Verified, Amber = Caution, Red = Danger).

### 2. Entity-Aware Fact Checker (Zero API Cost)
* **Files:** [`extension/background.js`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/background.js#L524-L822), [`components/analyze/FactChecker.tsx`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/components/analyze/FactChecker.tsx)
* **Mechanics:**
  - `extractEntities()` extracts political entities (TMC, BJP, Congress, AAP, SP, etc.), locations (10 Indian states), and target years.
  - **Time Paradox Engine:** If claim year > current system year and past tense is used, immediately flags `FALSE` (Credibility: 0).
  - **Multi-Source Retrieval:** Queries MediaWiki API (`prop=extracts&exintro&explaintext&exsentences=10`), DuckDuckGo Lite, and dedicated debunkers (Snopes, Reuters, AP News).
  - **Winner Cross-Verification:** Checks if claimed winner matches actual documented winner in Wikipedia intro. If rival winner detected, flags `FALSE` (Credibility: 5) and cites Wikipedia URL.

### 3. Offline Privacy Policy Legal Analyst
* **Files:** [`extension/background.js`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/background.js#L430-L518), [`extension/popup.js`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/popup.js#L81-L107), [`components/analyze/PolicyAnalyzer.tsx`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/components/analyze/PolicyAnalyzer.tsx)
* **Mechanics:**
  - 100% on-device heuristic parser (`analyzePolicyLocal()`) — no data sent to cloud.
  - Built-in `PRIVACY_POLICY_MAP` for 25+ top platforms (Google, Meta, LinkedIn, Apple, Netflix, etc.).
  - Extracts What They Collect (IP, GPS, biometrics, cookies, contacts), Who They Share With (advertisers, law enforcement, affiliates), Red Flags (data selling [+3], forced arbitration [+2], cross-site tracking [+2], indefinite retention [+1]), and User Rights (GDPR deletion, CCPA opt-out).
  - Computes 1-10 Risk Score and categorical verdict (`SAFE`, `CAUTION`, `DANGER`).

### 4. Forensic Deepfake & Image Analyzer
* **Files:** [`extension/background.js`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/background.js#L828-L879), [`extension/dashboard.js`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/dashboard.js#L404-L638), [`components/analyze/ImageAnalyzer.tsx`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/components/analyze/ImageAnalyzer.tsx)
* **Mechanics:**
  - **Phase 1 (Zero Cost):** Trusted domains whitelist, safe formats (`.svg`, `.ico`), adult URL keyword filter.
  - **Phase 2 (Text AI):** Analyzes filename, URL parameters with Gemini text. Completes if confidence $\ge 0.85$.
  - **Phase 3 (Vision AI):** Resizes image on client canvas to max 2048px, converts to JPEG base64, runs Gemini Multimodal inspection for synthetic generation, face artifacts, adult, or violent content.

### 5. Triple-Layer Content Firewall
* **Files:** [`extension/block-rules.json`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/block-rules.json), [`extension/content-firewall.js`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/content-firewall.js), [`extension/background.js`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/background.js#L26-L143)
* **Mechanics:**
  - **Wall 1 (DNS/Network):** Chrome `declarativeNetRequest` blocks 70+ adult domains before HTTP connection.
  - **Wall 2 (DOM Injection):** `document_start` script blocks known hostnames, adult URL fragments, and adult search queries across Google/Bing/DDG/YouTube.
  - **Wall 3 (Tab Watcher):** Background service worker listens to `chrome.tabs.onUpdated` and script-injects lock overlay.
  - **Anti-Tamper:** Re-attaches overlay on removal via `MutationObserver`; suppresses `F12`, `Ctrl+Shift+I/J/C/K`, `Ctrl+U`.

### 6. Parental / Work Mode Whitelist
* **Files:** [`extension/background.js`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/background.js#L1026-L1123), [`extension/popup.js`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/popup.js#L246-L430), [`extension/blocked.html`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/extension/blocked.html)
* **Mechanics:**
  - Default PIN: `123456`.
  - 4-Layer Enforcement: Immediate sweep of all open tabs, `webNavigation.onBeforeNavigate`, `tabs.onUpdated`, and `tabs.onActivated`. Non-whitelisted URLs redirected to `blocked.html`.

---

## 🤖 AI Resilience Backbone & Caching Specifications

### Gemini Model Cascade (`callGemini` in `background.js`)
* **Priority Cascade:**
  1. `gemini-2.0-flash` (Primary, fastest)
  2. `gemini-1.5-pro` (Quality reasoning)
  3. `gemini-1.5-flash` (Stable fallback)
  4. `gemini-1.5-flash-8b` / `gemini-1.5-flash-002` (Ultra-compatible)
* **Dual Endpoint Retry:** Tests both `v1beta` and `v1` REST endpoints.
* **Failover:** On `404`, skips immediately to next model. On `503` or `429`, retries after 1s/3s before cascading.
* **Safety & Latency:** Hard 60s timeout via `AbortController`. `thinkingBudget: 0` set to prevent reasoning hangs.

### Cache & Rate Limits
* **Extension Cache:** In-memory LRU Map capped at 500 entries, 24h TTL, indexed by fast `djb2` hash string.
* **Next.js Cache:** [`lib/cache.ts`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/lib/cache.ts) uses SHA-256 keys, 500 entry limit, 24h TTL.
* **Rate Limits:** Extension defaults to 15 req/min, 100 req/day. Web defaults to 8 req/min, 30 req/day per IP, 800 global.

---

## 📡 Message Protocol Catalog (`chrome.runtime.onMessage`)

| Action Name | Source | Key Payload Fields | Handler |
|---|---|---|---|
| `TRUST_AURA` | `content.js` | `{ text, isAd }` | `handleTrustAura` |
| `SCAN_POLICY` | Popup/Dash/UI | `{ url, urls, siteName, text }` | `handlePolicy` |
| `SCAN_FACT` | Popup/Dash/UI | `{ text }` | `handleFact` |
| `SCAN_IMAGE` | Dash/UI | `{ imageUrl, imageData }` | `handleImage` |
| `GEMINI_GENERATE` | Dashboard | `{ prompt, imageBase64, imageMime }` | `callGemini` |
| `FETCH_IMAGE_BASE64` | Dashboard | `{ url }` | Background CORS bypass fetcher |
| `PARENTAL_MODE_ON` | Popup | `{ whitelist: string[] }` | `enforceOnAllTabs` + whitelist save |
| `PARENTAL_MODE_OFF` | Popup | `{}` | Clears active whitelist |
| `PING` | UI | `{}` | Returns rate limit counters |
| `SET_FEED_SCANNER` | Popup | `{ enabled: boolean }` | Toggles Trust Aura in content script |
| `SET_BLUR_ADULT` | Popup | `{ enabled: boolean }` | Toggles adult blur in content script |

---

## ⚠️ Critical Architectural Invariants (DO NOT BREAK)

1. **Manifest V3 Directory Rules:** Chrome extensions disallow folders starting with `_`. Next.js outputs `_next/`. The build script `build-extension.ps1` **must** rename `_next` to `next_assets` and rewrite references.
2. **CSP Disallows Inline Scripts:** Chrome MV3 blocks inline `<script>` tags. `build-extension.ps1` extracts all inline scripts into external files (`*-inline-*.js`) and removes `async` attributes to prevent React hydration mismatches.
3. **Static Export Constraint:** `next.config.js` uses `output: 'export'`. Server-side API route handlers (`POST`, `PUT`, dynamic server rendering) cannot be executed by Next.js in static export mode. All dynamic AI logic belongs in `extension/background.js` or client-side fallbacks.
4. **Router Patch (`route-fix.js`):** Next.js expects `/analyze/`, but extensions open `chrome-extension://<id>/analyze/index.html`. `route-fix.js` must be injected into the `<head>` of static HTML exports to rewrite the URL state before React hydrates.
5. **CORS Isolation:** Browser extension pages and content scripts cannot directly fetch images from arbitrary external origins without CORS blocks. Use `action: "FETCH_IMAGE_BASE64"` to fetch via the background service worker.

---

## 📝 Agent Maintenance Protocol (How to Update This Memory Box)

Whenever you (an AI agent or developer) make changes to this repository, follow this protocol:
1. **Identify the affected subsystem:** Check if your change touches UI components, background workers, content scripts, message actions, or build scripts.
2. **Implement and test the change.**
3. **Update [`MEMORY.md`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/MEMORY.md):**
   - If you added/renamed a file, update the **Repository & Symbol Map**.
   - If you added a message action, update the **Message Protocol Catalog**.
   - If you changed build behavior, update the **Command Cheat Sheet** or **Architectural Invariants**.
   - Add a brief entry to the **Living Changelog & State Ledger** below.

---

## 📜 Living Changelog & State Ledger

| Timestamp (Local) | Agent / Author | Action / Change Summary |
|---|---|---|
| **2026-11-07 00:12** | Antigravity AI | Generated comprehensive technical specification document [`agent.md`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/agent.md). |
| **2026-11-07 00:23** | Antigravity AI | Created [`MEMORY.md`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/MEMORY.md) (Memory Box) to provide an ultra-dense, token-efficient context cache for future agents, covering repository layout, subsystems, AI cascade, message bus, and MV3 build invariants. |
| **2026-11-07 00:39** | Antigravity AI | Created [`MASTER_PROMPT.md`](file:///f:/AOT/Agentic%20Chase/ambient-Shield/MASTER_PROMPT.md) containing the small master directive for onboarding future agents to work seamlessly with the Memory Box. |
| **2026-11-07 01:33** | Antigravity AI | Fixed broken pipelines and features: (1) Replaced non-existent `gemini-2.5-flash` model with valid `gemini-1.5-flash`/`gemini-2.0-flash` cascade in `lib/ai.ts` and `lib/extension-api.ts`. (2) Corrected snake_case `inline_data` to camelCase `inlineData` in `lib/extension-api.ts`. (3) Connected `restoreRef` in `ImageAnalyzer.tsx` & `AnalyzeTabs.tsx` to fix broken context-menu intent & history restore for images. (4) Fixed Next.js subdirectory asset 404s by switching from relative `./` to origin-rooted `/next_assets/` in `next.config.js` and `build-extension.ps1`. (5) Overhauled `build-extension.sh` to mirror full MV3 packaging pipeline. |



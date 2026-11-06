# 🤖 Ambient Shield — Agent Master Prompt

> **Copy and paste this prompt to any new AI agent (Cursor, Claude, Copilot, ChatGPT, Antigravity) working on this codebase.**

---

```markdown
You are an expert developer and digital safety specialist working on the **Ambient Shield** codebase.

### STEP 1: CONTEXT INGESTION (DO THIS FIRST)
Before inspecting files or writing code, read `MEMORY.md` in the project root. It contains:
- Complete file map and architecture index
- Dual-runtime specs (Chrome MV3 Extension vs. Next.js Static Web Mode)
- Subsystem details (Trust Aura, Fact Checker, Policy Analyzer, Image/Deepfake Scanner, Firewall, Parental Mode)
- AI resilience cascade and in-memory cache/rate-limiting rules
- Complete IPC message protocol catalog (`chrome.runtime.onMessage`)
- Critical invariants and build rules

DO NOT waste tokens reading through all source files. Rely on `MEMORY.md` as your primary source of truth, and read only the specific files you need to modify.

### STEP 2: ARCHITECTURAL INVARIANTS (NEVER BREAK)
1. **Chrome MV3 Compliance:**
   - NEVER add inline `<script>` tags to HTML files (forbidden by MV3 CSP).
   - Any dynamic background work belongs in `extension/background.js`.
   - Never reference `/_next/` paths directly; the build script renames them to `/next_assets/`.
2. **Next.js Static Export:**
   - The app compiles via `output: 'export'`. No server-side POST/PUT API handlers are allowed.
   - All AI calls from UI go through `lib/extension-api.ts` -> `chrome.runtime.sendMessage` -> `background.js` (with web fallback for standalone browser preview).
3. **AI Gateway & Cost Discipline:**
   - Fact-checking and privacy policy analysis must remain zero-cost/offline at the edge unless explicitly asked otherwise.
   - For cloud AI calls, preserve the 4-model fallback cascade (`gemini-2.0-flash` -> `gemini-1.5-pro` -> `gemini-1.5-flash` -> `gemini-1.5-flash-8b`) and maintain `thinkingBudget: 0`.
4. **Build Pipeline:**
   - After altering Next.js code or extension files, verify that `build-extension.ps1` (or `build-extension.sh`) accounts for the changes.

### STEP 3: SYNCHRONIZE THE MEMORY BOX (MANDATORY)
After making any code, file, or architectural modifications:
1. Update `MEMORY.md`:
   - Update the **Repository & Symbol Map** if files were created, moved, or deleted.
   - Update the **Message Protocol Catalog** if message actions or payloads changed.
   - Add a row to the **Living Changelog & State Ledger** with the current timestamp, your identity, and a summary of what changed.
2. Maintain documentation integrity. Keep code and memory perfectly in sync.
```


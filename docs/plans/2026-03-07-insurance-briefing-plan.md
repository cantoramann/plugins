# Insurance Briefing Plugin — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a Claude Code plugin that generates a daily intelligence briefing for Turkish insurance professionals using a multi-agent pipeline.

**Architecture:** 5-stage pipeline (memory → 4 scouts → cross-pollinator → composer → personalizer) mirroring the existing `daily-briefing/` plugin. All files are markdown, JSON, YAML, and shell — no compiled code.

**Tech Stack:** Claude Code plugin system (agents, commands, skills, hooks), AWS S3, shell scripting.

**Reference:** Design doc at `docs/plans/2026-03-07-insurance-briefing-design.md`. Existing `daily-briefing/` plugin as structural template.

---

### Task 1: Plugin Scaffold & Manifest

**Files:**
- Create: `insurance-briefing/.claude-plugin/plugin.json`
- Create: `insurance-briefing/briefings/tracker.json`
- Create: `insurance-briefing/profiles/user-example.yaml`
- Modify: `.claude-plugin/marketplace.json`

**Step 1: Create plugin.json**

```json
{
  "name": "insurance-briefing",
  "description": "Daily intelligence briefing for Turkish insurance professionals — regulatory, market, industry, and cross-domain analysis with personalization",
  "version": "0.1.0",
  "author": {
    "name": "Can Toraman"
  },
  "keywords": ["insurance", "sigorta", "briefing", "turkey", "multi-agent"]
}
```

**Step 2: Create empty tracker**

```json
{
  "meta": {
    "last_updated": null,
    "briefings_generated": 0
  },
  "stories": []
}
```

**Step 3: Create example user profile**

```yaml
# Example user profile — copy to user-{id}.yaml and customize
name: Örnek Kullanıcı
company: Örnek Sigorta A.Ş.
company_type: insurance_company  # insurance_company | brokerage | reinsurer
role: Genel Müdür Yardımcısı
focus_areas:
  - motor
  - property_cat
  - digital_distribution
company_context: >
  Kısa şirket açıklaması: büyüklük, ana branşlar,
  stratejik odak, halka açıklık durumu.
```

**Step 4: Update marketplace.json**

Add the insurance-briefing entry to the `plugins` array in `.claude-plugin/marketplace.json`.

**Step 5: Commit**

```bash
git add insurance-briefing/.claude-plugin/plugin.json insurance-briefing/briefings/tracker.json insurance-briefing/profiles/user-example.yaml .claude-plugin/marketplace.json
git commit -m "Scaffold insurance-briefing plugin with manifest and empty tracker"
```

---

### Task 2: Domain Context Reference

**Files:**
- Create: `insurance-briefing/skills/insurance-briefing/references/insurance-domain-context.md`

This is the shared domain knowledge file that all agents reference. Contains: key Turkish insurers, major brokerages, regulatory bodies, common acronyms, reinsurance calendar, source URLs.

**Step 1: Write insurance-domain-context.md**

Content should cover:

1. **Regulatory Bodies**: SEDDK (Sigortacılık ve Özel Emeklilik Düzenleme ve Denetleme Kurumu), Hazine ve Maliye Bakanlığı, TSB (Türkiye Sigorta Birliği), DASK (Doğal Afet Sigortaları Kurumu), Güvence Hesabı
2. **Top Turkish Insurers** (by premium volume): Anadolu Sigorta, Aksigorta, Allianz Türkiye, AXA Sigorta, Sompo Sigorta, Güneş Sigorta, HDI Sigorta, Mapfre Sigorta, Groupama Sigorta, Zurich Sigorta, etc.
3. **Major Brokerages**: Marsh Türkiye, Aon Türkiye, WTW Türkiye, Acrisure, plus major local brokerages
4. **Common Acronyms**: SEDDK, TSB, DASK, SBM (Sigorta Bilgi ve Gözetim Merkezi), TSEV, teknik kâr, hasar prim oranı, sedan, reasürans, trete, fakultatif, CAT, ILS, retrosesyon
5. **Key Source URLs**: SEDDK (seddk.gov.tr), Resmi Gazete (resmigazete.gov.tr), TSB (tsb.org.tr), Sigorta Medya (sigortamedya.com.tr), Sigortacı Gazetesi (sigortacigazetesi.com.tr), Dünya Gazetesi (dunya.com), Bloomberg HT (bloomberght.com), Artemis (artemis.bm), AM Best (ambest.com), Reinsurance News (reinsurancene.ws)
6. **BIST Insurance Tickers**: AKGRT (Aksigorta), ANHYT (Anadolu Hayat), ANSGR (Anadolu Sigorta), GUSGR (Güneş Sigorta), RAYSG (Ray Sigorta), TURSG (Türk Sigorta)
7. **Calendar**: Quarterly earnings seasons, annual TSB statistics publication (~March), SEDDK circular cadence, 1/1 and 7/1 reinsurance treaty renewal dates

**Step 2: Commit**

```bash
git add insurance-briefing/skills/insurance-briefing/references/insurance-domain-context.md
git commit -m "Add insurance domain context reference (companies, regulators, sources)"
```

---

### Task 3: Scout Agents (4 files)

**Files:**
- Create: `insurance-briefing/agents/regulatory-intelligence-scout.md`
- Create: `insurance-briefing/agents/market-data-scout.md`
- Create: `insurance-briefing/agents/industry-news-scout.md`
- Create: `insurance-briefing/agents/cross-domain-implications-scout.md`

Each follows the same frontmatter pattern as `daily-briefing/agents/tech-scout.md`: name, description, example, model (sonnet), color, tools (WebSearch, WebFetch, Read, Write).

**Step 1: Write regulatory-intelligence-scout.md**

Role: Monitor SEDDK, Resmi Gazete, TSB for regulatory developments. Search queries should target: "SEDDK duyuru", "sigorta mevzuat", "Resmi Gazete sigorta", "TSB genelge", "sigortacılık düzenleme". Output format matches daily-briefing scout format but with a "Regulatory Impact" field per story (which branches/products affected, timeline, severity).

**Step 2: Write market-data-scout.md**

Role: Track BIST insurance tickers, macro indicators, financial press. Search queries: "BIST sigorta hisseleri", "Aksigorta Anadolu Sigorta hisse", "Bloomberg HT sigorta", "Dünya Gazetesi sigorta", "sigorta prim üretimi". Output includes market data points (stock prices, premium volumes) and macro context (interest rates, inflation, FX — all relevant to insurance investment portfolios and pricing).

**Step 3: Write industry-news-scout.md**

Role: Cover Sigorta Medya, Sigortacı Gazetesi, TSB press, company announcements, global reinsurance. Search queries split into Turkish sources ("Sigorta Medya", "Sigortacı Gazetesi", "sigorta sektör haberleri", "reasürans Türkiye") and global reinsurance ("Artemis catastrophe bond", "AM Best rating action", "reinsurance renewal", "natural catastrophe insurance"). Output includes a "Küresel Reasürans" subsection for global items.

**Step 4: Write cross-domain-implications-scout.md**

Role: The differentiator. Searches broadly — tech, climate, geopolitics, demographics, legal, science — and translates into insurance implications. NOT an insurance news scout. Searches for non-insurance developments, then analyzes them through the insurance lens. Each finding must include: (a) the development, (b) the insurance mechanism (underwriting, actuarial, regulatory, reinsurance pricing), (c) which insurance branches/products are affected. Search queries are broad and rotating: "autonomous vehicle regulation 2026", "climate model update", "EU AI Act liability", "Turkey earthquake risk", "cyber attack recent", "demographic aging Turkey", "Strait of Hormuz shipping". Must ground every implication — no speculation.

**Step 5: Commit**

```bash
git add insurance-briefing/agents/regulatory-intelligence-scout.md insurance-briefing/agents/market-data-scout.md insurance-briefing/agents/industry-news-scout.md insurance-briefing/agents/cross-domain-implications-scout.md
git commit -m "Add 4 function-specialized scout agents for insurance briefing"
```

---

### Task 4: Cross-Pollinator Agent

**Files:**
- Create: `insurance-briefing/agents/cross-pollinator.md`

**Step 1: Write cross-pollinator.md**

Adapted from `daily-briefing/agents/cross-pollinator.md`. Key differences:
- Receives 4 scout reports (not 5)
- Curates into the insurance-specific section structure: Gündem (4-6 items), Derinlemesine (2-3 features), Radar (1-2 cross-domain implications), Gelişmeler (conditional, max 3), Küresel Reasürans (2-3 items)
- Applies the Practitioner Test and Implications Test instead of Pragmatist/Curiosity tests
- Continuity rules same as daily-briefing: NEW/UPDATE/STALE classification, Gündem allows max 2 updates, Radar must be new, Gelişmeler only for material updates
- Editorial plan output format matches the section structure above
- Frontmatter: model opus, color yellow, tools Read/Write

**Step 2: Commit**

```bash
git add insurance-briefing/agents/cross-pollinator.md
git commit -m "Add cross-pollinator agent for insurance editorial curation"
```

---

### Task 5: Briefing Composer Agent

**Files:**
- Create: `insurance-briefing/agents/briefing-composer.md`

**Step 1: Write briefing-composer.md**

Adapted from `daily-briefing/agents/briefing-composer.md`. Key differences:
- Writes in Turkish. Section headers in Turkish.
- Voice: analytical, confident, collegial. Written for insurance practitioners with 10+ years experience. No jargon explanations for insurance terms.
- Section structure: Hook title → Gündem → Derinlemesine → Radar → Gelişmeler (conditional) → Küresel Reasürans → Footer
- Radar section writing rules: every implication must name the insurance mechanism explicitly. Explain the non-insurance development briefly (the audience is insurance experts, not tech/climate experts). Then connect to insurance with specifics.
- Developing Stories framing: "Dün bahsettiğimiz..." or "Geçen haftadan beri..." — never re-explain backstory.
- Footer: "*Sigorta Brifing — Türk sigorta profesyonelleri için günlük istihbarat.*"
- Voice principles adapted: be specific with Turkish insurance data, use Turkish financial conventions, no filler (same no-filler rules), weave cross-section threads.
- Frontmatter: model opus, color magenta, tools Read/Write/WebSearch/WebFetch

**Step 2: Commit**

```bash
git add insurance-briefing/agents/briefing-composer.md
git commit -m "Add briefing composer agent for Turkish-language insurance briefing"
```

---

### Task 6: Personalizer Agent

**Files:**
- Create: `insurance-briefing/agents/personalizer.md`

**Step 1: Write personalizer.md**

New agent (no daily-briefing equivalent). Receives:
1. The base briefing (full markdown)
2. All user profiles (YAML files from `profiles/`)

For each user, generates 1-2 personalized lines connecting the day's content to their company, role, and focus areas. Output is a JSON file `personalization-YYYY-MM-DD.json` with the schema from the design doc.

Rules:
- Batch all users in one pass
- Each personalization line must reference a specific section of the briefing
- Lines should be actionable: "Aksigorta'nın motor portföyü için: SEDDK'nın yeni hasar bildirim süresi, tazminat rezerv süreçlerinizi doğrudan etkiliyor" — not generic
- If no content is relevant to a user's profile, output an empty lines array (don't force it)
- Frontmatter: model sonnet (or haiku for cost), color green, tools Read/Write

**Step 2: Commit**

```bash
git add insurance-briefing/agents/personalizer.md
git commit -m "Add personalizer agent for per-user briefing customization"
```

---

### Task 7: Skill Entry Point & References

**Files:**
- Create: `insurance-briefing/skills/insurance-briefing/SKILL.md`
- Create: `insurance-briefing/skills/insurance-briefing/references/editorial-philosophy.md`
- Create: `insurance-briefing/skills/insurance-briefing/references/briefing-structure.md`
- Create: `insurance-briefing/skills/insurance-briefing/references/scout-strategies.md`
- Create: `insurance-briefing/skills/insurance-briefing/references/tracker-schema.md`

**Step 1: Write SKILL.md**

Adapted from `daily-briefing/skills/daily-briefing/SKILL.md`. Describes the insurance briefing system: editorial philosophy, pipeline architecture (4 scouts, cross-pollinator, composer, personalizer), section structure, and pointers to reference files.

Frontmatter trigger: "insurance briefing", "sigorta brifing", "insurance digest", "sigorta haberleri".

**Step 2: Write editorial-philosophy.md**

Adapted from daily-briefing's version. Replace Pragmatist/Curiosity tests with Practitioner/Implications tests. Voice guidelines for each section in Turkish context. Quality benchmarks: at least 2 domains in Gündem, at least 1 Radar item, Derinlemesine 300-500 words each, no filler.

**Step 3: Write briefing-structure.md**

Section-by-section spec matching the design: Gündem, Derinlemesine, Radar, Gelişmeler, Küresel Reasürans. File naming: `briefing-YYYY-MM-DD.md`. Selection criteria per section.

**Step 4: Write scout-strategies.md**

4 scout sections with primary search queries, quality criteria, and "look beyond headlines" guidance. Adapted for insurance domain — specific Turkish and English query templates, source prioritization, Turkish-language search tips.

**Step 5: Write tracker-schema.md**

Same schema as daily-briefing's tracker. Copy and adapt — domain values change to insurance-specific ones (regulatory, market, industry, reinsurance, cross-domain).

**Step 6: Commit**

```bash
git add insurance-briefing/skills/
git commit -m "Add skill entry point and reference docs for insurance briefing"
```

---

### Task 8: Command — /briefing Orchestrator

**Files:**
- Create: `insurance-briefing/commands/briefing.md`

**Step 1: Write briefing.md**

Adapted from `daily-briefing/commands/briefing.md`. Same stage structure with these differences:

- **Stage 0**: Same memory loading logic. Reads `${CLAUDE_PLUGIN_ROOT}/briefings/tracker.json` and most recent `briefing-*.md`.
- **Stage 1**: Launches 4 scouts (not 5) in parallel. Each gets continuity brief appended. Uses `subagent_type: "general-purpose"` and includes the system prompt from the corresponding agent file.
- **Stage 2**: Cross-pollinator receives 4 scout reports + continuity brief + tracker. Model: opus.
- **Stage 3**: Composer writes the Turkish briefing. Model: opus.
- **Stage 4**: NEW — Personalizer. Reads all YAML files from `${CLAUDE_PLUGIN_ROOT}/profiles/`. If no profiles exist, skip this stage. Passes base briefing + profiles to personalizer agent. Model: sonnet. Saves output as `personalization-YYYY-MM-DD.json` in `${CLAUDE_PLUGIN_ROOT}/briefings/`.
- **Stage 5**: Save briefing, update tracker, present to user.

Frontmatter: description, allowed-tools (Task, Read, Write, Glob, Grep, WebSearch, WebFetch), model opus.

**Step 2: Commit**

```bash
git add insurance-briefing/commands/briefing.md
git commit -m "Add /briefing command orchestrating 5-stage insurance pipeline"
```

---

### Task 9: Hooks — S3 Sync

**Files:**
- Create: `insurance-briefing/hooks/hooks.json`
- Create: `insurance-briefing/hooks/sync-briefing-to-s3.sh`

**Step 1: Write hooks.json**

Same structure as daily-briefing. PostToolUse hook on Write tool:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/insurance-briefing/hooks/sync-briefing-to-s3.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**Step 2: Write sync-briefing-to-s3.sh**

Adapted from `daily-briefing/hooks/sync-briefing-to-s3.sh`. Two differences:
1. S3 key prefix is `content/insurance/tr/` instead of `content/en/`
2. Also handles personalization JSON: if the written file matches `briefings/personalization-*.json`, upload to `personalization/insurance/YYYY-MM-DD.json`
3. Frontmatter `language: tr` and `author: "Sigorta Brifing"`
4. Same .env loading: SCRIPT_DIR → PLUGIN_DIR → REPO_ROOT

Make executable: `chmod +x insurance-briefing/hooks/sync-briefing-to-s3.sh`

**Step 3: Commit**

```bash
git add insurance-briefing/hooks/
git commit -m "Add S3 sync hooks for briefing and personalization uploads"
```

---

### Task 10: Update Repo Docs

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`

**Step 1: Update CLAUDE.md**

Add `insurance-briefing/` to the Plugins section and update the Repository Structure tree to show the new plugin directory.

**Step 2: Update README.md**

Add insurance-briefing to the plugin listing table.

**Step 3: Commit**

```bash
git add CLAUDE.md README.md
git commit -m "Update repo docs with insurance-briefing plugin"
```

---

### Task 11: Verify Plugin Structure

**Step 1: Verify all files exist**

Run: `find insurance-briefing -type f | sort`

Expected output should match the file structure from the design doc (all 20+ files present).

**Step 2: Verify marketplace.json lists both plugins**

Run: `cat .claude-plugin/marketplace.json`

Verify both `daily-briefing` and `insurance-briefing` entries exist.

**Step 3: Verify hooks.json paths are correct**

Run: `cat insurance-briefing/hooks/hooks.json`

Verify the command path uses `$CLAUDE_PROJECT_DIR/insurance-briefing/hooks/sync-briefing-to-s3.sh`.

**Step 4: Verify sync script is executable**

Run: `ls -la insurance-briefing/hooks/sync-briefing-to-s3.sh`

Verify `-rwxr-xr-x` permissions.

**Step 5: Verify .env path traversal in sync script**

Read `insurance-briefing/hooks/sync-briefing-to-s3.sh` and confirm SCRIPT_DIR → PLUGIN_DIR → REPO_ROOT → .env path is correct (same 2-level traversal as daily-briefing).

**Step 6: Final commit if any fixes needed**

```bash
git add -A && git commit -m "Fix any structural issues found during verification"
```

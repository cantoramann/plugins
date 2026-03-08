# Insurance Briefing Plugin — Design Document

Date: 2026-03-07

## Overview

A daily intelligence briefing for Turkish insurance professionals (insurance company executives, brokerage owners). Delivered as a Claude Code plugin in the `plugins` repo alongside `daily-briefing/`. Same multi-agent pipeline pattern, adapted for a domain-expert audience.

## Pipeline Architecture

5-stage pipeline:

### Stage 0: Load Memory

Read `tracker.json` and the most recent briefing to build a continuity brief. Enforces no-repetition: scouts receive explicit lists of what was already covered, what's developing, and what to skip. Same logic as daily-briefing.

### Stage 1: 4 Function-Specialized Scouts (parallel, sonnet)

1. **regulatory-intelligence-scout** — SEDDK announcements, Resmi Gazete (filtered for insurance/Hazine keywords), TSB circulars, proposed regulatory changes. Outputs structured findings with regulatory impact assessment.

2. **market-data-scout** — BIST insurance tickers (Aksigorta, Anadolu Sigorta, Güneş Sigorta, etc.), Bloomberg HT macro context, Dünya Gazetesi financial coverage, premium volume data, investment return indicators.

3. **industry-news-scout** — Sigorta Medya, Sigortacı Gazetesi, TSB press releases, company announcements (M&A, product launches, partnerships), global reinsurance sources (Artemis, AM Best, Reinsurance News), catastrophe events.

4. **cross-domain-implications-scout** — Searches broadly across tech, climate, geopolitics, demographics, legal, science — anything — and translates findings into insurance implications. Every implication must be grounded in concrete insurance logic (underwriting, actuarial, regulatory precedent, reinsurance pricing). This is the signature differentiator.

### Stage 2: Cross-Pollinator (opus)

Receives all 4 scout reports + continuity brief + tracker. Curates the editorial plan: selects stories, identifies connections, picks the Radar analysis topic, enforces continuity rules (no repetition, narrative threading for developing stories).

### Stage 3: Briefing Composer (opus)

Writes the final Turkish-language briefing from the editorial plan. Tone: sharp, analytical, expert-level — morning coffee, not homework.

### Stage 4: Personalization Batch (sonnet or haiku)

Reads the base briefing + all user profiles. For each user, generates 1-2 personalized summary lines based on their company type, role, and focus areas. Outputs a JSON mapping. One cheap model call per day regardless of user count.

### Stage 5: Save + Tracker Update + S3 Upload

Save the briefing, update `tracker.json`, upload to S3 via PostToolUse hook.

## Briefing Sections

### Header

Hook title referencing 2-3 key stories. Not a date label.

Good: "SEDDK Deprem Muafiyetlerini Sıkılaştırıyor, Aksigorta Q4'te Beklentileri Aştı, Otonom Araçlar Sorumluluk Sigortasını Yeniden Yazıyor"
Bad: "Sigorta Brifing — 7 Mart 2026"

### Section 1: Gündem (The Rundown)

4-6 headline items. Most important insurance-relevant events. Each: the fact + the "so what" for insurance in 2-4 sentences.

### Section 2: Derinlemesine (Feature Stories)

2-3 medium-depth pieces (300-500 words). Stories where analysis matters more than the headline.

### Section 3: Radar (Cross-Domain Implications)

The signature section. 1-2 pieces (400-700 words total). Non-insurance developments translated into insurance implications. Could be tech, climate, demographics, legal, geopolitical — anything. Every claim grounded in concrete insurance logic: underwriting, actuarial, regulatory, reinsurance pricing.

### Section 4: Gelişmeler (Developing Stories)

Conditional. Short updates on stories from previous briefings. Never re-explains backstory. "Dün bahsettiğimiz X konusunda yeni bir gelişme var..." Max 3 items.

### Section 5: Küresel Reasürans (Global Reinsurance Pulse)

2-3 brief items from Artemis, AM Best, Reinsurance News. CAT bond activity, rating actions, global catastrophe pricing trends.

## Editorial Voice & Standards

### Tone

Analytical, confident, collegial. Written for practitioners with 10+ years of experience. No jargon explanations for insurance terms (sedan, reasürans, hasar prim oranı, teknik kâr). Cross-domain topics in Radar section: briefly explain the non-insurance side.

### Language

Turkish-first. English used only for: direct quotes from English sources, natively English company/product names, and brief English translation/summary per content block.

### The Two Tests

**Practitioner Test:** "Does this change how an insurance professional would underwrite, price, reserve, invest, or make a strategic decision?"

**Implications Test:** "Does this non-insurance development have a concrete, articulable insurance mechanism?" The mechanism must be specific: "shifts the liability profile for motor underwriters because X" — not "could affect insurance."

### Content Continuity

No repetition without material updates. Narrative threading via tracker: "dün bahsettiğimiz..." framing. Cross-pollinator enforces freshness. Same tracker schema as daily-briefing.

### Radar Standard

Every implication must name the insurance mechanism. Solid ground, not speculation. Originality and correctness are paramount. Multiple implications per briefing are fine when warranted.

## User Profiles & Personalization

### Profile Format

`profiles/user-{id}.yaml`:

```yaml
name: Ahmet Yılmaz
company: Aksigorta
company_type: insurance_company  # insurance_company | brokerage | reinsurer
role: Genel Müdür Yardımcısı
focus_areas:
  - motor
  - property_cat
  - digital_distribution
company_context: >
  Mid-size composite insurer, strong in motor,
  expanding into digital channels. Publicly traded on BIST.
```

### Personalization Agent

Receives base briefing + all profiles. Generates 1-2 lines per user connecting the day's content to their context. Outputs `personalization-YYYY-MM-DD.json`:

```json
{
  "date": "2026-03-07",
  "personalizations": {
    "user-ahmet": {
      "lines": ["Aksigorta'nın motor portföyü için: ..."],
      "relevant_sections": ["gündem-1", "radar-1"]
    }
  }
}
```

### Onboarding

User gives name + company. AI researches the company and presents a profile for approval.

## Plugin File Structure

```
insurance-briefing/
  .claude-plugin/
    plugin.json
  agents/
    regulatory-intelligence-scout.md
    market-data-scout.md
    industry-news-scout.md
    cross-domain-implications-scout.md
    cross-pollinator.md
    briefing-composer.md
    personalizer.md
  briefings/
    tracker.json
  commands/
    briefing.md
  hooks/
    hooks.json
    sync-briefing-to-s3.sh
  profiles/
    user-example.yaml
  skills/
    insurance-briefing/
      SKILL.md
      references/
        editorial-philosophy.md
        briefing-structure.md
        scout-strategies.md
        tracker-schema.md
        insurance-domain-context.md
```

## S3 & Delivery

- Same S3 bucket (`daily-intelligence-reporter`), different prefix: `content/insurance/tr/YYYY-MM-DD.md`
- Personalization JSON: `personalization/insurance/YYYY-MM-DD.json`
- Frontend: insurance.daily.cantoramann.com, same ISR pattern (10-min revalidation)
- Personalization JSON fetched client-side after page load
- Same `.env` at repo root, no new secrets needed

## marketplace.json Update

```json
{
  "name": "plugins",
  "owner": { "name": "Can Toraman" },
  "plugins": [
    {
      "name": "daily-briefing",
      "source": "./daily-briefing",
      "description": "Multi-agent daily briefing — 7 agents produce a curated news digest"
    },
    {
      "name": "insurance-briefing",
      "source": "./insurance-briefing",
      "description": "Daily intelligence briefing for Turkish insurance professionals"
    }
  ]
}
```

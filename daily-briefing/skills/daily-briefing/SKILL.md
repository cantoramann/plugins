---
name: daily-briefing
description: >
  This skill should be used when the user asks for a "daily briefing",
  "morning briefing", "news summary", "what's happening today",
  "daily digest", or wants a curated overview of news and trends across
  technology, business, policy, science, and culture. Also triggers when
  the user mentions "briefing plugin" or wants to understand the editorial
  philosophy behind the daily briefing system.
version: 0.1.0
---

# Daily Briefing System

A multi-agent pipeline that produces a curated daily briefing blending hard news with intellectually curious cross-domain content.

## Editorial Philosophy

The briefing serves two audiences living in the same person:

1. **The Pragmatist** — wants to know what happened, what changed, and what it means for their work and decisions. Morning Brew's directness: no filler, sharp takes, efficient reading.

2. **The Curious Intellectual** — wants to understand *why* things happen and how seemingly unrelated domains connect. MIT Technology Review's depth: backstories, hidden connections, the "I never thought about it that way" moments.

Every briefing must serve both. Headlines and feature stories serve the pragmatist. The deep dive and curiosity corner serve the intellectual. The best pieces serve both simultaneously.

## Pipeline Architecture

The briefing is produced by a 3-stage multi-agent pipeline:

### Stage 1: Domain Scouts (parallel)

Five specialized agents search their domains simultaneously:

- **tech-scout** — Technology, AI, software, hardware, open source
- **business-scout** — Markets, earnings, M&A, startups, economic indicators
- **policy-scout** — Regulation, trade, elections, geopolitics, governance
- **science-scout** — Research, health, biotech, climate, space
- **culture-scout** — Consumer trends, cultural phenomena, entertainment, social shifts

Each scout returns a structured list of 5-8 candidate stories ranked by importance and novelty.

### Stage 2: Cross-Pollinator (editorial intelligence)

A single agent receives all scout outputs and performs editorial curation:

- Selects the best 8-12 stories across all domains
- Identifies 2-3 cross-domain connections
- Picks one story for deep-dive treatment
- Flags 2-3 curiosity pieces
- Outputs a structured editorial plan

### Stage 3: Briefing Composer

A single agent takes the editorial plan and writes the final markdown briefing with consistent voice and structure.

## Briefing Sections

See `references/briefing-structure.md` for the full section-by-section specification.

## Scout Strategies

See `references/scout-strategies.md` for domain-specific search strategies and quality criteria.

## Editorial Standards

See `references/editorial-philosophy.md` for the full editorial guidelines, the curiosity content framework, and quality benchmarks.

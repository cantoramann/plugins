---
description: Generate today's daily briefing using the multi-agent pipeline
allowed-tools: Task, Read, Write, WebSearch, WebFetch, Glob, Grep
model: opus
---

Generate today's daily briefing by orchestrating the multi-agent pipeline. Follow these stages exactly:

**Storage note:** All generated files (briefings, tracker, scout reports) are saved to `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/`. Agent definitions are read from `${CLAUDE_PLUGIN_ROOT}/agents/`.

## Stage 0: Load Memory (pre-processing)

Before launching scouts, build the continuity context that all agents will need:

1. **Read the story tracker:** Read `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/tracker.json`. This contains every story previously covered, with dates, key facts, and current status. If the file doesn't exist or is empty, skip — this is the first briefing.

2. **Read the previous briefing:** Use Glob to find the most recent `briefing-*.md` file in `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/`. Read it. If none exists, skip.

3. **Build the continuity prompt:** From the tracker, extract:
   - Stories with status `"developing"` — these are ongoing and should be checked for updates
   - Stories covered in the last 3 days — these should not be repeated unless there's a material update
   - The previous briefing's deep dive topic — avoid repeating the same deep dive angle

   Format this as a concise **continuity brief** (aim for under 800 words) that will be passed to scouts and the cross-pollinator. Structure:

   ```
   ## Continuity Brief

   ### Developing Stories (check for updates)
   - [story id]: [headline]. Last covered [date]. Last known state: [state]. Key facts already reported: [facts].
   ...

   ### Recently Covered (do NOT repeat unless material update)
   - [story id]: [headline]. Covered [date(s)].
   ...

   ### Previous Deep Dive
   - Topic: [topic]. Covered [date]. Do not reuse this angle.
   ```

## Stage 1: Launch Domain Scouts (parallel)

Launch ALL 5 scout agents simultaneously using the Task tool. Each scout must search for today's news in their domain. Send all 5 Task calls in a single message so they run in parallel:

1. **tech-scout** — Find today's top technology and AI stories
2. **business-scout** — Find today's top business and markets stories
3. **policy-scout** — Find today's top policy and geopolitics stories
4. **science-scout** — Find today's top science and health stories
5. **culture-scout** — Find today's most interesting culture and consumer trend stories

For each Task call, use `subagent_type: "general-purpose"` and include the full system prompt from the corresponding agent definition file in `${CLAUDE_PLUGIN_ROOT}/agents/`. Tell each scout today's date so their searches are current.

**IMPORTANT:** Append the continuity brief from Stage 0 to each scout's prompt. Instruct each scout to:
- Check developing stories in their domain for updates
- Flag any story that is a material update to a previously covered story (mark as `[UPDATE]`)
- Avoid resurfacing stories that were already covered unless something changed
- Still prioritize genuinely new stories over updates

Wait for ALL 5 scouts to complete before proceeding.

## Stage 2: Cross-Pollination (editorial curation)

Once all scouts have returned their reports, launch the **cross-pollinator** agent using the Task tool:

- Pass ALL 5 scout reports as input
- **Also pass the full continuity brief and the full tracker JSON**
- The cross-pollinator will read all reports, apply continuity rules, select the best stories, identify cross-domain connections, and produce a structured editorial plan
- Use `subagent_type: "general-purpose"` and include the system prompt from `${CLAUDE_PLUGIN_ROOT}/agents/cross-pollinator.md`
- Use `model: "opus"` for this agent — editorial judgment requires the strongest reasoning

Wait for the cross-pollinator to complete before proceeding.

## Stage 3: Compose the Briefing

Launch the **briefing-composer** agent using the Task tool:

- Pass the editorial plan AND all 5 scout reports as input
- The composer writes the final markdown briefing following the structure and voice guidelines
- Use `subagent_type: "general-purpose"` and include the system prompt from `${CLAUDE_PLUGIN_ROOT}/agents/briefing-composer.md`
- Use `model: "opus"` for this agent — writing quality matters

Wait for the composer to complete.

## Stage 4: Translate to Turkish

After the English briefing is composed, translate it to Turkish for `daily.cantoramann.com/tr`.

1. Launch a translation agent using the Task tool with `subagent_type: "general-purpose"` and `model: "sonnet"`.
2. Pass it the full English briefing markdown and the following system prompt:

   ```
   You are a world-class translator specializing in engaging, conversational content.
   Translate the provided daily briefing from English to Turkish while preserving its soul — not just its words.

   Voice rules:
   - Write naturally as a native Turkish speaker would talk
   - Keep the punchy rhythm — short sentences that hit, longer ones that flow
   - Preserve humor, wit, and personality (adapt jokes/references for Turkish cultural fit)
   - Use colloquial Turkish expressions
   - Keep technical terms in English (Bitcoin, Lightning Network, CVE numbers, API, etc.)
   - Preserve company names, product names, and proper nouns as-is

   Don't:
   - Produce stiff, formal, or "translated-sounding" text
   - Lose the conversational energy in pursuit of literal accuracy
   - Change the structure or length significantly
   - Add or remove information
   - Translate technical jargon universally used in English

   Format:
   - Keep all markdown formatting (headers, bold, lists)
   - Maintain the same section structure
   - The first line must be the translated title as an H1 heading (# ...)

   Quality check: Read your translation mentally. Does it sound like a native Turkish speaker wrote it for a friend? If it sounds like a textbook, rewrite it.

   Output ONLY the translated markdown. No preamble or commentary.
   ```

3. Save the Turkish translation as `briefing-YYYY-MM-DD-tr.md` in `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/`. The S3 hook will detect the `-tr` suffix and upload it to `content/tr/`.

## Stage 5: Save, Update Tracker, and Deliver

1. Take the composer's output (the complete markdown briefing)
2. Save it as `briefing-YYYY-MM-DD.md` (using today's date) in `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/`

3. **Update the story tracker:** Read the current `tracker.json` from `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/tracker.json`, then update it:
   - For each story in today's briefing that already exists in the tracker: increment `times_covered`, update `last_covered` to today, update `last_known_state` with the latest information, update `status` if appropriate (e.g., `"developing"` → `"resolved"` if the story reached a conclusion)
   - For each NEW story in today's briefing: add a new entry with `first_covered` and `last_covered` set to today, `times_covered: 1`, appropriate `status`, and `key_facts` extracted from the briefing
   - For stories already in the tracker that were NOT covered today: leave them unchanged, but if they are older than 7 days and status is `"covered"` (not `"developing"`), set status to `"archived"`
   - Write the updated `tracker.json` back to `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/tracker.json`

4. Present the file to the user with a brief summary of what's in today's briefing (2-3 sentences highlighting the lead story and the deep dive topic). If there are developing stories with updates, mention that.

## Error Handling

- If a scout fails or returns empty results, proceed with the remaining scouts. Note the gap in the cross-pollinator's input.
- If the cross-pollinator or composer fails, report the error and offer to retry.
- If WebSearch is unavailable, inform the user that the briefing requires web access to search for current news.
- If `tracker.json` is malformed, log a warning and proceed without continuity context. Create a fresh tracker in Stage 4.

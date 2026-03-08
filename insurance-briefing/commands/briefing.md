---
description: Generate today's insurance briefing using the multi-agent pipeline
allowed-tools: Task, Read, Write, WebSearch, WebFetch, Glob, Grep
model: opus
---

Generate today's insurance briefing by orchestrating the multi-agent pipeline. Follow these stages exactly:

**Storage note:** All generated files (briefings, tracker, scout reports, editorial plans, personalization) are saved to `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/`. Agent definitions and reference materials are read from `${CLAUDE_PLUGIN_ROOT}/agents/` and `${CLAUDE_PLUGIN_ROOT}/references/`. User profiles are read from `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/profiles/` (with fallback to `${CLAUDE_PLUGIN_ROOT}/profiles/`).

## Stage 0: Load Memory (pre-processing)

Before launching scouts, build the continuity context that all agents will need:

1. **Read the story tracker:** Read `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/tracker.json`. This contains every story previously covered, with dates, key facts, and current status. If the file doesn't exist or is empty, skip — this is the first briefing.

2. **Read the previous briefing:** Use Glob to find the most recent `briefing-*.md` file in `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/`. Read it. If none exists, skip.

3. **Build the continuity prompt:** From the tracker, extract:
   - Stories with status `"developing"` — these are ongoing and should be checked for updates
   - Stories covered in the last 3 days — these should not be repeated unless there's a material update
   - The previous briefing's Radar topic — avoid repeating the same angle

   Format this as a concise **continuity brief** (aim for under 800 words) that will be passed to scouts and the cross-pollinator. Structure:

   ```
   ## Continuity Brief

   ### Developing Stories (check for updates)
   - [story id]: [headline]. Last covered [date]. Last known state: [state]. Key facts already reported: [facts].
   ...

   ### Recently Covered (do NOT repeat unless material update)
   - [story id]: [headline]. Covered [date(s)].
   ...

   ### Previous Radar Topic
   - Topic: [topic]. Covered [date]. Do not reuse this angle.
   ```

## Stage 1: Launch Domain Scouts (parallel)

Launch ALL 4 scout agents simultaneously using the Task tool. Each scout must search for today's news in their domain. Send all 4 Task calls in a single message so they run in parallel:

1. **regulatory-intelligence-scout** — Find today's regulatory developments affecting Turkish insurance
2. **market-data-scout** — Find today's market and financial data (pricing, underwriting trends, premium trends)
3. **industry-news-scout** — Find today's industry news and global reinsurance updates
4. **cross-domain-implications-scout** — Find non-insurance developments with insurance implications

For each Task call, use `subagent_type: "general-purpose"` and include the full system prompt from the corresponding agent definition file in `${CLAUDE_PLUGIN_ROOT}/agents/`. Tell each scout today's date so their searches are current.

**IMPORTANT:** Append the continuity brief from Stage 0 to each scout's prompt. Instruct each scout to:
- Check developing stories in their domain for updates
- Flag any story that is a material update to a previously covered story (mark as `[UPDATE]`)
- Avoid resurfacing stories that were already covered unless something changed
- Still prioritize genuinely new stories over updates

Wait for ALL 4 scouts to complete before proceeding.

## Stage 2: Cross-Pollination (editorial curation)

Once all scouts have returned their reports, launch the **cross-pollinator** agent using the Task tool:

- Pass ALL 4 scout reports as input
- **Also pass the full continuity brief and the full tracker JSON**
- The cross-pollinator will read all reports, apply continuity rules, select the best stories, identify cross-domain connections, and produce a structured editorial plan
- Use `subagent_type: "general-purpose"` and include the system prompt from `${CLAUDE_PLUGIN_ROOT}/agents/cross-pollinator.md`
- Use `model: "opus"` for this agent — editorial judgment requires the strongest reasoning

Wait for the cross-pollinator to complete before proceeding. Save the editorial plan as `editorial-plan-YYYY-MM-DD.md` in `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/`.

## Stage 3: Compose the Briefing

Launch the **briefing-composer** agent using the Task tool:

- Pass the editorial plan AND all 4 scout reports as input
- The composer writes the final markdown briefing following the structure and voice guidelines
- Use `subagent_type: "general-purpose"` and include the system prompt from `${CLAUDE_PLUGIN_ROOT}/agents/briefing-composer.md`
- Use `model: "opus"` for this agent — writing quality matters

Wait for the composer to complete.

## Stage 4: Personalize (conditional)

Check if any user profiles exist: Glob for `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/profiles/user-*.yaml` first, then fallback to `${CLAUDE_PLUGIN_ROOT}/profiles/user-*.yaml`

**If profiles exist:**
- Launch the **personalizer** agent using the Task tool
- Pass the complete briefing + all profile file contents as input
- Use `subagent_type: "general-purpose"` and include the system prompt from `${CLAUDE_PLUGIN_ROOT}/agents/personalizer.md`
- Use `model: "sonnet"` — cost optimization
- Wait for completion. Save output as `personalization-YYYY-MM-DD.json` in `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/`

**If no profiles exist:** Skip this stage. Log that personalization was skipped.

## Stage 5: Save, Update Tracker, and Deliver

1. Take the composer's output (the complete markdown briefing)
2. Save it as `briefing-YYYY-MM-DD.md` (using today's date) in `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/`

3. **Update the story tracker:** Read the current `tracker.json` from `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/tracker.json`, then update it:
   - For each story in today's briefing that already exists in the tracker: increment `times_covered`, update `last_covered` to today, update `last_known_state` with the latest information, update `status` if appropriate (e.g., `"developing"` → `"resolved"` if the story reached a conclusion)
   - For each NEW story in today's briefing: add a new entry with `first_covered` and `last_covered` set to today, `times_covered: 1`, appropriate `status`, and `key_facts` extracted from the briefing
   - For stories already in the tracker that were NOT covered today: leave them unchanged, but if they are older than 7 days and status is `"covered"` (not `"developing"`), set status to `"archived"`
   - Write the updated `tracker.json` back to `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/tracker.json`

4. **Also save scout reports** for reference: save each scout's output as `scouts/{scout-name}-YYYY-MM-DD.md` in `${CLAUDE_PLUGIN_ROOT}/.mcpb-cache/briefings/`

5. Present the briefing to the user with a brief summary of what's in today's briefing (2-3 sentences highlighting the lead story, the Radar topic, and any developing story updates). If personalization was run, mention that.

## Error Handling

- If a scout fails or returns empty results, proceed with the remaining scouts. Note the gap in the cross-pollinator's input.
- If the cross-pollinator or composer fails, report the error and offer to retry.
- If WebSearch is unavailable, inform the user that the briefing requires web access to search for current news.
- If `tracker.json` is malformed, log a warning and proceed without continuity context. Create a fresh tracker in Stage 5.
- If personalizer fails, proceed without personalization. The base briefing is still complete.

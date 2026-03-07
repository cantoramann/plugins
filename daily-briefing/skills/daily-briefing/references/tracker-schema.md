# Story Tracker Schema

The story tracker (`briefings/tracker.json`) provides cross-session memory for the briefing pipeline. It is read before each briefing run and updated after.

## Schema

```json
{
  "meta": {
    "last_updated": "YYYY-MM-DD",
    "briefings_generated": <number>
  },
  "stories": [
    {
      "id": "<kebab-case-identifier>",
      "headline": "<story headline as it appeared in the briefing>",
      "domain": "<primary domain: tech|business|policy|science|culture, or hyphenated for cross-domain>",
      "first_covered": "YYYY-MM-DD",
      "last_covered": "YYYY-MM-DD",
      "times_covered": <number>,
      "status": "<new|developing|covered|resolved|archived>",
      "key_facts": ["<fact 1>", "<fact 2>", "..."],
      "last_known_state": "<1-2 sentence summary of where things stand>"
    }
  ]
}
```

## Story Statuses

| Status | Meaning | Behavior |
|--------|---------|----------|
| `new` | Just added this run | Will be checked for updates next run |
| `developing` | Ongoing story with expected future developments | Scouts actively check for updates each run |
| `covered` | Story was covered; no further developments expected | Scouts skip unless they find something unexpected |
| `resolved` | Story reached a conclusion | Scouts skip. Kept in tracker for reference. |
| `archived` | Older than 7 days with status `covered` | Ignored by scouts. Pruned from continuity brief. |

## Lifecycle

1. **New story appears in briefing** → added with status `new` or `developing`
2. **Story is covered again with updates** → `times_covered` incremented, `last_covered` updated, `key_facts` appended, `last_known_state` updated
3. **Story has no updates for 2+ days** → status stays but scouts stop resurfacing it
4. **Story reaches conclusion** → status set to `resolved`
5. **Story is older than 7 days and status is `covered`** → status set to `archived`

## Continuity Brief Generation

Before each run, the `/briefing` command reads the tracker and generates a continuity brief:

- **Developing stories:** All stories with status `developing` — scouts check for updates
- **Recently covered:** All stories covered in the last 3 days — scouts avoid repeating
- **Previous deep dive:** The deep dive topic from the most recent briefing — not to be reused

The continuity brief is kept under 800 words to fit within scout context windows.

## Update Rules (post-briefing)

After each briefing, the command updates the tracker:

- **Existing stories in today's briefing:** increment `times_covered`, update `last_covered`, append new `key_facts`, update `last_known_state`
- **New stories in today's briefing:** add new entry
- **Untouched stories older than 7 days with status `covered`:** set to `archived`
- **Stories with status `developing` that weren't updated in 5+ days:** consider setting to `covered` (editorial judgment)

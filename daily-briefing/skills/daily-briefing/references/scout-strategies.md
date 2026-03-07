# Scout Strategies

Domain-specific search strategies and quality criteria for each scout agent.

## General Search Principles

All scouts should:

1. **Search for today's news first** — use date-qualified queries (e.g., "today", current date)
2. **Diversify sources** — don't rely on a single publication; cross-reference across outlets
3. **Prioritize primary reporting** — original reporting over aggregated summaries
4. **Look for the "second story"** — beyond the headline, what's the underlying trend or shift?
5. **Flag surprises** — anything unexpected or counterintuitive gets bonus points

## Tech & AI Scout

### Primary Search Queries
- "AI news today", "technology news today"
- "software launch", "open source release"
- "tech regulation", "AI policy"
- "cybersecurity breach", "data privacy"
- Trending topics on Hacker News, TechCrunch, Ars Technica, The Verge

### Quality Criteria
- **High value**: New capability that changes what's possible, regulation that reshapes an industry, security incident with broad implications
- **Medium value**: Product updates from major companies, funding rounds, executive changes
- **Low value**: Rumor-stage leaks, opinion pieces without new information, rehashed announcements

### What to Look For Beyond Headlines
- Open source projects gaining sudden traction
- Quiet infrastructure changes (API deprecations, standard updates)
- Developer tool shifts that signal where the industry is heading
- Research papers that just became practical

## Business & Markets Scout

### Primary Search Queries
- "stock market today", "earnings report"
- "M&A deal", "acquisition announced"
- "startup funding round", "IPO"
- "economic indicators", "jobs report", "inflation data"
- "supply chain", "trade"

### Quality Criteria
- **High value**: Market-moving events, major M&A, economic data releases, unexpected earnings
- **Medium value**: Notable funding rounds, industry consolidation trends, exec moves
- **Low value**: Minor price fluctuations, speculative analysis, clickbait forecasts

### What to Look For Beyond Headlines
- What sectors are quietly outperforming or underperforming
- Consumer spending pattern shifts
- Supply chain disruptions before they become headline news
- Small company moves that signal larger industry trends

## Policy & Geopolitics Scout

### Primary Search Queries
- "regulation passed", "policy announcement"
- "trade deal", "sanctions", "tariff"
- "election results", "government formation"
- "international summit", "diplomatic"
- "antitrust", "data privacy law"

### Quality Criteria
- **High value**: Passed legislation, signed executive orders, trade agreements, election outcomes
- **Medium value**: Proposed bills gaining momentum, diplomatic meetings with concrete agendas
- **Low value**: Political speculation, poll numbers without context, partisan rhetoric

### What to Look For Beyond Headlines
- Regulations in smaller countries that preview what larger ones will do
- Quiet bureaucratic decisions with outsized impact
- International coordination (or lack thereof) on emerging issues
- The gap between political rhetoric and actual policy implementation

## Science & Health Scout

### Primary Search Queries
- "research breakthrough", "study published"
- "clinical trial results", "FDA approval"
- "climate data", "environmental"
- "space exploration", "NASA", "ESA"
- "public health", "disease outbreak"

### Quality Criteria
- **High value**: Peer-reviewed breakthroughs, clinical trial results, public health emergencies, climate milestones
- **Medium value**: Promising early-stage research, conference presentations, notable grants
- **Low value**: Pre-print papers without peer review (unless from top labs), sensationalized health claims

### What to Look For Beyond Headlines
- Research that connects to everyday life in non-obvious ways
- Methodological breakthroughs (new tools that will accelerate many fields)
- Replication results (did the big finding hold up?)
- Funding shifts that signal where science is heading

## Culture & Consumer Trends Scout

### Primary Search Queries
- "trending today", "viral", "cultural moment"
- "consumer behavior", "spending trends"
- "entertainment industry", "streaming data"
- "social media trend", "generational"
- "anniversary", "milestone"
- "niche community", "subculture mainstream"

### Quality Criteria
- **High value**: Cultural phenomena that reveal behavioral shifts, consumer data that challenges assumptions, milestones that provide a lens on change
- **Medium value**: Viral moments with staying power, entertainment industry moves with business implications
- **Low value**: Celebrity gossip without cultural insight, listicles, rage-bait

### What to Look For Beyond Headlines
- Why is this trending *now*? What changed?
- What does this reveal about how people spend time, money, or attention?
- Cross-generational patterns (what boomers and Gen Z both care about, for different reasons)
- The business model behind cultural phenomena (how does this thing make money?)
- Things that broke out of their niche — what enabled the crossover?

## Output Format (All Scouts)

Each scout must return their findings in this structured format:

```
## [Domain Name] Scout Report

### Top Stories (ranked by importance)

**1. [Headline]**
- Source: [publication/url]
- Summary: [2-3 sentence summary]
- Why it matters: [1-2 sentences on significance]
- Cross-domain potential: [any connections to other domains, or "none"]

**2. [Headline]**
...

### Emerging/Trending
- [Brief mention of 2-3 things worth watching but not yet headline-worthy]

### Curiosity Candidates
- [1-2 items that might fit the Curiosity Corner — explain why they're interesting beyond the obvious]
```

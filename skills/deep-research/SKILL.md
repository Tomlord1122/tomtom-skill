---
name: deep-research
description: Deep research expert for comprehensive technical investigations. Use when conducting technology evaluations, comparing solutions, analyzing papers, or exploring technical trends.
---

# Deep Research Expert

Expert assistant for comprehensive technical research, multi-source information synthesis, technology evaluation, and trend analysis.

## Thinking Process

When activated, follow this structured thinking approach to conduct comprehensive technical research:

### Step 1: Problem Framing

**Goal:** Transform a vague research request into specific, answerable questions.

**Key Questions to Ask:**
- What is the core decision that needs to be made?
- Who is the audience for this research? (developer, CTO, team)
- What is the timeline? (immediate decision vs long-term evaluation)
- What are the constraints? (budget, team skills, existing infrastructure)

**Actions:**
1. Clarify the research scope with the user
2. Identify 3-5 key research questions
3. Define success criteria (what makes a good answer?)
4. Establish evaluation criteria for comparing options

**Decision Point:** You should be able to articulate:
- "The core question is: [X]?"
- "We will evaluate options based on: [criteria list]"

### Step 2: Hypothesis Formation

**Goal:** Form initial hypotheses to guide efficient research.

**Thinking Framework:**
- "Based on my knowledge, what are the likely candidates?"
- "What do I expect to find, and why?"
- "What would change my initial assumptions?"

**Actions:**
1. List 2-4 initial hypotheses or candidate solutions
2. Identify knowledge gaps that need to be filled
3. Prioritize research areas by impact on decision

**Decision Point:** Document:
- "Initial hypothesis: [X] because [Y]"
- "Key uncertainty: [Z]"

### Step 3: Source Strategy

**Goal:** Identify the most authoritative and relevant sources.

**Source Hierarchy (in order of reliability):**
1. **Official Documentation** (WebFetch) - Most authoritative
2. **GitHub Repository Analysis** - Code examples, activity metrics
3. **Context7 Documentation** - Structured, searchable docs
4. **Technical Blogs** (WebSearch) - Real-world experiences
5. **Discussion Forums** - Edge cases, gotchas

**Thinking Framework:**
- "What type of information do I need?"
  - Factual/API details → Official docs
  - Real-world experience → Blogs, case studies
  - Community health → GitHub activity
  - Comparison data → Benchmarks, surveys

**Actions:**
1. List sources to query for each research question
2. Note date sensitivity (when does info become stale?)
3. Plan for cross-validation of key claims

### Step 4: Information Gathering

**Goal:** Systematically collect relevant information.

**Thinking Framework - For each source:**
- "What am I looking for specifically?"
- "How do I know if this is trustworthy?"
- "Does this confirm or contradict other sources?"

**Gathering Checklist:**
- [ ] Official documentation for each candidate
- [ ] Getting started / quickstart guides
- [ ] Migration guides (reveal complexity)
- [ ] GitHub metrics (stars, issues, PR activity)
- [ ] Recent blog posts (last 12 months)
- [ ] Benchmark data (if performance-relevant)

**Quality Indicators:**
- Check article dates (recency matters)
- Verify author credibility
- Look for hands-on experience vs theoretical discussion
- Note sample sizes and methodology for benchmarks

### Step 5: Analysis Framework

**Goal:** Apply structured analysis to collected information.

**Thinking Framework - For Technology Evaluation:**

| Dimension | Questions to Answer |
|-----------|---------------------|
| **Maturity** | How long in production? Stable API? Breaking changes? |
| **Community** | Active maintainers? Issue response time? Contributor diversity? |
| **Performance** | Benchmark data? Real-world case studies? |
| **Learning Curve** | Documentation quality? Tutorials? Time to productivity? |
| **Ecosystem** | Integrations? Plugins? Tooling support? |
| **Risk** | Bus factor? Funding/backing? License concerns? |

**Maturity Assessment Scale:**
| Level | Criteria |
|-------|----------|
| Emerging | < 1 year, experimental, API unstable |
| Growing | 1-3 years, production-ready, active development |
| Mature | 3+ years, stable API, widespread adoption |
| Declining | Decreasing activity, maintenance mode |

### Step 6: Synthesis

**Goal:** Transform raw findings into actionable insights.

**Thinking Framework:**
- "What patterns emerge across sources?"
- "Where do sources agree/disagree?"
- "What are the trade-offs between options?"

**Synthesis Process:**
1. Create comparison matrix against evaluation criteria
2. Identify clear winners for specific criteria
3. Note where context matters (team, scale, use case)
4. Formulate primary recommendation with reasoning

**Handling Conflicts:**
- When sources disagree, note the discrepancy
- Check for date differences (newer may be more accurate)
- Look for official clarification
- Present both perspectives if unresolved

### Step 7: Risk Assessment

**Goal:** Identify and document risks for each option.

**Thinking Framework:**
- "What could go wrong with this choice?"
- "How likely is this risk? How severe?"
- "How can we mitigate this risk?"

**Risk Categories:**
- Technical: Performance, scalability, integration issues
- Organizational: Learning curve, hiring difficulty
- Strategic: Vendor lock-in, technology obsolescence
- Operational: Deployment complexity, monitoring gaps

### Step 8: Recommendation and Roadmap

**Goal:** Provide clear, actionable recommendations.

**Recommendation Structure:**
1. **Primary recommendation** with confidence level
2. **Conditions that would change this recommendation**
3. **Alternative for different contexts**
4. **Implementation roadmap** (next steps)

**Decision Point:** Your recommendation should state:
- "For [this context], I recommend [X] because [Y]"
- "If [condition changes], consider [Z] instead"
- "Next steps: [1, 2, 3]"

## Research Methodology

### Phase 1: Problem Definition
- Clarify research scope
- Identify key questions
- Establish evaluation criteria

### Phase 2: Information Gathering
- Official documentation (WebFetch)
- Technical blogs and discussions (WebSearch)
- GitHub project analysis
- Context7 documentation queries
- Academic papers if relevant

### Phase 3: Analysis Framework

**Technology Maturity Assessment:**
| Level | Description |
|-------|-------------|
| Emerging | < 1 year, experimental |
| Growing | 1-3 years, production-ready |
| Mature | 3+ years, widespread adoption |
| Declining | Decreasing activity |

**Community Health Metrics:**
- GitHub stars and growth rate
- Issue response time
- Release frequency
- Contributor diversity

**Performance Considerations:**
- Benchmark data availability
- Real-world case studies
- Scaling characteristics

### Phase 4: Synthesis
- Compare options against criteria
- Identify trade-offs
- Form recommendations

## Research Output Format

```markdown
# [Research Topic] Deep Research Report

## Executive Summary
[2-3 sentences summarizing key findings and recommendations]

## Background & Problem Statement
[Why this research is needed]

## Research Questions
1. [Question 1]
2. [Question 2]

## Findings

### Option A: [Name]
**Overview:** [Brief description]

**Strengths:**
- Point 1
- Point 2

**Weaknesses:**
- Point 1
- Point 2

**Best For:** [Use cases]

### Option B: [Name]
[Same structure]

## Comparative Analysis

| Criterion | Option A | Option B | Option C |
|-----------|----------|----------|----------|
| Maturity  | Mature   | Growing  | Emerging |
| Learning Curve | Medium | Low | High |
| Performance | High | Medium | High |
| Community | Active | Very Active | Small |

## Risk Assessment
- [Risk 1]: [Mitigation]
- [Risk 2]: [Mitigation]

## Recommendations
1. **Primary recommendation**: [Option] because [reasons]
2. **Alternative**: [Option] if [conditions]

## Implementation Roadmap
1. Step 1
2. Step 2
3. Step 3

## References
- [Source 1](url)
- [Source 2](url)
```

## Research Tips

### Effective Web Searches
- Use specific technical terms
- Include version numbers when relevant
- Search for "[technology] vs [alternative]"
- Look for "[technology] production experience"

### Evaluating Sources
- Prefer official documentation
- Check article/post dates
- Look for hands-on experience reports
- Verify claims with multiple sources

### Context7 Usage
- Resolve library ID first: `mcp__context7__resolve-library-id`
- Query with specific questions: `mcp__context7__query-docs`

## Present Results to User

When delivering research:
- Start with executive summary
- Provide clear recommendations
- Include comparative tables
- List sources for verification
- Acknowledge limitations

## Troubleshooting

**"Conflicting information found"**
- Note the discrepancy in report
- Check source dates (newer may be more accurate)
- Look for official clarification
- Present both perspectives if unresolved

**"Insufficient information"**
- Expand search terms
- Try different source types
- Acknowledge gaps in report
- Suggest ways to gather more data

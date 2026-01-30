# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Cursor, Copilot, etc.) when working with code in this repository.

## Repository Overview

A collection of skills for Claude.ai and Claude Code for working with Vercel deployments. Skills are packaged instructions and scripts that extend Claude's capabilities.

## Creating a New Skill

### Directory Structure

```
skills/
  {skill-name}/           # kebab-case directory name
    SKILL.md              # Required: skill definition
    scripts/              # Required: executable scripts
      {script-name}.sh    # Bash scripts (preferred)
  {skill-name}.zip        # Required: packaged for distribution
```

### Naming Conventions

- **Skill directory**: `kebab-case` (e.g., `vercel-deploy`, `log-monitor`)
- **SKILL.md**: Always uppercase, always this exact filename
- **Scripts**: `kebab-case.sh` (e.g., `deploy.sh`, `fetch-logs.sh`)
- **Zip file**: Must match directory name exactly: `{skill-name}.zip`

### SKILL.md Format

```markdown
---
name: {skill-name}
description: {One sentence describing when to use this skill. Include trigger phrases like "Deploy my app", "Check logs", etc.}
---

# {Skill Title}

{Brief description of what the skill does.}

## Thinking Process

{Structured thinking approach - see "Designing the Thinking Process" section below}

## Usage

```bash
bash /mnt/skills/user/{skill-name}/scripts/{script}.sh [args]
```

**Arguments:**
- `arg1` - Description (defaults to X)

**Examples:**
{Show 2-3 common usage patterns}

## Output

{Show example output users will see}

## Present Results to User

{Template for how Claude should format results when presenting to users}

## Troubleshooting

{Common issues and solutions, especially network/permissions errors}
```

## Designing the Thinking Process

The **Thinking Process** section is the core of an effective skill. It provides a structured mental framework that guides the agent through problem-solving, ensuring consistent, high-quality outcomes.

### Why Thinking Process Matters

A simple numbered list like "1. Do X, 2. Do Y, 3. Do Z" is insufficient because:
- It doesn't explain **why** each step matters
- It doesn't help the agent **decide** between alternatives
- It doesn't provide **context** for edge cases
- It treats the agent as a mechanical executor rather than a thinking partner

A well-designed Thinking Process transforms the agent into an expert by providing the mental models and decision frameworks that experts use.

### Structure of a Thinking Process Step

Each step should include these components:

```markdown
### Step N: {Step Name} ({Optional Context})

**Goal:** {What this step aims to achieve - one sentence}

**Key Questions to Ask:**
- {Question that guides thinking}
- {Question that uncovers requirements}
- {Question that identifies constraints}

**Thinking Framework:**
- "{Mental model or heuristic}"
- "{Decision criteria}"

**Actions:**
1. {Concrete action to take}
2. {Another concrete action}

**Decision Point:** {Criteria for moving to next step}
- "{Articulation template: 'I understand that [X] because [Y]'}"
```

### Key Design Principles

#### 1. Start with Context Gathering

The first step should always establish understanding before action:
- What is the current state?
- What are the constraints?
- What patterns already exist?

**Example:**
```markdown
### Step 1: Context Discovery

**Goal:** Understand the current state before proposing changes.

**Key Questions to Ask:**
- What is the existing architecture?
- What are the team's conventions?
- What are the pain points?

**Decision Point:** Only proceed when you can articulate:
- "The current system uses [X] with [Y] patterns"
```

#### 2. Use Decision Matrices for Pattern Selection

When multiple approaches exist, provide a decision matrix:

```markdown
**Thinking Framework - Match Requirements to Patterns:**

| Requirement | Recommended Pattern |
|-------------|---------------------|
| Simple CRUD | Standard layered architecture |
| Complex domain | Clean Architecture |
| Event-driven | CQRS with event sourcing |
```

#### 3. Include "Thinking Framework" Questions

Frame decisions as questions the agent should ask itself:

```markdown
**Thinking Framework:**
- "If an attacker controlled this input, what could happen?"
- "What happens at the boundaries?" (empty, null, max values)
- "How does this scale with data size?"
```

#### 4. Define Clear Decision Points

Each step should have criteria for completion:

```markdown
**Decision Point:** You should be able to explain:
- "This change implements [X] to solve [Y] problem"
- "It affects [Z] components and may impact [W]"
```

#### 5. Provide Checklists for Systematic Coverage

Use checklists for comprehensive review:

```markdown
**Security Checklist:**
- [ ] Input validation on all user inputs
- [ ] Parameterized queries (no SQL injection)
- [ ] Output encoding (no XSS)
- [ ] Authentication/authorization checks
```

#### 6. Include Anti-Patterns

Show what NOT to do:

```markdown
**Anti-Patterns to Avoid:**
```typescript
// BAD: Exposes raw internals
contextBridge.exposeInMainWorld('electron', { ipcRenderer });

// GOOD: Explicit, limited API
contextBridge.exposeInMainWorld('api', {
  openFile: () => ipcRenderer.invoke('dialog:openFile')
});
```
```

### Recommended Number of Steps

- **6-8 steps** is ideal for most skills
- Each step should represent a distinct **phase of thinking**
- Steps should flow logically from understanding → design → implementation → validation

### Template: Thinking Process for a New Skill

```markdown
## Thinking Process

When activated, follow this structured thinking approach:

### Step 1: Context Discovery
**Goal:** Understand the current state and constraints.
{Questions, Actions, Decision Point}

### Step 2: Requirements Analysis
**Goal:** Clarify what needs to be accomplished.
{Questions, Actions, Decision Point}

### Step 3: Solution Design
**Goal:** Choose the appropriate approach.
{Decision Matrix, Thinking Framework}

### Step 4: Implementation Strategy
**Goal:** Plan the concrete steps.
{Patterns, Checklists}

### Step 5: Quality Assurance
**Goal:** Ensure correctness and safety.
{Validation Checks, Anti-patterns}

### Step 6: Communication
**Goal:** Present results clearly to the user.
{Output Format, Templates}
```

### Best Practices for Context Efficiency

Skills are loaded on-demand — only the skill name and description are loaded at startup. The full `SKILL.md` loads into context only when the agent decides the skill is relevant. To minimize context usage:

- **Keep SKILL.md under 500 lines** — put detailed reference material in separate files
- **Write specific descriptions** — helps the agent know exactly when to activate the skill
- **Use progressive disclosure** — reference supporting files that get read only when needed
- **Prefer scripts over inline code** — script execution doesn't consume context (only output does)
- **File references work one level deep** — link directly from SKILL.md to supporting files

### Script Requirements

- Use `#!/bin/bash` shebang
- Use `set -e` for fail-fast behavior
- Write status messages to stderr: `echo "Message" >&2`
- Write machine-readable output (JSON) to stdout
- Include a cleanup trap for temp files
- Reference the script path as `/mnt/skills/user/{skill-name}/scripts/{script}.sh`

### Creating the Zip Package

After creating or updating a skill:

```bash
cd skills
zip -r {skill-name}.zip {skill-name}/
```

### End-User Installation

Document these two installation methods for users:

**Claude Code:**
```bash
cp -r skills/{skill-name} ~/.claude/skills/
```

**claude.ai:**
Add the skill to project knowledge or paste SKILL.md contents into the conversation.

If the skill requires network access, instruct users to add required domains at `claude.ai/settings/capabilities`.
---
name: code-review-master
description: Code review expert for security, quality, and performance analysis. Use when reviewing code, PRs, conducting security audits, or identifying performance issues.
---

# Code Review Expert

Expert assistant for comprehensive code review including security vulnerability detection, code quality assessment, performance analysis, and best practice recommendations.

## Thinking Process

When activated, follow this structured thinking approach to deliver thorough code reviews:

### Step 1: Context Gathering (Understanding the Landscape)

**Goal:** Build a complete mental model of the codebase before reviewing changes.

**Key Questions to Ask:**
- What is the project's architecture style? (Clean Architecture, MVC, Hexagonal, etc.)
- What design patterns are already established? (Factory, Repository, DI, etc.)
- What are the naming conventions? (camelCase, snake_case, file naming)
- What testing patterns exist? (unit test structure, mocking style)

**Actions:**
1. Scan 5-10 representative files in `src/` or `lib/` to understand coding style
2. Check for `README.md`, `CONTRIBUTING.md`, `.eslintrc`, `.prettierrc` for explicit rules
3. Map the directory structure to understand layer boundaries
4. Note any custom patterns unique to this codebase

**Decision Point:** Only proceed to Step 2 after you can articulate:
- "This repo uses [X] architecture with [Y] patterns"
- "The coding style follows [Z] conventions"

### Step 2: Scope Understanding (What and Why)

**Goal:** Understand the intent and impact of the changes being reviewed.

**Key Questions to Ask:**
- What problem does this PR/code solve?
- What are the explicit and implicit requirements?
- What is the blast radius of these changes? (Which parts of the system are affected?)

**Actions:**
1. Read the PR description, commit messages, or related issue
2. Identify all files changed and categorize them (new feature, bug fix, refactor)
3. Trace the dependency graph of changed code
4. Determine if changes cross layer boundaries

**Decision Point:** You should be able to explain:
- "This change implements [X] to solve [Y] problem"
- "It affects [Z] components and may impact [W]"

### Step 3: Security Review (CRITICAL - Must Pass)

**Goal:** Identify any security vulnerabilities that could expose the system to attacks.

**Thinking Framework:**
- "If an attacker controlled this input, what could happen?"
- "Is sensitive data being logged, exposed, or stored insecurely?"
- "Are authentication and authorization properly enforced?"

**Systematic Checks:**
1. **Input Validation:** All user inputs sanitized and validated?
2. **SQL/NoSQL Injection:** Parameterized queries used?
3. **XSS:** User content escaped before rendering?
4. **CSRF:** State-changing requests protected?
5. **Secrets:** No hardcoded credentials or tokens?
6. **Auth/Authz:** Proper access control at every endpoint?

**Decision Point:** Security issues are BLOCKING - document and require fix before approval.

### Step 4: Logic Correctness Review

**Goal:** Verify the code does what it claims to do correctly.

**Thinking Framework:**
- "What happens at the boundaries?" (empty input, max values, null)
- "What happens on failure?" (network error, timeout, exception)
- "Is there any implicit state that could cause issues?"

**Systematic Checks:**
1. Trace the happy path - does it work as intended?
2. Identify all edge cases - are they handled?
3. Check error handling - are errors caught and handled appropriately?
4. Verify async operations - are race conditions possible?

### Step 5: Consistency Review (Repo Standards)

**Goal:** Ensure new code integrates seamlessly with existing codebase.

**Thinking Framework:**
- "Would someone reading this code expect it to look like this based on the rest of the codebase?"
- "Does this follow the established patterns or introduce new conventions?"

**Systematic Checks:**
1. **Naming:** Does it follow existing conventions?
2. **Patterns:** Does it use established design patterns correctly?
3. **Architecture:** Does it respect layer boundaries?
4. **Error Handling:** Is it consistent with repo style?
5. **Testing:** Does it follow existing test patterns?

**Decision Point:** Inconsistencies should be flagged with:
- "Existing pattern: [X]"
- "This code does: [Y]"
- "Suggestion: [How to align]"

### Step 6: Quality & Maintainability Review

**Goal:** Ensure code is readable, maintainable, and follows best practices.

**Thinking Framework:**
- "Will someone unfamiliar with this code understand it in 6 months?"
- "Is this code easy to modify, extend, or delete?"

**Systematic Checks:**
1. Naming clarity and self-documentation
2. Function length and complexity (< 50 lines, cyclomatic complexity < 10)
3. DRY principle adherence
4. Single Responsibility Principle
5. Appropriate abstraction level

### Step 7: Performance Review

**Goal:** Identify potential performance bottlenecks.

**Thinking Framework:**
- "How does this scale with data size?"
- "Are there unnecessary operations or allocations?"

**Systematic Checks:**
1. N+1 query problems
2. Memory leak risks
3. Unnecessary computations in loops
4. Missing async/parallel opportunities
5. Inefficient data structures

### Step 8: Synthesize and Communicate

**Goal:** Provide clear, actionable, and constructive feedback.

**Output Structure:**
1. Summarize repository context (so reviewee understands your perspective)
2. List critical issues (MUST fix) with specific file:line references
3. List important issues (SHOULD fix) with explanations and suggestions
4. Note minor suggestions (NICE to have)
5. Acknowledge good practices (positive reinforcement)

## Usage

### Fetch PR Diff

```bash
bash /mnt/skills/user/code-review-master/scripts/pr-diff.sh <pr-number> [repo] [format]
```

**Arguments:**
- `pr-number` - Pull request number (required)
- `repo` - Repository in owner/repo format (default: from git remote)
- `format` - Output format: markdown, json, plain (default: markdown)

**Examples:**
```bash
bash /mnt/skills/user/code-review-master/scripts/pr-diff.sh 123
bash /mnt/skills/user/code-review-master/scripts/pr-diff.sh 123 owner/repo markdown
bash /mnt/skills/user/code-review-master/scripts/pr-diff.sh 456 owner/repo json
```

**Output:**
- PR metadata (title, author, base branch)
- Changed files list
- Diff content formatted for review

**Requirements:** gh CLI installed and authenticated

## Review Dimensions

### 1. Security (OWASP Top 10)

**Critical Checks:**
- SQL Injection - Parameterized queries used?
- XSS - User input sanitized for output?
- CSRF - Tokens validated for state-changing requests?
- Sensitive Data - Secrets in code? Logging sensitive info?
- Auth/Authz - Proper access control checks?

**Security Code Patterns:**
```typescript
// BAD: SQL Injection
db.query(`SELECT * FROM users WHERE id = ${userId}`);

// GOOD: Parameterized query
db.query('SELECT * FROM users WHERE id = $1', [userId]);

// BAD: XSS vulnerability
element.innerHTML = userInput;

// GOOD: Safe text content
element.textContent = userInput;
```

### 2. Code Quality

**Checks:**
- Naming clarity and consistency
- Function length and complexity
- DRY (Don't Repeat Yourself)
- Error handling completeness
- Single Responsibility Principle

**Metrics:**
- Cyclomatic complexity < 10
- Function length < 50 lines
- Nesting depth < 4 levels

### 3. Performance

**Checks:**
- N+1 query problems
- Memory leak risks
- Unnecessary computations
- Missing async/parallel opportunities
- Inefficient data structures

**Performance Patterns:**
```typescript
// BAD: N+1 queries
for (const user of users) {
  const orders = await getOrdersByUserId(user.id);
}

// GOOD: Batch query
const userIds = users.map(u => u.id);
const orders = await getOrdersByUserIds(userIds);
```

### 4. Maintainability

**Checks:**
- Test coverage for changes
- Documentation for public APIs
- Proper module structure
- Dependency management
- Backward compatibility

### 5. Repository Consistency (Repo-Specific Standards)

**Before reviewing, analyze the existing codebase to understand:**

#### Coding Style Analysis
- Naming conventions (camelCase, snake_case, PascalCase)
- File/folder naming patterns
- Import ordering and grouping
- Comment styles and documentation format
- Indentation and formatting preferences
- Error handling patterns used in the repo

**How to Analyze:**
```bash
# Scan existing code for naming patterns
# Look at 5-10 representative files in src/ or lib/
# Identify consistent patterns across the codebase
```

#### Design Pattern Detection
- **Creational**: Factory, Singleton, Builder patterns in use
- **Structural**: Adapter, Decorator, Facade patterns
- **Behavioral**: Observer, Strategy, Command patterns
- **Repository-specific patterns**: Custom patterns unique to this codebase

**Common Patterns to Check:**
```typescript
// If repo uses Factory pattern
// BAD: Direct instantiation breaking existing pattern
const service = new UserService(db, config);

// GOOD: Follow existing factory pattern
const service = ServiceFactory.create('user', { db, config });

// If repo uses Repository pattern
// BAD: Direct database access in controller
const users = await db.query('SELECT * FROM users');

// GOOD: Follow existing repository pattern
const users = await userRepository.findAll();
```

#### Layered Architecture Compliance

**Identify the repo's architecture style:**
- **Clean Architecture**: Entities → Use Cases → Controllers → Frameworks
- **Hexagonal (Ports & Adapters)**: Core → Ports → Adapters
- **MVC/MVVM**: Model → View → Controller/ViewModel
- **Domain-Driven Design**: Domain → Application → Infrastructure
- **Microservices patterns**: Service boundaries, API contracts

**Architecture Checks:**
```
// Analyze directory structure to understand layers
src/
├── domain/          # Business logic (should not import from infrastructure)
├── application/     # Use cases (orchestrates domain)
├── infrastructure/  # External concerns (DB, API, etc.)
└── presentation/    # UI/API controllers

# Check for layer violations:
# - Domain importing from infrastructure ❌
# - Presentation containing business logic ❌
# - Circular dependencies between layers ❌
```

**Layer Violation Examples:**
```typescript
// BAD: Domain layer importing infrastructure
// In domain/user.ts
import { PostgresClient } from '../infrastructure/database'; // ❌

// GOOD: Domain defines interface, infrastructure implements
// In domain/user.ts
export interface UserRepository {
  findById(id: string): Promise<User>;
}

// In infrastructure/postgres-user-repository.ts
import { UserRepository } from '../domain/user';
export class PostgresUserRepository implements UserRepository { ... }
```

#### Consistency Checklist

When reviewing, verify the PR follows:
- [ ] Same naming conventions as existing code
- [ ] Same design patterns already established
- [ ] Same layer boundaries and dependencies
- [ ] Same error handling approach
- [ ] Same testing patterns (unit test structure, mocking style)
- [ ] Same API design conventions (REST conventions, response format)

## Review Process

1. **Analyze Repository Standards** (First Step)
   - Scan 5-10 representative files to understand coding style
   - Identify design patterns in use (Factory, Repository, etc.)
   - Map the layered architecture (folder structure, dependencies)
   - Note any project-specific conventions (README, CONTRIBUTING.md)

2. **Understand Context**
   - What problem does this solve?
   - What are the requirements?

3. **Security Review** (Must Pass)
   - Check all inputs are validated
   - Verify authentication/authorization
   - Look for sensitive data exposure

4. **Logic Review**
   - Does the code do what it claims?
   - Are edge cases handled?

5. **Consistency Review** (Repo Standards)
   - Does naming follow existing conventions?
   - Are established design patterns respected?
   - Does it maintain layer boundaries?
   - Is error handling consistent with repo style?

6. **Quality Review**
   - Is it readable and maintainable?
   - Does it follow project conventions?

7. **Performance Review**
   - Are there obvious bottlenecks?
   - Is resource usage appropriate?

## Output Format

```markdown
## Repository Context
- **Coding Style**: [e.g., camelCase, ESLint config, Prettier]
- **Design Patterns**: [e.g., Repository, Factory, DI Container]
- **Architecture**: [e.g., Clean Architecture, MVC, Hexagonal]

## Review Summary
[One sentence overall assessment]

## Critical Issues (Must Fix)
- [ ] **[SECURITY]** Issue description (file:line)
  - Impact: [description]
  - Fix: [suggestion]

## Important Issues (Should Fix)
- [ ] **[QUALITY]** Issue description (file:line)
  - Reason: [explanation]
  - Suggestion: [how to fix]

- [ ] **[CONSISTENCY]** Issue description (file:line)
  - Existing Pattern: [how the repo does it]
  - Violation: [what the PR does differently]
  - Suggestion: [how to align with repo standards]

- [ ] **[ARCHITECTURE]** Issue description (file:line)
  - Layer Violation: [e.g., domain importing infrastructure]
  - Expected: [correct dependency direction]
  - Fix: [how to restructure]

## Minor Suggestions (Nice to Have)
- [ ] **[STYLE]** Issue description (file:line)

## Highlights
- Positive observation 1
- Positive observation 2
- Follows established [pattern name] pattern ✓
```

## Present Results to User

When providing code reviews:
- Prioritize security issues first
- Provide specific file:line references
- Include fix suggestions, not just problems
- Acknowledge good practices
- Be constructive and educational

## Troubleshooting

**"Too many issues to address"**
- Prioritize: Security > Bugs > Quality > Style
- Focus on the most impactful changes
- Suggest incremental improvement plan

**"Unclear if issue is valid"**
- Ask for clarification about intent
- Explain the potential problem
- Offer alternatives rather than mandates
